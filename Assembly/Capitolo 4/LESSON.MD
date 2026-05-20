# Capitolo 4: Strutture Dati Complesse e lo Stack

Per poter risolvere problematiche algoritmiche reali, la semplice gestione di una o due variabili non basta più. In questo capitolo ci dedichiamo all'esplorazione della memoria per gestire blocchi di dati sequenziali (Vettori e Stringhe) e imparare a preservare lo stato del processore utilizzando lo Stack Pointer, competenza fondamentale per scrivere subroutine modularizzate.

---

## 4.1 I Vettori (Arrays) in Memoria
Un vettore non è altro che una sequenza di dati memorizzati in indirizzi fisici adiacenti (contigui). In ARM a 32 bit, un numero intero standard (dichiarato con `.word`) occupa **4 Byte**.
Di conseguenza, se il primo elemento si trova all'indirizzo `1000`, il secondo sarà a `1004`, il terzo a `1008` e così via.

*Nota Operativa (Allineamento):* Quando si lavora con blocchi da 4 byte, è cruciale che l'indirizzo di memoria di partenza cada su un asse multiplo di 4. Questa regola è detta **allineamento della memoria** e si forza comunemente prima della dichiarazione dei dati aggiungendo la direttiva `.balign 4`.

### Dichiarazione in Memoria (Sezione `.data`)
Per inizializzare un vettore (array) all'interno del programma, si utilizza la classica direttiva `.data`. I numeri a 32 bit si definiscono concatenando i valori alla direttiva `.word`, separati da una virgola. Allo stesso tempo, se serve uno spazio di lavoro vuoto per memorizzare risultati, si usa la direttiva `.space`.
```assembly
.data
    .balign 4             @ Assicura rigorosamente l'allineamento di sicurezza a 4 byte
    vettore_pieno: 
        .word 10, -5, 30, 42, 7    @ Creo un vettore predefinito lungo 5 elementi interi
    
    vettore_vuoto: 
        .space 40                  @ Alloco "a vuoto" 40 byte di zeri. Equivale ad un array di 10 interi! (10 * 4 byte)
```

### 4.1.1 Indice vs Offset: La distinzione fondamentale
Spesso i termini vengono usati come sinonimi, ma in Assembly hanno scopi diversi:

*   **L'Indice ($i$):** È un concetto **logico**. Rappresenta la posizione dell'elemento nel vettore (0°, 1°, 2°...). È il numero che useresti in un ciclo `for (int i=0; i<N; i++)`. In ARM, l'indice solitamente risiede in un registro (es. `R2`) che viene incrementato di 1 ad ogni iterazione.
*   **L'Offset:** È un concetto **fisico**. Rappresenta il numero di **byte** di distanza dall'inizio del vettore. Poiché ogni `.word` occupa 4 byte, l'offset non avanza di uno in uno, ma di quattro in quattro.

**La formula magica:**
$$\text{Offset} = \text{Indice} \times \text{Dimensione Elemento (4 byte per .word)}$$

### Modalità di Indirizzamento (Addressing)
Per "scorrere" un vettore, ARM offre delle tecniche di calcolo rapido degli indirizzi incluse organicamente nei comandi Load/Store (`LDR` / `STR`). Le più usate nei cicli sono tre:

1. **Pre-Indexed con Update (`!`):** Cambia il puntatore PRIMA di leggere.
   ```assembly
   LDR R0, [R1, #4]!    @ L'indirizzo base R1 viene prima incrementato di 4, poi si legge in R0
   ```
2. **Post-Indexed:** Carica il valore puntato adesso, e DOPO aggiorna il puntatore. È in assoluto il metodo più comodo per iterare e scivolare linearmente un elemento alla volta.
   ```assembly
   LDR R0, [R1], #4     @ Legge in R0 il valore all'indirizzo corrente R1. DOPO averletto, assegna R1 = R1 + 4.
   ```
3. **Register Offset con Shift:** È il metodo più simile ai linguaggi di alto livello (`vettore[i]`). Utilizza un registro come **Indice logico** (es. `R2`) e lascia che l'hardware calcoli l'**Offset fisico** in tempo reale moltiplicando per 4 tramite lo shift.
   ```assembly
   @ Ipotizziamo: R1 = Indirizzo base, R2 = Indice logico (0, 1, 2...)
   LDR R0, [R1, R2, LSL #2]  
   
   @ Cosa succede dietro le quinte?
   @ 1. Prende l'indice in R2
   @ 2. Lo shifta a sinistra di 2 (LSL #2), che equivale a moltiplicare per 4.
   @    Ora ha ottenuto l'OFFSET.
   @ 3. Somma l'OFFSET all'indirizzo base R1.
   @ 4. Legge il valore risultante in R0.
   ```
   *Vantaggio:* Non devi modificare manualmente l'indirizzo base `R1`. Puoi accedere a qualsiasi elemento `i` saltando direttamente alla posizione corretta.

