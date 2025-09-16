# FantaBet

![Schermate principali dell'app](app.jpg)

## Panoramica
FantaBet è un'app Qt pensata per gestire un'asta di fantacalcio (o qualsiasi altra
competizione basata su rilanci) con un'esperienza moderna: il *Master* controlla il
banco da desktop, mentre gli *Scommettitori* partecipano da tablet o notebook sulla
stessa rete inviando le puntate in tempo reale via UDP.【F:main.qml†L16-L188】【F:udpslave.cpp†L111-L170】

## Funzionalità principali
- **Due modalità nello stesso eseguibile.** Dalla home si può scegliere se avviare il
  flusso *Master* o *Scommettitore*, basati su due StackView indipendenti con UI
  ottimizzata per il controllo touch/mouse.【F:main.qml†L16-L188】
- **Waiting room del Master.** Gli scommettitori registrati vengono scoperti in
  broadcast, aggiunti al modello condiviso e mostrati in una griglia adattiva con
  avatar tondi e colori dinamici; quando almeno una persona è connessa il Master può
  passare alla schermata d'asta.【F:MasterPages/MasterWaitingRoomPage.qml†L20-L157】【F:playermodel.cpp†L145-L229】
- **Console d'asta completa.** Il Master imposta il giocatore all'asta, avvia/pausa
  il countdown, modifica al volo i secondi residui e vede lo storico puntate con
  timestamp, importo e nome. Alla fine del round compaiono un popup di riepilogo e
  un'animazione celebrativa con i colori del vincitore.【F:MasterPages/MasterHomePage.qml†L14-L518】【F:WinPopup.qml†L6-L145】【F:CelebrationPopup.qml†L8-L207】
- **Registrazione rapida dello scommettitore.** Ogni partecipante inserisce nome e
  cognome, può caricare una foto dalla galleria oppure scattarla con la fotocamera,
  quindi invia automaticamente i dati al Master e accede alla schermata di gioco.【F:SlavePages/SlaveAddPersonPage.qml†L36-L276】【F:udpslave.cpp†L37-L105】
- **Puntate predefinite e personalizzabili.** La griglia delle offerte è costruita
  da un array che, se presente un file `bets.json` accanto all'eseguibile,
  viene sovrascritto con i valori definiti dall'organizzatore.【F:SlavePages/SlaveBettingPage.qml†L12-L104】
- **Modelli C++ condivisi.** PlayerModel, PeopleModel e BidsModel sono esposti come
  singletons QML per gestire elenco partecipanti, rubrica persistente e storico
  puntate (con eventuale modalità demo).【F:main.cpp†L78-L103】【F:playermodel.cpp†L16-L244】【F:peoplemodel.cpp†L51-L198】【F:bidsmodel.h†L14-L83】【F:bidsmodel.cpp†L5-L176】
- **Networking robusto via UDP.** Lo slave effettua il discovery in broadcast,
  invia i dati persona in chunk Base64 con ritrasmissioni NACK e riceve un ID univoco
  per firmare le puntate; il master risponde con ACK e processa le offerte in
  tempo reale.【F:udpslave.cpp†L111-L246】【F:udpmaster.cpp†L7-L169】

## Architettura
- **Interfaccia utente:** QML/Qt Quick Controls 2 con componenti custom per bottoni,
  card e popup, organizzati in `MasterPages/` e `SlavePages/` caricati via `qml.qrc`.
- **Strato C++:** i modelli e i servizi di rete sono registrati come singleton o
  tipi istanziabili (namespace `App` e `Network`) nel `main.cpp`, così la logica è
  riutilizzabile da tutta l'interfaccia.【F:main.cpp†L14-L103】
- **Dipendenze Qt:** progetto `.pro` basato su Qt Quick, Multimedia e Network per
  interfaccia, fotocamera e socket UDP.【F:FantaBet.pro†L1-L35】

## Flusso di utilizzo
### Per il Master
1. Avvia l'app, scegli *Master* e attendi la waiting room: ogni nuovo slave che si
   registra appare automaticamente con avatar e iniziali.【F:main.qml†L32-L117】【F:MasterPages/MasterWaitingRoomPage.qml†L20-L155】
2. Quando tutti sono collegati, premi **Avanti**, scegli il giocatore da mettere
   all'asta e premi **Start** per avviare il countdown.【F:MasterPages/MasterWaitingRoomPage.qml†L142-L155】【F:MasterPages/MasterHomePage.qml†L117-L455】
3. Gestisci la sessione con **Pausa/Start**, modifica i secondi con doppio clic
   sull'etichetta del timer e osserva lo storico puntate in tempo reale.【F:MasterPages/MasterHomePage.qml†L335-L518】
4. Alla chiusura il popup mostra vincitore, prezzo finale e ti permette di lanciare
   subito un nuovo round.【F:MasterPages/MasterHomePage.qml†L86-L123】【F:WinPopup.qml†L31-L145】

### Per gli Scommettitori
1. Scegli *Scommettitore*, inserisci nome e cognome e, se vuoi, aggiungi una foto
   dal file system o scatta una nuova immagine con la fotocamera integrata.【F:SlavePages/SlaveAddPersonPage.qml†L36-L276】
2. Tocca **Salva**: l'app trova automaticamente il Master sulla rete locale,
   invia i dati persona e passa alla griglia puntate.【F:SlavePages/SlaveAddPersonPage.qml†L167-L185】【F:udpslave.cpp†L37-L170】
3. Durante l'asta scegli l'importo desiderato (o i valori definiti in `bets.json`)
   per inviare immediatamente il rilancio.【F:SlavePages/SlaveBettingPage.qml†L63-L104】

## Compilazione e avvio
### Prerequisiti
- Qt 5.12 (o superiore) con i moduli **Qt Quick**, **Qt Quick Controls 2**,
  **Qt Multimedia** e **Qt Network** abilitati.【F:FantaBet.pro†L1-L17】【F:SlavePages/SlaveAddPersonPage.qml†L2-L8】
- Un compilatore C++ compatibile con Qt (MSVC, MinGW, Clang, GCC).

### Utilizzo con Qt Creator
1. Apri `FantaBet.pro` in Qt Creator.
2. Configura un kit Qt 5.12+ e genera i file con *qmake* o *CMake (Qt >= 6)*.
3. Compila e avvia il progetto; l'eseguibile generato includerà tutte le risorse QML
   grazie al file `qml.qrc`.

### Compilazione da riga di comando (qmake)
```bash
qmake FantaBet.pro
make            # oppure nmake / mingw32-make su Windows
./FantaBet      # esegui il binario prodotto nella stessa cartella
```
Assicurati che tutti i dispositivi (Master e Scommettitori) siano connessi alla
stessa rete locale per permettere il discovery via broadcast.【F:udpslave.cpp†L111-L170】

## Configurazione e dati
- **bets.json personalizzato:** posiziona un file `bets.json` accanto all'eseguibile
  con un array di numeri, ad esempio:
  ```json
  [5, 15, 25, 35, 50, 75]
  ```
  Verrà caricato all'avvio della pagina puntate al posto dei valori di default.【F:SlavePages/SlaveBettingPage.qml†L12-L61】
- **Rubrica persistente:** PeopleModel salva automaticamente i contatti in un file
  INI nell'area utente e li ripristina all'avvio, così non si perdono i nomi usati
  più spesso.【F:peoplemodel.cpp†L8-L198】
- **Modalità demo:** BidsModel espone proprietà per abilitare una simulazione di
  puntate automatiche utile durante le prove (timer disattivato di default).【F:bidsmodel.h†L18-L83】【F:bidsmodel.cpp†L10-L143】

## Note sul networking
1. Gli slave inviano periodicamente un messaggio `find` in broadcast fino a quando
   ricevono un ACK dal Master.【F:udpslave.cpp†L107-L136】【F:udpmaster.cpp†L21-L53】
2. I dati anagrafici sono spezzati in chunk `people_part` (circa 900 byte) con
   ritrasmissioni sui pacchetti mancanti; il Master li riunisce e conferma con un
   ACK contenente l'ID assegnato al giocatore.【F:udpslave.cpp†L187-L246】【F:udpmaster.cpp†L54-L126】
3. Ogni puntata viene firmata con l'ID ricevuto e confermata tramite ACK, così il
   totale in console è sempre allineato al traffico di rete.【F:udpslave.cpp†L88-L170】【F:udpmaster.cpp†L44-L108】

---
Buon divertimento con le tue aste fantacalcistiche!
