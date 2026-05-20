# Capitolo 1: Introduzione all'Architettura ARM e Istruzioni di Base

Benvenuto nel mondo della programmazione a basso livello. In questo primo capitolo, esploreremo le fondamenta dell'architettura **ARM** (Advanced RISC Machine), imparando come un processore "vede" e gestisce i dati, per poi cominciare a scrivere le prime istruzioni per controllarlo direttamente.

---

## 1.1 Livelli di Astrazione: Dalla Macchina all'Uomo

Un calcolatore comprende solo tensioni elettriche (accese/spente), matematicamente rappresentate come 1 e 0 (**Linguaggio Macchina**). Scrivere codice in binario è estremamente complesso per un essere umano.

*   **ISA (Instruction Set Architecture):** Rappresenta il set di "parole" e di regole (set di istruzioni) che il processore è in grado di comprendere ed eseguire. Ogni famiglia di processori (ARM, x86, MIPS) ha la propria ISA.
*   **Linguaggio Assembly:** È la traduzione leggibile (mnemonica) del linguaggio macchina. A ogni comando testuale (es. `ADD`) corrisponde una specifica serie di bit (es. `1110 0010 1000 ...`). 
*   **Linguaggio ad Alto Livello (C, Java, Python):** Astrae ulteriormente i concetti (variabili, loop, oggetti). Il compilatore li tradurrà in Assembly, e l'assemblatore li trasformerà in linguaggio macchina.

> **Regola d'Oro:** In Assembly sei "il padrone assoluto" dell'hardware. Non ci sono variabili predefinite o tipi di dato ad alto livello (int, float, stringhe); c'è solo memoria, registri e sequenze di bit, che sarai tu a dover manipolare e interpretare logicamente.

L'architettura **ARM** è di tipo **RISC (Reduced Instruction Set Computer)**. A differenza dei processori Intel/AMD dei computer fissi (CISC - Complex Instruction Set), ARM dispone di un set di istruzioni semplice, ridotto e ottimizzato per l'efficienza energetica e l'alta velocità, il che la rende il cuore del 99% degli smartphone, tablet, e sistemi embedded (come Raspberry Pi).

---

## 1.2 I 4 Principi di Progettazione

L'architettura RISC, e ARM in particolare, ruota attorno a quattro filosofie dettate da Hennessy e Patterson:

1.  **La regolarità favorisce la semplicità:** Ogni istruzione ha una lunghezza fissa (32 bit, ovvero 4 Byte). Questo rende l'hardware di decodifica (dentro la CPU) estremamente semplice e veloce.
2.  **Rendere veloci le cose frequenti:** Fornire poche istruzioni ma molto semplici, eseguibili in pochissimi cicli di clock.
3.  **Più piccolo è più veloce:** I processori ARM cercano di fare le operazioni matematiche usando un piccolo numero di memorie interne super-veloci (i Registri), evitando il più possibile di leggere dalla Memoria RAM centrale, che è immensa ma lentissima.
4.  **Un buon progetto richiede buoni compromessi:** Le dimensioni fisse delle istruzioni impediscono di caricare numeri enormi in un colpo solo, richiedendo tecniche compensative che esamineremo più avanti.

---

## 1.3 Il "Tavolo di Lavoro": I Registri e il CPSR

Per eseguire operazioni (sommare, sottrarre), il processore ARM richiede che i dati siano portati dalla memoria RAM all'interno del microprocessore stesso, in particolari celle di memoria chiamate **Registri**.

*   La CPU ARM (a 32 bit) possiede **16 Registri principali**, numerati da `R0` a `R15`.
*   Un blocco di dati a 32 bit in ARM è chiamato **Word (Parola)**. Ogni registro è ampio esattamente 1 Word (32 bit / 4 Byte).

### Tabella dei Registri e Convenzioni ARM (AAPCS)

| Registro | Alias | Funzione Principale |
| :--- | :--- | :--- |
| **R0 - R3** | $a1-$a4 | Variabili temporanee (Scratch) e passaggio di argomenti nelle funzioni. Non sono preservati tra le chiamate a funzione. |
| **R4 - R11** | $v1-$v8 | Variabili locali stabili. Devono essere salvate (di solito in memoria Stack) se una funzione intende utilizzarle e poi ripristinarle. |
| **R12** | IP | Intra-Procedure call register. Spesso usato come scratch temporaneo veloce. |
| **R13** | **SP** | **Stack Pointer:** Punta all'ultimo dato inserito nello *Stack*, una speciale area di memoria RAM usata al volo (LIFO). |
| **R14** | **LR** | **Link Register:** Salva l'indirizzo di ritorno al chiamante al termine di una subroutine/funzione. |
| **R15** | **PC** | **Program Counter:** Registra l'indirizzo in memoria dell'istruzione correntemente in elaborazione. |

Oltre a questi 16, la CPU contiene anche il **CPSR (Current Program Status Register)**, un registro di controllo vitale che memorizza al suo interno i flag di stato (es: risultato negativo, divisione per zero) essenziali per le operazioni condizionali dei capitoli successivi.

> ⚠️ **Attenzione / Errore Comune**
> Modificare manualmente `R13` (SP), `R14` (LR) o `R15` (PC) con normali operazioni matematiche `ADD` o `SUB` è consentito, ma altera la gestione hardware e il flusso logico causandone deviazioni inaspettate. Sii molto prudente. 

