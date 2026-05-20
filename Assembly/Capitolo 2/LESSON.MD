Capitolo 2: Istruzioni di Shift e Moltiplicazione

Nota del tutor: questo capitolo si concentra sulle operazioni di scorrimento dei bit (shift/rotate) e sulle istruzioni di moltiplicazione a 64 bit presenti nelle fonti indicate. Ho migliorato la struttura, corretto imprecisioni e aggiunto alcuni concetti essenziali non trattati nel Capitolo 1 ma utili per comprendere pienamente questi argomenti.

## 2.1 Istruzioni di Shift e Rotazione
Le istruzioni di shift e rotazione manipolano i singoli bit di un registro. Sono estremamente utili per ottimizzare operazioni aritmetiche (moltiplicazioni/divisioni per potenze di 2), per l'elaborazione di maschere di bit e per il calcolo di indirizzi.

Principali istruzioni:

### LSL (Logical Shift Left) e LSR (Logical Shift Right)
Lo scorrimento *logico* sposta tutti i bit di un registro in una direzione specificata e riempie gli spazi vuoti che si creano con dei **zeri**.

Per capire perché si usano, pensa alla base 10 (decimale): se scrivi `5` e lo sposti a sinistra aggiungendo uno zero, ottieni `50` (hai moltiplicato per 10). In binario (base 2), spostare a sinistra di una posizione **moltiplica per 2**, spostare a destra **divide per 2**.

- **`LSL` (Logical Shift Left - Scorrimento a sinistra)**:
  Tutti i bit "scivolano" verso sinistra. I bit che escono oltre il limite (a sinistra) vengono persi (o finiscono nel Carry flag), mentre a destra entrano nuovi zeri.
  *Esempio visivo su 8 bit:*
  Valore iniziale: `0000 0101` (Decimale: 5)
  Scorrimento `LSL #1`: `0000 1010` (Decimale: 10, cioè 5 * 2)
  Scorrimento `LSL #2`: `0001 0100` (Decimale: 20, cioè 5 * 4)

  ```assembly
  ; Moltiplica il valore di R7 per 32 (che è 2 elevato alla 5a)
  LSL R0, R7, #5    ; Trasla a sinistra di 5 bit, R0 = R7 * 32
  ```

- **`LSR` (Logical Shift Right - Scorrimento a destra)**:
  Tutti i bit scivolano verso destra. I bit che escono a destra vengono persi, e a sinistra entrano nuovi zeri. Corrisponde a una divisione per potenze di 2 per numeri **senza segno**.
  *Esempio visivo su 8 bit:*
  Valore iniziale: `0000 1010` (Decimale: 10)
  Scorrimento `LSR #1`: `0000 0101` (Decimale: 5, cioè 10 / 2)

  L'LSR viene usato spesso anche per "spingere" un bit specifico nella primissima posizione (il bit 0), permettendo di leggerlo facilmente.
  ```assembly
  ; Isola il Bit Più Significativo (MSB, il 31esimo) portandolo in posizione 0
  LSR R3, R2, #31
  ```

### Altre varianti di Shift
- `ASR` (Arithmetic Shift Right): trasla a destra mantenendo il bit di segno (replicando il MSB) — utile per divisioni aritmetiche mantenendo il segno.
  ```assembly
  ASR R0, R1, #1    ; R0 = R1 >> 1 mantenendo il segno
  ```

- `ROR` (Rotate Right): ruota i bit verso destra; i bit che escono a destra rientrano a sinistra.
  ```assembly
  ROR R0, R1, #8    ; ruota R1 di 8 posizioni a destra
  ```

Nota su flag e carry: alcune operazioni di shift possono restituire il bit che viene "spinto fuori" come valore del Carry (C) nel registro di stato CPSR se l'istruzione è usata con l'opzione che aggiorna i flag. Questo è importante quando si concatenano shift e operazioni aritmetiche che dipendono dal carry.

## 2.2 Le Istruzioni Logiche a Bit (Bitwise) e le "Maschere"
Oltre agli shift, ARM fornisce istruzioni per eseguire operazioni logiche booleane *bit a bit* (bitwise). Queste confrontano due registri verticalmente (il bit 0 con il bit 0, il bit 31 con il bit 31, ecc.). 

L'utilizzo più tipico di queste istruzioni è creare **"maschere di bit"**. Pensa a una maschera fisica: copre alcune parti del viso (lasciandole inalterate o nascondendole) e lascia passare la luce solo da fori specifici. In Assembly, usiamo una stringa di `1` e `0` per "mascherare" un registro target: diremo al processore di operare *solo* dove noi mettiamo un `1` (o uno `0`, a seconda dell'istruzione), ignorando il resto!

Ecco come funzionano le 4 istruzioni principali con esempi visivi:

