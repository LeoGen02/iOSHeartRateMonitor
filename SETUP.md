# HR Trigger — kit di partenza (zero Mac, zero Xcode)

Cosa cambia rispetto alla versione precedente: niente più sessione Mac una tantum. Il `.xcodeproj` non esiste nel repo — non lo scrive né una persona né io a mano, lo genera **XcodeGen** dentro la GitHub Action stessa, da un file `project.yml` dichiarativo. Se `project.yml` ha un errore, XcodeGen lo segnala con un messaggio chiaro nei log della Action, non con un progetto Xcode silenziosamente corrotto — è il motivo per cui questo approccio è robusto anche senza mai aprire Xcode.

## Struttura del repo

```
project.yml                          <- spec XcodeGen (target, HealthKit, Info.plist)
HRTrigger/
  HRTriggerApp.swift                 <- entry point + HeartRateMonitor
.github/workflows/
  build-unsigned-ipa.yml             <- genera il progetto e compila un .ipa non firmato
```

## Il ciclo di lavoro pensato per Cowork / Claude Code

1. Apri questa cartella come progetto in Cowork (o nel tab Code della stessa app desktop — per un repo git con CI, è probabilmente lo strumento più naturale dei due).
2. Editiamo insieme `HRTriggerApp.swift` — la logica dell'automazione vera e propria (cosa succede quando scatta l'evento) prende forma lì.
3. Da lì fai commit e push su un repo GitHub (Cowork/Claude Code possono farlo per te, oppure da terminale).
4. Su GitHub → tab **Actions** → "Build unsigned IPA" → **Run workflow**.
5. A fine run, scarichi l'artifact `HRTrigger-unsigned` (uno zip con l'.ipa dentro).
6. Sideloadly su Windows: iTunes + iCloud scaricati da apple.com (non dal Microsoft Store), colleghi l'iPhone via USB, trascini l'.ipa, inserisci il tuo Apple ID gratuito, Start.
7. Sul telefono: **Impostazioni → Generali → VPN e gestione dispositivo → Trust**.
8. Ogni 7 giorni l'app scade (limite dell'ID Apple gratuito): riapri Sideloadly per rifirmare, oppure AltStore se preferisci il refresh automatico via Wi-Fi.

## Il test che risolve il dubbio rimasto aperto

Non ho ancora una risposta certa se HealthKit richieda l'abbonamento Developer Program a pagamento anche solo per un'installazione locale con ID gratuito, o se basti l'account gratuito — le fonti che ho trovato si contraddicono. Con zero Mac in mezzo, il modo per saperlo è: fai girare questa pipeline una prima volta così com'è (l'app minima allegata già chiede il permesso HealthKit sui due eventi), e guarda cosa succede al passaggio 6. Se Sideloadly si rifiuta di firmare l'entitlement HealthKit, o l'app crasha all'autorizzazione, hai la risposta — senza aver speso nulla oltre al tempo. Se funziona, hai già la pipeline end-to-end pronta e puoi espandere `notifyBackend` con la logica reale.

## Note

- `com.leonardo.hrtrigger` in `project.yml` è un bundle ID segnaposto — puoi lasciarlo così, va bene per uso personale, purché non collida con altre tue app firmate con lo stesso ID Apple.
- `NSHealthShareUsageDescription` in `project.yml` è la stringa che l'utente (tu) vede nel prompt di autorizzazione — modificala se vuoi un testo diverso.
