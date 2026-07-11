import SwiftUI
import HealthKit

@main
struct HRTriggerApp: App {
    @StateObject private var monitor = HeartRateMonitor()

    var body: some Scene {
        WindowGroup {
            Text(monitor.status)
                .multilineTextAlignment(.center)
                .padding()
                .onAppear { monitor.start() }
        }
    }
}

final class HeartRateMonitor: ObservableObject {
    @Published var status: String = "Avvio..."

    private let healthStore = HKHealthStore()

    // Sostituisci con l'URL del tuo backend (es. dietro Tailscale)
    private let backendURL = URL(string: "https://tuo-backend.ts.net/hr-alert")!

    func start() {
        guard HKHealthStore.isHealthDataAvailable() else {
            status = "HealthKit non disponibile su questo dispositivo"
            return
        }

        let highHR = HKObjectType.categoryType(forIdentifier: .highHeartRateEvent)!
        let lowHR = HKObjectType.categoryType(forIdentifier: .lowHeartRateEvent)!
        let types: Set<HKObjectType> = [highHR, lowHR]

        status = "Richiesta autorizzazione HealthKit..."

        healthStore.requestAuthorization(toShare: nil, read: types) { [weak self] success, error in
            DispatchQueue.main.async {
                guard success else {
                    self?.status = "Autorizzazione HealthKit fallita: \(error?.localizedDescription ?? "sconosciuto")"
                    return
                }
                self?.status = "Autorizzato — in ascolto eventi HR"
                self?.observe(highHR, kind: "high")
                self?.observe(lowHR, kind: "low")
            }
        }
    }

    private func observe(_ type: HKSampleType, kind: String) {
        let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completion, error in
            defer { completion() }
            guard error == nil else { return }
            DispatchQueue.main.async {
                self?.status = "Ultimo evento: \(kind) alle \(Self.timeFormatter.string(from: Date()))"
            }
            self?.notifyBackend(kind: kind)
        }
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
            if !success {
                print("enableBackgroundDelivery fallita per \(kind): \(error?.localizedDescription ?? "")")
            }
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()

    private func notifyBackend(kind: String) {
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["event": kind])
        URLSession.shared.dataTask(with: request).resume()
    }
}