- **`AND` (AND Logico - "Isolare")**:
  La regola dell'AND è che restituisce `1` **solo se e soltanto se** entrambi i bit di input sono `1`.
  Se metti uno `0` nella maschera spegni il bit originale (è come coprirlo). Se metti un `1` mantieni intatto il bit originale.
  *Esempio: Vogliamo leggere solo i primi 4 bit di un numero, spazzando via il resto:*
  ```text
  Valore:   1011 0110
  Maschera: 0000 1111  (questo è #0x0F, voglio tenere solo gli ultimi 4 bit)
  ------------------- (AND)
  Risultato:0000 0110  (I primi 4 bit sono stati azzerati, gli ultimi 4 sono intatti)
  ```
  ```assembly
  AND R0, R1, #0xF     ; Isola i primi 4 bit azzerando tutto il resto
  ```

- **`ORR` (OR Logico - "Accendere")**:
  Restituisce `1` se **almeno uno** dei due bit è `1`.
  Conviene per **forzare a 1** dei bit specifici senza toccare il resto. Se nella maschera metti `0` il valore originale non cambia; se metti `1` il valore si trasforma in `1`.
  *Esempio: Voglio accendere gli ultimi 4 bit di un registro, a prescindere dal loro stato attuale:*
  ```text
  Valore:   1010 0000
  Maschera: 0000 1111  (voglio forzare a 1 gli ultimi 4 bit)
  ------------------- (ORR)
  Risultato:1010 1111  (Prima metà intatta, seconda metà forzata a 1)
  ```
  ```assembly
  ORR R1, R1, #0xF     ; Accende i primi 4 bit (LSB) lasciando intatto il resto
  ```

- **`EOR` (Exclusive OR / XOR - "Invertire / Toggle")**:
  Restituisce `1` solo se i due bit sono **diversi**. 
  L'uso geniale dello XOR è che, laddove nella maschera metti `1`, il bit originale si inverte (da 0 a 1 e da 1 a 0). Dove metti `0`, resta identico.
  *Esempio: voglio spegnere/accendere (toggle) gli ultimi 4 bit:*
  ```text
  Valore:   1010 1100
  Maschera: 0000 1111  (voglio "flipperare" gli ultimi 4 bit)
  ------------------- (EOR)
  Risultato:1010 0011  (Prima metà intatta, seconda metà invertita invertiti)
  ```
  ```assembly
  EOR R1, R1, #0xF     ; Inverte lo stato dei primi 4 bit
  ```

- **`BIC` (Bit Clear - "Spegnere")**:
  È un'istruzione comodissima nativa di ARM che equivale a `AND NOT`. Pulisce (imposta a `0`) i bit del valore originale in tutti i punti in cui la maschera presenta un `1`. È il modo più dichiarativo per forzare a zero dei bit, perché si definisce la maschera specificando esattamente "QUALI bit voglio spegnere".
  *Esempio: voglio azzerare esplicitamente i primi 4 bit.*
  ```text
  Valore:   1111 1111 
  Maschera: 0000 1111  (indica: "voglio spegnere questi 4 bit!")
  ------------------- (BIC, cioè AND NOT)
  Risultato:1111 0000  (Hai spento la seconda metà in un colpo solo)
  ```
  ```assembly
  BIC R1, R1, #0xF     ; Forza a 0 i primi 4 bit del registro R1
  ```


## 2.3 Quando e perché usare le istruzioni logiche e di shift
Ma all'atto pratico, **quando dobbiamo usare queste istruzioni?** Nella programmazione ad alto livello spesso ignoriamo i singoli bit, ma in Assembly sono essenziali in questi scenari tipici:

1. **Interazione con l'Hardware (Periferiche e Sensori):** I dispositivi hardware (es. pin GPIO per accendere un LED, sensori) comunicano spesso tramite "registri di controllo" in cui gni singolo bit ha un significato diverso. Es: il bit 0 accende il LED, il bit 1 legge lo stato di un bottone. Per accendere il LED *senza spegnere il bottone*, sei obbligato a usare un `ORR` con maschera. Per spegnere il LED senza toccare il resto, usi `BIC`.
2. **Ottimizzazione delle Prestazioni:** Come già visto, usare `LSL` o `LSR` per moltiplicare/dividere per potenze di 2 richiede una frazione del tempo e dei calcoli rispetto all'esecuzione di una vera istruzione `MUL` o di divisione.
3. **Compressione dei Dati (Packing/Unpacking):** Quando si vogliono risparmiare byte (es. trasmissione di pacchetti di rete, o manipolazione di pixel in grafica RGB), si "impacchettano" più valori dentro a un singolo registro a 32 bit. Per scompattarli e leggerli singolarmente, le istruzioni di Shift portano il dato nella posizione giusta e le istruzioni logiche (`AND`) tagliano via i bit in eccesso.

Esempio di "Unpacking" (estrarre i bit dal centro del registro): voglio leggere i secondi 8 bit partendo dalla posizione 4 di `R1` e salvarli in `R0`:
```assembly
LSR R0, R1, #4       ; Sposta i bit desiderati verso la posizione zero
AND R0, R0, #0xFF    ; Isola solo quei primi 8 bit azzerando tutto il resto
```