**Nota Operativa: L'Inganno della Parità (Indici vs Valori):** 
Nei test universitari viene spesso chiesto di operare sui vettori valutando la parità in due accezioni diverse che non vanno confuse:
*   **Indici Pari/Dispari (Posizione in memoria)**: Parliamo della posizione dell'elemento (es. `V[0]`, `V[2]`). Puoi gestirla incrementando il passo base di avanzamento a run-time (avanzando l'indirizzo di `+8` byte invece che di `+4`, saltando quindi un elemento in modo alternato) oppure verificando il registro che funge da **contatore dell'indice `i`** (es. `TST R2, #1`).
*   **Valori Pari/Dispari (Contenuto)**: Qui l'indice numerico di cella non interessa! Si tratta di capire se il valore estratto è divisibile per due (es. "14" è pari, "3" è dispari). Per scoprirlo, devi caricare il valore in un registro (es. nell'`R3` interno al ciclo) ed eseguire una `TST R3, #1`. Se il bit meno significativo è a 1, il numero estratto è Dispari (esci con `BNE dispari`). Altrimenti, se il bit è a 0, il numero è Pari (bypassa con `BEQ pari`).

**Esempio Dimostrativo: Somma degli elementi di un vettore (Post-Indexed)**
```assembly
    LDR R1, =vettore    @ R1 contiene l'indirizzo base dell'inizio dell'Array
    MOV R2, #5          @ Numero di elementi (N = 5) da prelevare
    MOV R0, #0          @ Inizializziamo l'accumulatore della somma (R0 = 0)
loop_array:
    LDR R3, [R1], #4    @ Preleva il valore in R3 e avanza il puntatore R1 di 4 byte
    ADD R0, R0, R3      @ Somma = Somma + Elemento
    SUBS R2, R2, #1     @ Countdown degli elementi esaminati e aggiornamento Flag di Zero (Z)
    BNE loop_array      @ Se R2 != 0, riparti in testa!
```

---

## 4.2 Stringhe (Array di Caratteri)
Una stringa non è altro che un array di byte trattati logicamente anziché matematicamente. Ci sono due differenze nette:
1. Ogni carattere occupa rigorosamente **1 Byte** (dichiarato con direttive `.ascii` o `.asciz`). 
2. A differenza dei vettori da 5, 10 o 50 spazi predeterminati, non sappiamo quanto sia lunga una frase in memoria. La stringa si considera conclusa unicamente all'incontro del **Terminatore Nullo**, ovvero il byte di valore logico zero (il classico `\0` dei linguaggi di base).

### LDRB (Load Register Byte) e STRB
Per leggere/scrivere i caratteri si **deve** usare l'istruzione al byte. Applicare una classica `LDR` caricherebbe 4 lettere contemporaneamente, creando errori sui dati e potenziali memory fault per difetti di allineamento su indirizzi dispari.
```assembly
LDRB R0, [R1], #1   @ Carica esattamente 1 byte in R0 espandendolo con zeri. Sposta l'indirizzo R1 avanti di +1.
```

### Valutazione ASCII dei caratteri
Il processore è ignaro dei caratteri tipografici. Elabora esclusivamente il loro valore numerico associato nello standard ASCII (es. 'A' equivale a 65, 'a' equivale a 97). 
Fortunatamente (e soprattutto nei test di IF stringati) l'assemblatore capisce automaticamente l'equazione apponendo gli apici singoli e il cancelletto:
```assembly
CMP R0, #'a'        @ Paragona segretamente R0 al valore ASCII numerico fisso di 'a'
```

**Distinguere le Categorie (Lettere vs Numeri):**
Durante l'analisi si tende comunemente a usare filtri di riconoscimento per capire se il carattere recuperato appartiene alle "lettere" o alle "cifre".
1.  **Riconoscimento Lettere Minuscole:** Si verifica che il valore ASCII sia compreso tra il limite inferiore `a` ed il limite superiore `z`.
  ```assembly
  CMP R0, #'a'
  BLT non_e_minuscola   @ E' minore di 'a'? 
  CMP R0, #'z'
  BGT non_e_minuscola   @ E' maggiore di 'z'? 
  @ << Se arriva a questa riga, il carattere è sicuramente una lettera MINUSCOLA >>
  ```
