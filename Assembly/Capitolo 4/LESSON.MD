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
3. **Register Offset con Shift:** Utilizza un altro registro come Indice (es. la tipica variabile `i` di un ciclo for classico `V[i]`) e calcola lo scostamento fisico moltiplicando questo indice per 4 usando lo shift.
   ```assembly
   @ Se R1 è l'indirizzo base e R2 è l'indice i (0, 1, 2...)
   LDR R0, [R1, R2, LSL #2]  @ Indirizzo effettivo letto = R1 + (R2 * 4). (Non altera R1 e R2 permanentemente!)
   ```

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
Man mano che le subroutine iniziano a formare catene chiamandosi a vicenda o iterando pesantemente i dati, la disponibilità sicura dei registri cala drasticamente. Cosa accade se la funzione genitore conservava un valore utile in `R4` e la subroutine appena chiamata sovrascrive quel registro durante un calcolo? Si verificherebbe un errore logico nel programma.
Qui entra in azione la struttura temporanea essenziale detta **Stack**, gestita dal registro **`SP` (Stack Pointer, R13)**.

Lo Stack in ARM è usualmente del tipo "Full Descending" (decrescente totale). La Pila non parte da zero, ma da indirizzi alti in RAM. Più dati vengono allocati nello stack, più questo cresce occupando gli indirizzi più bassi.

### Standard AAPCS (ARM Architecture Procedure Call Standard)
Nell'intera industria di manipolazione di basso livello ARM vigono precise convenzioni per rendere le Subroutine prevedibilmente rispettose per il chiamante:
- **`R0` - `R3` (Parametri, "Caller-Saved"):** Servono alla burocrazia logica di Passaggio-Ritrazione dei dati per i return value (output in R0). Una funzione chiamata può sovrascriverli deliberatamente. Sono usa e getta.
- **`R4` - `R11` (Contesto Protetto, "Callee-Saved"):** Sono strettamente registri di lavoro interno duraturi. Se la Subroutine ha brama di usarli `R4` ecc., cade su di essa l'OBBLIGO perentorio di nascondere i vecchi valori nello stack mediante Backup primitivo e successivamente recuperarli (Restore) a fine riga prima del ritorno.
- **`LR` (Link Register - R14):** Se dentro la tua Subroutine A farai una `BL` per chiamare una Subroutine B intertestuale... scordati di tornare indietro nello Main! La chiamata incapsulata perderà permanentemente la scia stracciando l'LR con l'ultima firma logica. Il rimedio? Occorre salvare tempestivamente il LR sullo lo stack insieme ai registri!

### Istruzioni PUSH e POP
L'architettura ARM permette di salvare (PUSH) o ripristinare (POP) liste multiple di registri sullo stack con una singola istruzione compatta.

```assembly
@ --- Esempio: Anatomia di una Subroutine che rispetta lo standard AAPCS ---
elabora_complesso:
    @ == PROLOGO ==
    @ Backup dei registri callee-saved e del registro di Link (LR) nello stack
    PUSH {R4, R5, R6, LR}  
    
    @ ...
    @ CODICE SUBROUTINE: R4, R5, R6 possono essere usati liberamente.
    @ ...

    @ == EPILOGO ==
    @ Ripristiniamo i valori di R4, R5, R6 per ridarli integri al chiamante.
    @ OTTIMIZZAZIONE ARM: invece di copiare l'indirizzo salvato in LR e poi eseguire "BX LR",
    @ noi trasferiamo l'indirizzo di rientro DIRETTAMENTE NEL Program Counter (PC).
    @ Questo permette di risalire lo stack e ritornare al chiamante in un colpo solo!
    POP {R4, R5, R6, PC}
```

**La Regola Fondamentale:** Se salvi N elementi con la `PUSH`, devi sempre ripristinarne esattamente N al momento della `POP`. Sbagliare il numero di registri nello stack corrompe il valore del PC al rientro (provocando `SegFault / Memory Corruption`).

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
Poiché la ricerca richiederà con buona probabilità l'utilizzo di specifici registri interni d'appoggio (`R4`, `R5`, ecc.), bisognerà assicurarsi di salvare e ripristinare in maniera appropriata il contesto attraverso le istruzioni protettive `PUSH` e `POP`. L'esecuzione dal codice chiamante (`_start`) dovrà avvenire con l'istruzione canonica `BL cerca_max`.