---

## 1.4 Aritmetica di Base: `ADD`, `SUB`, e Operandi

Grazie al "principio di regolarità", l'architettura ARM forza quasi tutte le istruzioni matematiche all'utilizzo rigoroso di **tre operandi**: 
`[ISTRUZIONE] [Destinazione], [Sorgente1], [Sorgente2]`

### Addizione (`ADD`)

Esegue la somma tra Sorgente1 e Sorgente2. Il risultato è scritto in Destinazione.

```assembly
@ Equivalente C: a = b + c
@ Assumiamo l'assegnazione nei registri: R0 = a (Destinazione), R1 = b, R2 = c

ADD R0, R1, R2 
```
**Esecuzione e mutazione dello stato:**
* *Prima:* R1 contiene `5`, R2 contiene `3`.
* L'ALU somma i due valori interni indipendentemente dai contenuti originari in memoria.
* *Dopo:* R0 viene sovrascritto col risultato iterativo `8`. R1 e R2 restano `5` e `3`.

### Sottrazione (`SUB`)

Esegue la sottrazione `Sorgente1 - Sorgente2`.

```assembly
@ Equivalente C: x = y - z
@ Setup: R4 = x, R5 = y, R6 = z

SUB R4, R5, R6
```

### Operazioni Composte e Variabili Temporanee

Non possiamo tradurre un'espressione composta come `X = (A + B) - (C + D)` in una sola istruzione assembly. Va frammentata usando registri di supporto provvisori. 

```assembly
@ x = (A+B) - (C+D)  -> Assumiamo: X=R10, A=R1, B=R2, C=R3, D=R4

ADD R0, R1, R2   @ R0 diventa A+B
ADD R12, R3, R4  @ R12 diventa C+D
SUB R10, R0, R12 @ R10 (X) accumula il risultato finale (R0 - R12)
```

---

## 1.5 Costanti, Immediati e Assegnazione (`MOV`)

L'`ADD` somma, ma come diamo un numero di partenza al computer? Usando i valori costanti chiamati in gergo **Immediati**, indicati tassativamente dal pre-fisso `#`.
L'istruzione **`MOV`** (Move) trasferisce un numero dentro un registro "ripulendone" il residuo esistente.

```assembly
MOV R0, #10      @ Inizializza il decimale base 10 dentro R0   (R0 = 10).
MOV R1, #0xFF    @ Valore pre-inserito in esadecimale          (R1 = 255).
MOV R2, R0       @ Trasferimento (Copy) da registro a registro (R2 = 10).
```

Il costrutto ad Immediati vale sia col termine `MOV` che nelle istruzioni logiche aritmetiche descritte poco sopra. L'immediato è ammesso come operando, ma occhio: **deve essere esclusivamente posizionato come l'ultimo dei tre.**

```assembly
ADD R0, R1, #5   @ R0 = R1 + 5. Corretto.

@ SUB R2, #10, R3  <-- ⚠️ ERRORE: L'immediato NON può essere il 2° operando in SUB!
@ Se desidero 10 - R3, si dovrà applicare un escamotage tramite RSB:
RSB R2, R3, #10  @ RSB = Reverse Subtract (Sottrazione invertita): R2 = 10 - R3
```

---

## 1.6 Impalcatura del Codice e Direttive di File

I sorgenti Assembly possiedono delle istruzioni ausiliarie utili solo all'eseguibile (l'assemblatore). Queste si chiamano **Direttive** (precedute da `.` punto).

### Esempio Pratico Completo (Simulazione)
```assembly
.global _start      @ Espone esteriormente dal file corrente l'etichetta `_start` per il setup e la generazione del binario

.data               @ Inizio segmento: Memoria statica (Variabili RAM non su CPU)
    @ Qui inserirai gli array o altre costanti globali nei doc successivi...

.text               @ Inizio segmento: Spazio puramente esecutivo e di istruzioni CPU
_start:             @ Label: Identifica al Program Counter da dove originare l'analisi

    MOV R0, #5      @ Immagina d'iniziare settando R0 a 5.
    MOV R1, #12     @ Poi R1 a 12.
    ADD R2, R0, R1  @ Adesso sommarli allocandone lo stato all'interno di R2
    
    @ ... il codice procede ...
```

* **Etichette (Labels come `_start:`):** Segnaposti simbolici nel flusso di esecuzione (come un "qui c'è l'inizio", oppure "qui finisce un loop").

---

## 📝 Pronti all'Azione: Esercizi Pratici
Adesso entra nella cartella `Esercizi/` di `Capitolo 1`. Compila o segui l'algoritmo step-by-step su carta.

*   **`es1.s` (Manipolazione `SUB` ed `ADD`)**  
    Mostra come `R0` riceva il risultato di un `SUB` e venga poi utilizzato nella riga successiva per una ri-assegnazione ricorsiva in un calcolo C simulato (`y = x + y`).
*   **`es2.s` (Valori Immediati `MOV`)**  
    Richiede d'ingettare i valori 10 e 15 (ricordati il simbolo `#`) inside i registri e sommarli.
*   **`es3.s` (Matematica a 3 Operandi con `ADD`)**  
    Testa le tue abilità simulando l'equazione estesa matematica utilizzando multipli registri temporanei combinati fra loro!
