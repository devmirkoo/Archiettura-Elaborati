# Capitolo 4: Strutture Dati Complesse e lo Stack

Per poter risolvere problematiche algoritmiche reali, la semplice gestione di una o due variabili non basta più. In questo capitolo ci dedichiamo all'esplorazione della memoria per gestire blocchi di dati sequenziali (Vettori e Stringhe) e imparare a preservare lo stato del processore utilizzando lo Stack Pointer, competenza fondamentale per scrivere subroutine modularizzate.

---

## 4.1 I Vettori (Arrays) in Memoria
Un vettore non è altro che una sequenza di dati memorizzati in indirizzi fisici adiacenti (contigui). In ARM a 32 bit, un numero intero standard (dichiarato con `.word`) occupa **4 Byte**.
Di conseguenza, se il primo elemento si trova all'indirizzo `1000`, il secondo sarà a `1004`, il terzo a `1008` e così via.

*Nota Operativa (Allineamento):* Quando si lavora con blocchi da 4 byte, è cruciale che l'indirizzo di memoria di partenza cada su un asse multiplo di 4. Questa regola è detta **allineamento della memoria** e si forza comunemente prima della dichiarazione dei dati aggiungendo la direttiva `.balign 4`.

### Dichiarazione in Memoria (Sezione `.data`)
Per inizializzare un vettore (array) all'interno del programma, si utilizza la classica sezione direttiva `.data`. I numeri a 32 bit si definiscono concatenando i valori alla direttiva `.word`, separati da una virgola. Allo stesso tempo, se serve uno spazio di lavoro vuoto per immagazzinare risultati, si usa astutamente la direttiva `.space`.
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
Nei test universitari viene spessissimo chiesto di agire sui vettori valutando termini di parità in due accezioni diversissime che possono ingannarti:
*   **Elementi in POSIZIONE Piena/Dispari (Indici Pari/Dispari)**: Parliamo dell'indice spaziale (es. `V[0], V[2]`). Puoi ricavarli o raddoppiando lo step di avanzamento dell'indirizzo a run-time (facendo avanzare l'indice di `+8` byte invece che `+4`, saltando di netto 1 index visivo alternato) oppure scandagliando il registro che fungeda **contatore indice incrementale `i`** (es `TST R2, #1`).
*   **Valori estratti Pari/Dispari**: Qui la posizione in memoria non vi interessa minimamente! Parliano di capire se il numeretto tirato su sia effettivamente divisibile a metà (es. "14" è pari, mentre "3" è dispari). Per scoprirvelo, devi caricare il valore in un registro ad hoc, ad esempio la X pescata nel post-indexed cycle nell'`R3` interno, ed eseguire una `TST R3, #1`. Se il bit zero del medesimo si setta acceso vuol dire per logica matematica binaria che il numero esatto estratto è Dispari (con `BNE dispari`). Nel lato oscuro speculare, se valuta disattivato, equivale ad intero Pari (con `BEQ pari`).

**Esempio Dimostrativo: Somma degli elementi di un vettore (Post-Indexed)**
```assembly
    LDR R1, =vettore    @ R1 contiene l'indirizzo base dell'inizio dell'Array
    MOV R2, #5          @ Numero di elementi (N = 5) da prelevare
    MOV R0, #0          @ Inizializziamo l'accumulatore della somma (R0 = 0)
loop_array:
    LDR R3, [R1], #4    @ Pescaggio magico: preleva in R3 e avanza silenziosamente il puntatore R1 di 4
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
Per leggere/scrivere i caratteri si **deve** usare l'istruzione al byte. Applicare una superflua `LDR` classica caricherebbe 4 lettere contemporaneamente, creando casini sintattici e potenziali errori per difetti di allineamento byte dispari.
```assembly
LDRB R0, [R1], #1   @ Carica esattamente 1 byte in R0 espandendolo con zeri. Sposta l'indirizzo R1 avanti solo di +1.
```

### Valutazione ASCII dei caratteri
Il processore è ignaro dei caratteri tipografici. Elabora esclusivamente il loro valore numerico associato nello standard ASCII (es. 'A' equivale a 65, 'a' equivale a 97). 
Fortunatamente (e soprattutto nei test di IF stringati) l'assemblatore capisce automaticamente l'equazione apponendo gli apici singoli e il cancelletto:
```assembly
CMP R0, #'a'        @ Paragona segretamente R0 al valore ASCII numerico fisso di 'a'
```

**Distinguere le Categorie (Lettere vs Numeri):**
Durante l'analisi si tende comunemente a raggruppare filtri di riconoscimento. I due filtri master servono a riconoscere se il pattern al byte recuperato ricade nelle "lettere base" oppure nelle "cifre". 
1.  **Detezione Lettere Minuscole:** Seleziona un limite inferiore basato su `a` e margine superiore sigillato a `z`. 
  ```assembly
  CMP R0, #'a'
  BLT non_e_minuscola   @ E' minore di 'a'? 
  CMP R0, #'z'
  BGT non_e_minuscola   @ E' maggiore di 'z'? 
  @ << Se tocca questo rigo, matematicamente è certificato MINUSCOLO >>
  ```
2.  **Detezione Cifre Numeriche:** Avvaliti sempre delle limitazioni stringate comprese tra `0` e `9`. Attento: NON devi valutarlo matematicamente con 0 e 9 (es. #0 o #9 numerici puri). Lo stoico testo vettoriale non possiede il numero 1 (che a byte corrisponde all'introvabile start di controllo comandi SOH logico n°1), ha bensì salvato il valore associativo del carattere ASCII `'1'` (che è pari al nr. 49). Usa il single quote! 
  ```assembly
  CMP R0, #'0'
  BLT non_e_numero      @ E' minore del code ascii di '0' ?
  CMP R0, #'9'
  BGT non_e_numero      @ E' maggiore della valenza codetipica del '9' ?
  @ << Se giunge qui infausto... la cella conteneva indubbiamente logica Cifrica >>
  ```

**Esempio Dimostrativo: Contare la lunghezza di una stringa con While-Loop terminatore**
```assembly
    LDR R1, =stringa    @ R1 punta al primissimo carattere "A..."
    MOV R0, #0          @ R0 farà da contatore totale della lunghezza
loop_string:
    LDRB R2, [R1], #1   @ Estrai un singolo carattere e fai avanzare delicatamente R1 di 1 casella
    CMP R2, #0          @ Questo carattere è per caso il famigerato nullo = '\0'?
    BEQ end_string      @ Se la flag di uguaglianza Z si attiva, la stringa è finita: scappa!
    ADD R0, R0, #1      @ Incrementa il contatore perché la lettera scoperta è valida!
    B loop_string       @ Loop ritornando a catturare e testare il Byte successivo.
end_string:
```

---

## 4.3 Lo Stack (La Pila di Memoria) e le Convenzioni
Man mano che le subroutine iniziano a formare catene chiamandosi a vicenda o iterando pesantemente i dati, la disponibilità sicura dei registri cala drasticamente. Cosa accade se la funzione genitore conservava salvata un'identità utile in `R4` e la subroutine appena chiamata azzera distrattamente proprio quel registro per un calcolo superficiale? Crash della logica.
Qui entra in azione la provvidenziale struttura temporanea detta **Stack**, capeggiata implacabilmente dal registro **`SP` (Stack Pointer, R13)**.

Lo Stack in ARM è usualmente del tipo "Full Descending". La memoria della Pila non è creata dal nulla ma partendo da alte altitudini in RAM. Più informazioni infili sulla mensola e più la pila sfugge in giù riempiendo gli indirizzi bassi.

### Standard AAPCS (ARM Architecture Procedure Call Standard)
Nell'intera industria di manipolazione di basso livello ARM vigono precise convenzioni per rendere le Subroutine prevedibilmente rispettose per il chiamante:
- **`R0` - `R3` (Parametri, "Caller-Saved"):** Servono alla burocrazia logica di Passaggio-Ritrazione dei dati per i return value (output in R0). Una funzione chiamata può sovrascriverli deliberatamente. Sono usa e getta.
- **`R4` - `R11` (Contesto Protetto, "Callee-Saved"):** Sono strettamente registri di lavoro interno duraturi. Se la Subroutine ha brama di usarli `R4` ecc., cade su di essa l'OBBLIGO perentorio di nascondere i vecchi valori nello stack mediante Backup primitivo e successivamente recuperarli (Restore) a fine riga prima del ritorno.
- **`LR` (Link Register - R14):** Se dentro la tua Subroutine A farai una `BL` per chiamare una Subroutine B intertestuale... scordati di tornare indietro nello Main! La chiamata incapsulata perderà permanentemente la scia stracciando l'LR con l'ultima firma logica. Il rimedio? Occorre salvare tempestivamente il LR sullo lo stack insieme ai registri!

### Istruzioni PUSH e POP
La straordinarietà ARM permette di stipare o riportare folte liste multiple di registri sullo stack con una singola riga compatta ed eccezionalmente espressiva.

```assembly
@ --- Esempio: Anatomia di una Subroutine rispettosissima delle regole ---
elabora_complesso:
    @ == PROLOGO ==
    @ Backup immediato per blindare il contesto Main chiamante su registri e percorsi
    PUSH {R4, R5, R6, LR}  
    
    @ ...
    @ SPAZIO MACCHINAZIONI: R4, R5, R6 sono ora impiegabili. Il ripostiglio è blindato nello stream SP
    @ ...

    @ == EPILOGO ==
    @ Ricompensiamo la stesura riacquisendo (dalla sommità a decrescere) specularmente i tre valori.
    @ MAGIA ARM: invece di sfilare il rientro salvato nel vecchio LR per poi eseguire in coda "BX LR", 
    @ noi peschiamo l'indirizzo rientro trasferendolo DIRETTAMENTE NEL (PC) ProgramCounter
    @ generando simultaneamente pulizia dello stack e rientro cinetico con un'unica master riga!
    POP {R4, R5, R6, PC}
```

**La Regola Cosmica:** Se immetti 3 elementi con `PUSH`, devi estrarne indiscutibilmente 3 al `POP` nello stesso Scope logico di allineamento e chiusura. Sbagliare la numerica o omettere questa speculazione paralizza il puntatore dello Stack mandando il Processore irrimediabilmente dentro la spazzatura (`Seg Fault / Memory Corruption`).

---

## 📝 Esercizi del Capitolo 4

### Esercizio #1 – Somma elementi positivi (Array)
Scrivere un programma che, iterando un vettore `numeri` di 6 elementi interi (es. `.word 4, -2, 7, 0, -5, 10`), sommi tra loro **solamente** i numeri strettamente positivi (>0). Il totale dovrà essere memorizzato in `R0` alla fine dell'esecuzione.
*(Consiglio: sfrutta la CMP del dato estratto con l'immediato #0 prima di autorizzare la somma)*.

### Esercizio #2 – Modifica Stringa (Uppercase)
Si supponga di avere in memoria una stringa `.asciz "assembly"`. Scrivere un ciclo in Assembly ARM che iteri linearmente la stringa, manipolandone ed alterandola internamente (con `STRB`) al fine di forzare ogni lettera alla conversione logica in formato Maiuscolo (da "assembly" a "ASSEMBLY"). *(Suggerimento Matematico: un'attenta analisi della tabella ASCII rivelerà che tra un carattere minuscolo e il gemello maiuscolo c'è un fisso distaccamento di un salto numerico `- 32`. Esempio: 'a'-32 = 'A')*.

### Esercizio #3 – Modifica alternata Array (Indirizzamento a shift logico)
Dichiarare un vettore vuoto formattato come blocco vergine con 8 elementi nulli `.word 0,0,0,0,0,0,0,0`. Tramite un ciclo classicheggiante scalata logica all'insù sul contatore `R2` che conta partendo da 0 fino a raggiungere 7, scrivi attivamente il valore `R2` limitrofo nei soli baricentri di caselle dal formato d'**indice dispari** e bypassa del tutto le caselle di index Pari (esito in Array = `[0, 1, 0, 3, 0, 5, 0, 7]`). Avvalitene usando lo strumento di calcolo del `TST R2, #1` combinato alla manovra a salti logici di Store complessa in formato dinamico `STR R2, [R1, R2, LSL #2]`.

### Esercizio #4 – La Subroutine "Sicura" che calcola il Massimo
Creare una vera procedurale isolata `cerca_max` in grado di immatricolare in `R0` lo snodo base di un array grezzo ed immagazzinando nel vano `R1` le grandezze lineari fisiche del conteggio esteso del Vettore (cioè `N`). 
Tale Subroutine dovrà isolare l'enormità del valore rintracciato, scaricandone l'essenza in `R0` unicamente al disbrigo del compito conclusivo.
Considerato che il manipolo di ricerca pretenderà un consumo esagerato di un paio di registri d'appoggio collaterali tipo `R4` e/o `R5`, sarà tua formale prassi il disbrigo della Subroutine per mezzo canonico del binomio speculare protettivo `PUSH` / `POP`. L'evocazione principale dalla piattaforma root (main/`_start`) scatterà in modalità classica `BL cerca_max`.
