# Capitolo 3: Gestione del Flusso di Controllo in ARM Assembly

Gli argomenti coperti in questo capitolo si concentrano sulla gestione del flusso di controllo e sulla traduzione dei classici costrutti di programmazione di alto livello (C, Java, Python) in linguaggio Assembly ARM. Scrivere codice Assembly pulito richiede di comprendere come il processore valuta i dati e salta tra i blocchi istruzione.

---

## 3.1 I Flag di Condizione e il Registro CPSR
In una CPU, per prendere decisioni (come un `if`), bisogna prima poter "giudicare" un risultato. L'ALU (Arithmetic Logic Unit) esegue i calcoli e imposta delle **flag di condizione**, dei singoli bit che registrano l'esito dell'operazione. Queste flag risiedono all'interno di un registro speciale chiamato **CPSR** (*Current Program Status Register*).

Le quattro flag fondamentali nel CPSR sono:
- **N (Negative)**: Viene impostata a `1` se il risultato matematico dell'ultima operazione è stato negativo (tecnicamente, se il bit più significativo, il MSB, è `1`).
- **Z (Zero)**: Viene impostata a `1` se il risultato dell'operazione è *esattamente zero*. Questa è la flag più usata per verificare se due numeri sono uguali (perché $A - B = 0$ significa che $A == B$).
- **C (Carry / Riporto)**: Viene impostata a `1` se un'addizione ha generato un riporto (es. sommando numeri molto grandi senza segno), oppure indica l'assenza di un "prestito" in una sottrazione.
- **V (Overflow)**: Segnala un errore matematico in operazioni con segno (es. sommi due numeri positivi immensi e ottieni un falso risultato che sembra negativo).

### Aggiornamento delle Flag: Le istruzioni di Confronto
In ARM, per impostazione predefinita, le istruzioni normali (`ADD`, `SUB`) **non** aggiornano i flag del CPSR. Per forzare un'istruzione matematica o logica ad aggiornare le flag, bisogna aggiungere il suffisso `S` all'istruzione (es. `ADDS`, `SUBS`, `MOVS`).

Tuttavia, molto spesso desideriamo testare i dati e prendere decisioni **senza modificarli**. A questo scopo, ARM fornisce un set di istruzioni di test/confronto dedicate che aggiornano fedelmente le flag CPSR e poi scartano immediatamente il risultato del calcolo, senza intaccare i registri originali. Le principali sono:

- **`CMP` (Compare - Confronta)**: Effettua matematicamente una **sottrazione** ($Op1 - Op2$). È di gran lunga la più comune e si presta benissimo per i tipici branch relazionali `if (A > B)` o `if (A == B)`.
  ```assembly
  CMP R1, R2   @ Sottrae R2 da R1. Se R1 == R2, la flag Zero (Z) diventa 1.
  ```
- **`CMN` (Compare Negative - Confronta Negativo)**: Agisce come la CMP, ma elabora internamente un'**addizione** ($Op1 + Op2$). Torna molto utile se occorre avviare valutazioni invertite, confrontando un registro con l'inverso dell'altro, oppure per verificare se due numeri sommati si elidono e determinano uno zero.
  ```assembly
  CMN R1, R2   @ Somma R1 e R2. Calcola le flag come se si testasse R1 - (-R2).
  ```
- **`TST` (Test)**: Esegue un'operazione logica **AND** bit a bit ($Op1 \ \& \ Op2$). Viene impiegata massicciamente per operazioni di *bitmasking*, per appurare individualmente se specifici bit dentro un registro sono "accesi" a `1` o "spenti" a `0`.
  ```assembly
  TST R1, #1   @ Mette in AND i bit, isolando solo il bit in posizione 0 per scoprire se R1 è dispari.
  ```
