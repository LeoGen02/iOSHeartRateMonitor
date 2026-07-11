import SwiftUI
import HealthKit

@main
struct HRTriggerApp: App {
    private let monitor = HeartRateMonitor()

    var body: some Scene {
        WindowGroup {
            Text("HR Trigger attivo")
                .onAppear { monitor.start() }
        }
    }
}

final class HeartRateMonitor {
    private let healthStore = HKHealthStore()

    // Sostituisci con l'URL del tuo backend (es. dietro Tailscale)
    private let backendURL = URL(string: "https://tuo-backend.ts.net/hr-alert")!

    func start() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let highHR = HKObjectType.categoryType(forIdentifier: .highHeartRateEvent)!
        let lowHR = HKObjectType.categoryType(forIdentifier: .lowHeartRateEvent)!
        let types: Set<HKObjectType> = [highHR, lowHR]

        healthStore.requestAuthorization(toShare: nil, read: types) { [weak self] success, error in
            guard success else {
                print("Autorizzazione HealthKit fallita: \(error?.localizedDescription ?? "sconosciuto")")
                return
            }
            self?.observe(highHR, kind: "high")
            self?.observe(lowHR, kind: "low")
        }
    }

    private func observe(_ type: HKSampleType, kind: String) {
        let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completion, error in
            defer { completion() }
            guard error == nil else { return }
            self?.notifyBackend(kind: kind)
        }
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
            if !success {
                print("enableBackgroundDelivery fallita per \(kind): \(error?.localizedDescription ?? "")")
            }
        }
    }

    private func notifyBackend(kind: String) {
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["event": kind])
        URLSession.shared.dataTask(with: request).resume()
    }
}