2.  **Riconoscimento Cifre Numeriche:** Si usano i caratteri compresi tra `0` e `9`. Attento: NON devi fare un confronto con i valori matematici numerici puri (non usare `#0` o `#9`). La stringa non contiene il valore `1`, ma il carattere ASCII `'1'` (che a livello numerico vale 49). Usa sempre il singolo apice!
  ```assembly
  CMP R0, #'0'
  BLT non_e_numero      @ E' minore del codice ascii di '0' ?
  CMP R0, #'9'
  BGT non_e_numero      @ E' maggiore del codice ascii di '9' ?
  @ << Se arriva a questa riga, la cella conteneva sicuramente una Cifra Numerica >>
  ```

**Esempio Dimostrativo: Contare la lunghezza di una stringa con While-Loop terminatore**
```assembly
    LDR R1, =stringa    @ R1 punta al primissimo carattere "A..."
    MOV R0, #0          @ R0 farà da contatore totale della lunghezza
loop_string:
    LDRB R2, [R1], #1   @ Estrae un singolo carattere e fa avanzare il puntatore R1 di 1 byte
    CMP R2, #0          @ Verifica se si tratta del terminatore nullo '\0'
    BEQ end_string      @ Se la flag di zero Z si attiva, la stringa è finita: esci dal ciclo!
    ADD R0, R0, #1      @ Incrementa il contatore perché il carattere è valido
    B loop_string       @ Torna all'inizio del loop per testare il byte successivo
end_string:
```

---

## 4.3 Lo Stack (La Pila di Memoria) e le Convenzioni
Man mano che le subroutine iniziano a formare catene chiamandosi a vicenda o processando dati complessi, i 16 registri a disposizione diventano insufficienti. Lo **Stack** (o Pila) è una porzione di memoria RAM dedicata alla conservazione temporanea dei dati e del contesto del processore.

### Il Funzionamento LIFO e lo Stack Pointer (SP)
La gestione della memoria avviene secondo la logica **LIFO (Last-In, First-Out)**: l'ultimo dato inserito è il primo ad essere estratto. Immagina una pila di piatti: puoi aggiungere o togliere piatti solo dalla cima.

Il registro **`SP` (Stack Pointer, R13)** ha il compito vitale di puntare sempre alla "cima" attuale della pila:
- Quando salviamo un dato (**PUSH manuale**), dobbiamo prima spostare lo `SP` verso il basso (sottraendo byte) e poi scrivere il dato usando `STR`.
- Quando recuperiamo un dato (**POP manuale**), dobbiamo leggere il valore con `LDR` e poi riportare lo `SP` verso l'alto (aggiungendo byte), liberando lo spazio.

### Stack "Full Descending"
In architettura ARM, lo stack è di tipo **Full Descending**:
1.  **Full**: lo `SP` punta sempre all'ultimo indirizzo effettivamente occupato (non al primo libero).
2.  **Descending**: lo stack cresce verso l'alto... ma negli indirizzi! In termini fisici, la pila parte da un indirizzo "alto" (es. `0x0000FFFF`) e cresce verso il basso (es. `0x0000FF00`).
    - Un "Push" comporta una **sottrazione** dallo `SP` (es. `SUB SP, SP, #4`).
    - Un "Pop" comporta una **addizione** allo `SP` (es. `ADD SP, SP, #4`).

### Standard AAPCS (ARM Architecture Procedure Call Standard)
Per permettere a funzioni scritte da programmatori diversi (o dal compilatore C) di comunicare senza errori, esistono regole ferree sull'uso dei registri:

- **Registri Scratch (`R0`-`R3`) - "Caller-Saved":** Sono i registri usati per passare parametri alle funzioni. La subroutine chiamata è libera di modificarli. Se il "chiamante" ha bisogno di conservare i valori in `R0-R3` dopo la chiamata, deve salvarli lui stesso nello stack prima di invocare la funzione.
- **Registri di Contesto (`R4`-`R11`) - "Callee-Saved":** Sono i registri di lavoro. Se una subroutine vuole usarli, **deve** prima salvarne il contenuto originale nello stack e ripristinarlo prima di terminare. Il "chiamante" ha la garanzia che, dopo la funzione, questi registri conterranno gli stessi valori di prima.
- **Link Register (`LR`, R14):** Contiene l'indirizzo di ritorno. Se la subroutine chiama a sua volta un'altra funzione (`BL`), l'indirizzo di ritorno originale in `LR` verrebbe sovrascritto. Per questo motivo, salvare `LR` nello stack è la prima cosa da fare in subroutine non terminali ("non-leaf functions").