## 2.4 Moltiplicazioni lunghe e varianti (`MUL`, `MLA`, `SMULL`, `UMULL`)
Quando si moltiplicano due numeri a 32 bit, il risultato matematico completo può richiedere fino a 64 bit (es. $1.000.000 \times 1.000.000 = 1.000.000.000.000$, che non entra in 32 bit). ARM offre diverse varianti a seconda delle esigenze di calcolo:

- **Risultato a 32 bit (Troncato)**:
  - `MUL` (Multiply): Moltiplica due registri e salva i 32 bit meno significativi. Se il risultato sfora i 32 bit, i bit "in eccesso" vengono scartati e si perdono informazioni.
    ```assembly
    MUL R0, R1, R2   ; R0 = R1 * R2 (salva solo la parte "bassa")
    ```
  - `MLA` (Multiply Accumulate): Esegue la moltiplicazione e in un solo colpo vi somma un terzo registro (Accumulatore). È vitale negli algoritmi grafici (matrici) o nel calcolo di medie o totali (es. `Totale += Prezzo * Quantità`).
    ```assembly
    MLA R0, R1, R2, R3 ; R0 = (R1 * R2) + R3
    ```

- **Risultato a 64 bit (Completo)**:
  Per non perdere alcun dato, usiamo le istruzioni "Long" che spaccano il risultato in due registri da 32 bit formanti una coppia: Parte Bassa (`RdLo`) e Parte Alta (`RdHi`).
  - `SMULL` (Signed Multiply Long): Calcola assumendo che i numeri abbiano un **segno** (complemento a due).
    ```assembly
    ; Sintassi: SMULL RdLo, RdHi, Rm, Rs
    SMULL R8, R9, R5, R6   ; Il risultato esatto a 64b di (R5 * R6) va in {R9, R8}
    ```
  - `UMULL` (Unsigned Multiply Long): Stessa logica ma interpreta i numeri come **positivi/senza segno**.

## 2.5 Gestione del segno e prevenzione dell'Overflow
Perché in ARM ci sono `SMULL` e `UMULL` ma non ci sono versioni distinte per il normale `MUL` a 32 bit?
Il motivo è puramente matematico: la parte "bassa" a 32 bit del prodotto di due valori è identica sia che l'hardware li consideri con segno che senza segno. La differenza emerge solo nella parte "alta" (i restanti 32 bit), dove in caso di numeri negativi l'architettura deve fare l'estensione del bit di segno.
- Se usi `MUL` su numeri troppo grandi, l'alta parte viene tagliata e andrai inevitabilmente in **overflow**, compromettendo il calcolo.
- Se temi un overflow, bisogna sempre usare `SMULL/UMULL` e analizzare la parte superiore (il registro `RdHi`). Se `RdHi` è diverso da tutti zeri (per i positivi) o tutti uno (per i negativi), hai sforato i 32 bit base.

## 2.6 Esempi pratici integrati

Vediamo come si combinano shift, logica e moltiplicazioni nel mondo reale:

1) **Ottimizzazione aritmetica (Shift al posto di `MUL`)**:
Si deve calcolare `A * 32` sapendo che `A` è in `R1`. Poiché 32 è una potenza di 2 ($2^5$), usare lo scorrimento è la via più ottimizzata:
```assembly
LSL R5, R1, #5    ; R5 = R1 traslato a sinistra di 5 (R1 * 32)
```

2) **Controllo di un dispositivo hardware (Uso di `ORR` e `BIC`)**:
In `R1` ci sono i settaggi di un componente su bus I/O. Vogliamo attivare il modulo (bit 0 = 1) e imporre lo spegnimento degli interrupt (bit 1 = 0) senza distruggere la configurazione degli altri pin:
```assembly
ORR R1, R1, #1    ; "Accende" il bit 0 usando una maschera (00...001)
BIC R1, R1, #2    ; "Spegne" il bit 1 usando una maschera per la posizione 1 (0...010)
```

3) **Moltiplicazione sicura per grandi coordinate**:
Devi moltiplicare le posizioni mondiali di un videogioco che generano numeri immensi (`R5` e `R6`), salvando il risultato senza alcun overflow:
```assembly
SMULL R8, R9, R5, R6   ; {R8 = parte bassa, R9 = parte alta}
```

---

## 📝 Esercizi del Capitolo 2 (rivisti)

Esercizio 1: Moltiplicazione rapida con `LSL`
Scrivi l'istruzione Assembly ARM per prendere il valore di `R1` e moltiplicarlo per 32, salvando il risultato in `R5`.

Esercizio 2: Estrazione del bit di segno con `LSR`
Hai un numero a 32 bit in `R2`. Scrivi l'istruzione per isolare il suo MSB (posizione 31) e posizionarlo in `R6`.

Esercizio 3: Moltiplicazione a 64 bit con `SMULL`
Hai due variabili con segno in `R5` e `R6`. Scrivi l'istruzione per moltiplicarle ottenendo la parte bassa in `R8` e la parte alta in `R9`.

Se vuoi, posso anche aggiungere soluzioni commentate per gli esercizi o esempi di test per verificarli in un assembler/emulatore.