- **`TEQ` (Test Equivalence - Testa Equivalenza)**: Applica un operatore logico **XOR** (OR Esclusivo, $Op1 \ \oplus \ Op2$). È utilissima per vagliare se due valori sono identici bit per bit; al contrario della CMP, che in quanto sottrazione può scatenare le flag Carry e Overflow, la TEQ tocca soltanto le flag Negative e Zero, fornendo un paragone d'identità "sicuro" tra intere sequenze bitwise.
  ```assembly
  TEQ R1, R2   @ Esegue XOR logico su R1 e R2. Se sono perfettamente identici, setta Z = 1.
  ```

---

## 3.2 Istruzioni di Salto (Branching)
Con i flag pronti nel CPSR, la CPU ha bisogno di poter deviare il proprio flusso logico di esecuzione. Normalmente, l'elaboratore esegue le istruzioni in rigida sequenza, incrementando automaticamente il Program Counter (`PC` oppure registro `R15`) per puntare all'istruzione successiva. Le istruzioni di salto forzano una modifica diretta del `PC`, permettendo di rompere la sequenza lineare e riprendere l'esecuzione da un'altra parte del programma.

L'architettura ARM offre tre istruzioni fondamentali per padroneggiare i salti:

1. **`B` (Branch)**: È l'istruzione di salto base. Viene utilizzata per saltare verso un'etichetta (`label`) specifica all'interno del codice. È concettualmente identico al `goto` nei linguaggi di alto livello e non tiene memoria del punto da cui si è appena saltati.
   ```assembly
   B loop_start    @ Salto incondizionato: la CPU smette di scorrere linearmente e salta a 'loop_start'.
   ```