### Gestione Manuale dello Stack (Senza PUSH/POP)
Sebbene ARM offra `PUSH` e `POP`, in ambito accademico (o per avere pieno controllo) si preferisce spesso interagire direttamente con lo `SP` tramite istruzioni di aritmetica e accesso alla memoria.

```assembly
@ --- Esempio: Anatomia di una Subroutine con gestione MANUALE dello Stack ---
subroutine_esempio:
    @ == PROLOGO ==
    @ 1. Creiamo spazio nello stack (3 registri * 4 byte = 12 byte)
    SUB SP, SP, #12         
    
    @ 2. Salviamo i registri manualmente negli slot creati
    STR LR, [SP, #8]        @ Salviamo LR nell'ultimo slot
    STR R4, [SP, #4]        @ Salviamo R4 nello slot centrale
    STR R5, [SP, #0]        @ Salviamo R5 nel primo slot (puntato da SP)
    
    @ ...
    @ CODICE DELLA SUBROUTINE: 
    @ Qui possiamo usare R4 e R5 liberamente per i calcoli.
    @ ...

    @ == EPILOGO ==
    @ 1. Ripristiniamo i valori originali leggendoli dallo stack
    LDR R5, [SP, #0]
    LDR R4, [SP, #4]
    LDR LR, [SP, #8]
    
    @ 2. Liberiamo lo spazio occupato riportando lo SP al valore originale
    ADD SP, SP, #12
    
    @ 3. Ritorno al chiamante
    BX LR
```

**Nota di Sicurezza:** Lo Stack deve essere sempre **bilanciato**. Se scendi di 12 byte nel prologo, devi risalire esattamente di 12 byte nell'epilogo. Se commetti un errore di calcolo dell'offset (es. salvando a `[SP, #2]` invece di `[SP, #4]`), corromperai i dati e il programma crasherà all'uscita della funzione.

---

## 📝 Esercizi del Capitolo 4

### Esercizio #1 – Somma elementi positivi (Array)
Scrivere un programma che, iterando un vettore `numeri` di 6 elementi interi (es. `.word 4, -2, 7, 0, -5, 10`), sommi tra loro **solamente** i numeri strettamente positivi (>0). Il totale dovrà essere memorizzato in `R0` alla fine dell'esecuzione.
*(Consiglio: sfrutta la CMP del dato estratto con l'immediato #0 prima di autorizzare la somma)*.

### Esercizio #2 – Modifica Stringa (Uppercase)
Si supponga di avere in memoria una stringa `.asciz "assembly"`. Scrivere un ciclo in Assembly ARM che scorra sequenzialmente la stringa, modificandola in memoria (tramite `STRB`) al fine di convertire ogni lettera nel formato Maiuscolo (da "assembly" a "ASSEMBLY"). *(Suggerimento: la tabella ASCII rivela che tra un carattere minuscolo e il suo corrispondente maiuscolo c'è una distanza fissa di `- 32`. Esempio: 'a' - 32 = 'A')*.

### Esercizio #3 – Modifica alternata Array (Indirizzamento a shift logico)
Dichiarare un vettore inizializzato a zero con 8 elementi nulli `.word 0,0,0,0,0,0,0,0`. Tramite un ciclo con un contatore iterativo (es. `R2` che conta da 0 a 7), assegnare all'elemento l'indice stesso (`R2`), scrivendo i dati **solo nelle posizioni di indice dispari**, mantenendo intatte le caselle ad indice pari (risultato finale = `[0, 1, 0, 3, 0, 5, 0, 7]`). Effettuare il calcolo di parità dell'indice con l'istruzione `TST R2, #1` e registrare le elaborazioni dinamiche ricorrendo alla store con offset calcolato tramite shift `STR R2, [R1, R2, LSL #2]`.

### Esercizio #4 – La Subroutine "Sicura" che calcola il Massimo
Implementare una subroutine `cerca_max` che prenda in input l'indirizzo base di un array grezzo in `R0` e il numero totale di elementi `N` in `R1`. 
Tale Subroutine dovrà trovare il valore massimo presente all'interno del vettore e restituirlo in output direttamente nel registro `R0` al termine della scansione.
Poiché la ricerca richiederà con buona probabilità l'utilizzo di specifici registri interni d'appoggio (`R4`, `R5`, ecc.), bisognerà assicurarsi di salvare e ripristinare in maniera appropriata il contesto attraverso la gestione manuale dello Stack (senza usare `PUSH` e `POP`). L'esecuzione dal codice chiamante (`_start`) dovrà avvenire con l'istruzione canonica `BL cerca_max`.
