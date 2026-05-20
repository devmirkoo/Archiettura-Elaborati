# Capitolo 1: Introduzione all'Architettura ARM e Istruzioni di Base

In questo capitolo getteremo le fondamenta dell'architettura ARM, comprendendo come il processore "vede" il mondo e come possiamo impartirgli ordini semplici.

## 1.1 Livelli di Astrazione: L'Architettura
Quando programmiamo a basso livello, scendiamo di astrazione rispetto a linguaggi come C o Java. L'**Architettura** è la visione che il programmatore ha del calcolatore: è definita dal set di istruzioni (i comandi) e da dove si trovano gli operandi (registri e memoria).

*   **Linguaggio Assembly**: La forma leggibile dall'uomo delle istruzioni.
*   **Linguaggio Macchina**: Sequenze di 1 e 0 comprese dal processore.

L'architettura che studieremo è **ARM**, una tipologia di processore RISC estremamente diffusa, alla base della quasi totalità di smartphone e tablet.

## 1.2 I Principi di Progettazione
Il design ARM segue quattro celebri principi (Hennessy e Patterson):

1.  **La regolarità favorisce la semplicità**: Un formato costante per le istruzioni semplifica l'hardware di decodifica.
2.  **Rendere veloci le cose frequenti**: ARM è un'architettura **RISC** (Reduced Instruction Set Computer). Offre poche istruzioni semplici e velocissime.
3.  **Più piccolo è più veloce**: I processori preferiscono operare su un numero limitato di registri interni piuttosto che sulla memoria (più grande ma lenta).
4.  **Un buon progetto richiede buoni compromessi.**

## 1.3 Il "Tavolo di Lavoro": I Registri
ARM esegue le operazioni aritmetiche su memorie microscopiche interne chiamate **registri**.

*   **32 bit**: ARM elabora dati da 32 bit e ogni registro è grande esattamente 32 bit.
*   **16 Registri**: Chiamati da `R0` a `R15`.

### Convenzioni sui Registri:
*   `R0`-`R3`: Passaggio parametri e variabili temporanee.
*   `R4`-`R11`: Variabili locali/permanenti.
*   `R13` (**SP** - Stack Pointer): Punta alla cima dello Stack.
*   `R14` (**LR** - Link Register): Indirizzo di ritorno per le funzioni.
*   `R15` (**PC** - Program Counter): Indirizzo dell'istruzione corrente.

## 1.4 Aritmetica di Base: `ADD` e `SUB`
Le operazioni più comuni. Grazie al **Principio della Regolarità**, richiedono esattamente tre operandi: destinazione, sorgente 1 e sorgente 2.

### Addizione (`ADD`)
```assembly
; Codice C: a = b + c
; Supponiamo R0 = a, R1 = b, R2 = c
ADD R0, R1, R2   ; R0 = R1 + R2
```

### Sottrazione (`SUB`)
```assembly
; Codice C: a = b - c
SUB R0, R1, R2   ; R0 = R1 - R2
```

### Operazioni Composte
Per eseguire `a = b + c - d`, dobbiamo spezzare l'istruzione usando un registro temporaneo:
```assembly
; Codice C: a = b + c - d
; Supponiamo R0=a, R1=b, R2=c, R3=d
ADD R12, R1, R2  ; R12 = b + c (temporaneo)
SUB R0, R12, R3  ; R0 = R12 - d
```

## 1.5 Costanti (Valori Immediati)
I valori scritti direttamente nel codice si chiamano **Immediati** e si indicano con `#`.

```assembly
ADD R0, R0, #4   ; R0 = R0 + 4
```

L'istruzione `MOV` (Move) carica un valore in un registro:
```assembly
MOV R0, #23      ; R0 = 23
MOV R1, #0x45    ; R1 = 69 (esadecimale 0x45)
```

Poiché le istruzioni ARM sono a 32 bit, non possiamo inserire una costante a 32 bit in un singolo `MOV`. Per costanti grandi si usano tecniche come `ORR` o `LDR`, che vedremo più avanti.

## 1.6 Struttura di un file Assembly sorgente e Direttive
Per poter far effettivamente "girare" un applicativo, l'eseguibile richiede un'impalcatura formale fornita dalle direttive per l'assemblatore (solitamente anticipate da un punto `.`).
Un file standard presenta queste macro-aree:
*   `.global _start` (oppure il nome di un'altra etichetta base): Permette al linker (o a un compilatore esterno come C) di rendere "pubblica" un'etichetta fuori dal file sorgente per farle avviare l'esecuzione principale.
*   `.text`: Identifica l'avvio della zona contenente le istruzioni da eseguire a livello CPU (il codice).
*   `.data`: Segmenta uno spazio in memoria RAM unicamente dedicato allo storaggio statico delle variabili, Array o Stringhe utili all'avvio. 

```assembly
.global _start      @ Dichiara il punto di ingresso visibile dall'esterno

.text               @ Qui sotto inizio a scrivere codice logico
_start:
    MOV R0, #5
    @ ... il tuo programma ...

.data               @ Qui sotto alloco la memoria al boot
    variabile_mia: .word 10
```

---

## 📝 Mettiti alla Prova: Esercizi del Capitolo 1

### Esercizio 1: Traduzione Semplice
Traduci il seguente codice C in Assembly ARM.
*   `x` in `R0`, `y` in `R1`, `z` in `R2`.
```c
x = y - z;
y = x + y;
```

### Esercizio 2: Inizializzazione ed Elaborazione
Scrivi il codice per:
1. Inserire `10` in `R4`.
2. Inserire `15` in `R5`.
3. Sommare `R4` e `R5`, salvando in `R6`.

### Esercizio 3: Operazioni Complesse
Traduci: `X = (A + B) - (C + 5)`
*   `A=R1`, `B=R2`, `C=R3`, `X=R0`.
*   *Suggerimento*: Usa `R4` e `R5` come temporanei.