2. **`BL` (Branch and Link)**: Questo salto costituisce il pilastro per l'implementazione di **funzioni** e **subroutine** modularizzate. Oltre a deviare il flusso del PC (esattamente come l'istruzione `B`), la `BL` porta a termine un compito essenziale: prima di saltare, salva l'indirizzo dell'istruzione successiva (ovvero l'indirizzo di "ritorno") nel **registro LR (Link Register - R14)**. In questo modo, la funzione chiamata saprà dove proseguire il lavoro una volta completata.
   ```assembly
   BL calcola_somma  @ Salta temporaneamente all'etichetta calcola_somma.
   ```

3. **`BX` (Branch and Exchange)**: Differisce radicalmente dalle altre due. Invece di usare un'etichetta `label`, questa istruzione effettua un salto dinamico usando un *registro*. Oltre al salto, istruisce la CPU a uno "scambio" (Exchange) di architettura (passando tra la modalità ARM a 32 bit e quella Thumb a 16 bit se richiesto). È universalmente usata alla fine di un frammento per ritornare alla funzione chiamante avvalendosi del Link Register:
   ```assembly
   BX LR           @ Termina la subroutine e riprendi l'esecuzione dall'indirizzo linkato in R14.
   ```

### Salti Condizionati (Conditional Branching)
La vera forza nei controlli logici emerge dal fatto che tutte le istruzioni di Branch supportano l'esecuzione **condizionale**, associando l'operazione allo stato dei flag (Z, N, C, V) presenti nel **CPSR**.
Aggiungendo un suffisso logico, il processore esegue il salto *solo se* la flag obbedisce alla condizione; in caso contrario l'istruzione di salto viene "ignorata" ed il processore prosegue in sequenza.

Ecco i suffissi più comuni che traducono i confronti standard:
- **Uguaglianza e Disuguaglianza**: 
  - `BEQ` (Branch if Equal): Salta se la flag Zero è accesa (`Z == 1`).
  - `BNE` (Branch if Not Equal): Salta se la flag Zero è spenta (`Z == 0`).
- **Istruzioni con Segno (Signed)** (usate per le abituali variabili intere `int`):
  - `BGT` (Branch if Greater Than): Maggiore stretto (es. +5 > -2).
  - `BGE` (Branch if Greater or Equal): Maggiore o uguale.
  - `BLT` (Branch if Less Than): Minore stretto.
  - `BLE` (Branch if Less or Equal): Minore o uguale.
- **Confronti Numerici Senza Segno (Unsigned)**:
  - `BHI` (Branch if Higher): L'equivalente del Maggiore per valori senza segno `unsigned`.
  - `BLS` (Branch if Lower or Same): L'equivalente del Minore o uguale.

---

## 3.3 Traduzione dei Costrutti di Programmazione

### 3.3.1 Il Costrutto If / If-Else
La logica più efficiente e comune in Assembly per tradurre un `if` è **"ragionare per contrari"**. In un linguaggio C, scriveremmo "Se condizione vera, fai blocco_if". In Assembly scriveremo: *"Valuta la condizione. Se **NON** si è avverata, salta via l'if"*.

**Esempio C:**
```c
if(x == y) {
    x = 10;
} else {
    y = 5;
}
```
**Traduzione in ARM:**
```assembly
    CMP R1, R2        @ Confronta x e y
    BNE else_block    @ Se NON sono uguali, salta il blocco If e vai su Else

    MOV R1, #10       @ Blocco IF.
    B end_if          @ Salta alla fine per non eseguire anche l'Else.

else_block:
    MOV R2, #5        @ Blocco ELSE.

end_if:
```

### 3.3.2 Predicazione (Esecuzione Condizionata)
Un enorme vantaggio di ARM, raramente presente su architetture x86, è che **quasi ogni singola istruzione supporta l'esecuzione condizionata**. 
Se un blocco if fa compiere un'operazione piccolissima (1-2 righe), si può evitare totalmente l'istruzione di salto branch (`B`), che in un processore rallenta la pipeline (flush).
```assembly
CMP R1, R2          @ Confronta R1 e R2
ADDEQ R3, R3, #1    @ Esegui l'ADD *SOLO* se il test era Equal (Z=1).
MOVNE R4, #0        @ Esegui la MOV *SOLO* se C'era Not Equal (Z=0).
```

**Pattern di Ecellenza: Ricerca Rapida del Minimo e del Massimo**
Grazie ai suffissi condizionali applicati su una banale `MOV` diventa estramemente elegante trovare minimi e massimi senza sprecare cicli di branch! 
Ad esempio, se vogliamo capire chi sia il Minimo e chi il Massimo tra due variabili residenti in `R0` e `R1`:
```assembly
    @ Vogliamo che R0 contenga il Minimo ed R1 il Massimo.
    CMP R0, R1          @ Paragoniamo R0 e R1 (Sottrazione R0 - R1)
    
    @ ATTENZIONE: le MOV avverranno SIMULTANEAMENTE al verificarsi logico.
    @ E' necessario salvaguardare uno dei vecchi valori scambiando con l'ausilio intermedio. 
    @ (Se R0 fosse > R1 dovremmo scambiarli fisicamente).
    MOVGT R12, R0       @ (SE R0 > R1) R12 fa da temp per R0 originario
    MOVGT R0, R1        @ (SE R0 > R1) Sovrascrivi il nuvo minimo in R0 prelevando R1
    MOVGT R1, R12       @ (SE R0 > R1) Inserisci il vecchio massimale prelevato nel temp in R1
    @ Se inve R0 fosse <= a R1, il processore salta queste righe come se non le vedesse!
```
Questa manovra è perfetta in Subroutine del tipo `minmax` per ridurre al minimo la confusione o la frammentazione del flusso.

### 3.3.3 Il Ciclo While (Test d'ingresso)
Un costrutto `while` si caratterizza per il **test d'ingresso**: il codice al suo interno viene eseguito se e solo se la condizione di partenza è vera. Se è falsa fin dall'inizio, il blocco di codice viene aggirato senza mai essere valutato.
In Assembly ARM l'approccio segue la regola del "ragionare per contrari": all'inizio dell'etichetta del ciclo si valuta la condizione; se questa indica che dobbiamo uscire, si salta oltre la fine del blocco. Al fondo del blocco esecutivo si pone invece un branch incondizionato che forza il PC a tornare in cima al test d'ingresso per la successiva valutazione.

**Esempio C:**
```c
int i = 0;
while (i < 5) {
    i++;
}
```
**Traduzione in ARM:**
```assembly
    MOV R1, #0        @ i = 0

while_start:
    CMP R1, #5        @ Test d'ingresso: confronta i con 5.
    BGE while_end     @ Logica invertita: se i >= 5 (Greater or Equal), salta via e termina il ciclo!

    ADD R1, R1, #1    @ Corpo del While: l'incremento (i++).
    
    B while_start     @ Torna sempre in alto a rifare il test d'ingresso.

while_end:
```

### 3.3.4 Il Ciclo For (E l'ottimizzazione decrescente "Count-Down")
Un ciclo `for` convenzionale è composto da tre passaggi fondamentali: inizializzazione del contatore, test limite e incremento (spesso ad alto livello scriviamo: `for(i=0; i<10; i++)`).
Tradurre fedelmente questo tipo di ciclo *in avanti* richiederebbe 3 istruzioni dedicate per poter fluire: l'aggiornamento logico (`ADD`), il ricalcolo del limite (`CMP`) e il salto direzionale (`BLT`).

**L'ottimizzazione verso lo zero (Count down):**
In ARM l'affidabilità di esecuzione e la performance balzano ad un livello superiore se decidiamo di eseguire i cicli "all'indietro", scalando dal limite fissato verso lo `0` (es. da 10 a 1). 
Il trucco risiede nell'usare il suffisso **`S`**, richiedendo esplicitamente un calcolo sottrattivo che tocchi la diagnostica di stato: eseguendo una **`SUBS`** sul contatore, il processore detrae la quantità aritmetica e **simultaneamente indaga sui flag**. Non appena il valore decrementato tocca il suolo dello `0`, il processore accende autonomamente la flag Zero (`Z=1`). 
Questa superba tecnica condensata **elimina stabilmente l'obbligo di inserire qualunque istruzione di confronto `CMP` ad ogni ciclo**.

**Esempio C:**
```c
int sum = 0;
for (int i = 5; i > 0; i--) {
    sum = sum + i;
}
```
**Traduzione in ARM:**
```assembly
    MOV R0, #0        @ sum = 0
    MOV R1, #5        @ contatore i = 5 (Inizializzazione)

loop_for:
    ADD R0, R0, R1    @ sum = sum + i (Corpo del For)
    
    SUBS R1, R1, #1   @ i = i - 1 [E AGGIORNA I FLAG]. Quando R1 = 0, attiva Z=1.
    BNE loop_for      @ Se Z=0 (cioè Not Equal, il decremento NON ha prodotto zero), riparti.

    @ Fine del ciclo. Non abbiamo mai avuto bisogno di una CMP!
```

---

## 📝 Esercizi del Capitolo 3

### Esercizio #1 – Tradurre un If-Else
Scrivere un frammento in Assembly in cui si confrontano `R1` e `R2`. 
Se `R1` è strettamente maggiore di `R2` (`R1 > R2`), metti il valore 10 dentro `R0`. Altrimenti (cioè se `R1 <= R2`), inserisci 20 dentro `R0`.
*(Indizio: Valuta la `CMP R1, R2` e usa il salto corretto verso l'else, come ad esempio `BLE - Branch Less or Equal`)*.

### Esercizio #2 – Conto alla Rovescia Ottimizzato
Realizza un ciclo `for` ottimizzato al contrario (decremento) partendo da 5 (in `R2`). Utilizza il trucco del `SUBS`.
Ad ogni istanza del ciclo, accumula i numeri dentro `R0`, in modo che alla fine in `R0` si calcoli $5+4+3+2+1$. 

### Esercizio #3 – La prima Subroutine (Uso del BL)
Definisci un'etichetta `raddoppia` che riceva un valore in `R0`, applichi un'istruzione in grado di moltiplicarlo per 2 (puoi usare un `LSL`), per poi restituire il controllo al codice di base istruendo la CPU a ritornare partendo dal Link Register (`BX LR`). 
Costruisci il tuo programma base (`_start`) in modo tale che chiami questa funzione passandogli vari numeri tramite la `BL`.
