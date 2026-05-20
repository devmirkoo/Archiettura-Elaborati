# Capitolo 3: Gestione del Flusso di Controllo e Sottoprogrammi

Benvenuto nel terzo capitolo del tuo percorso verso la maestria in Assembly ARM. Finora abbiamo scritto codice "lineare": istruzioni eseguite una dopo l'altra senza sosta. I linguaggi di alto livello, tuttavia, traggono la loro potenza decisionale dai costrutti di controllo (come **If-Else**, **For/While**) e dalla modularità delle **Funzioni**.
In Assembly, non esistono costrutti semantici pre-fabbricati superiori; saremo noi a tradurli pezzo per pezzo, dominando esplicitamente i registri di stato, i confronti chimici e le istruzioni di Salto (Branching).

---

## 3.1 Un Giudice Silenzioso: Il Registro CPSR e i Flag

Per effettuare una scelta (es. `se x > y allora...`), la CPU deve prima compiere un test matematico. L'hardware adibito non formula riflessioni verbali, ma restituisce la diagnosi di questo test alterando dei bit speciali chiamati **Flag di Condizione**. 
Tali marker risiedono stabilmente nel **CPSR** (*Current Program Status Register*), il "libro mastro" delle operazioni in corso.

Le quattro Flag fondamentali manipolate dall'ALU (Arithmetic Logic Unit) sono:
*   **Z (Zero):** Si accende (`1`) se l'ultimo risultato del calcolo è stato matematicamente **0**. (Esempio: 5-5 = 0. Se è 0, le due variabili testate sono palesemente uguali!).
*   **N (Negative):** Si accende (`1`) se il risultato è strettamente negativo (ovvero se il bit più significativo MSB della Word è impostato a 1).
*   **C (Carry):** Si accende (`1`) quando c'è un riporto in un'addizione che supera il confine dei 32 bit, o un mancato "prestito" in una sottrazione unsigned.
*   **V (Overflow):** Si accende (`1`) se un calcolo con numeri "Signed" trancia i limiti, sfalsando il bit del segno (es. sommo due immensi numeri positivi uscendo dai margini logici ed il computer li interpreta come negativi).

> **Regola d'Oro del Test (Il suffisso `S`):**
> Le normali istruzioni (`ADD`, `SUB`) **non** aggiornano autonomamente il CPSR! Per obbligarle a scriverne il resoconto accendendone le Flag si DEVE apporre il magico suffisso `S`. (Esempio: `ADDS`, `SUBS`). 

---

## 3.2 L'Istruzione di Confronto Assoluta: `CMP`

Sovente, noi vogliamo unicamente *verificare* lo scarto fra due registri, **senza manomettere o sovrascrivere** minimamente il loro contenuto con una stima.

Per questo interviene `CMP` (Compare - Confronta). L'istruzione `CMP` attua internamente una sottrazione invisibile fra il Primo Operando ed il Secondo (Operando1 - Operando2), si occupa puntualmente di **aggiornare rigorosamente i Flag** su base della differenza, per poi procedere gettando alle fiamme l'output! I valori in entrata rimarranno perciò illesi, offrendovi al tempo stesso l'accensione utile del Flag nel CPSR pronto per l'indagine condizionale.

```assembly
@ Equivalente C:  if (R1 == R2)
MOV R1, #10
MOV R2, #10

CMP R1, R2      @ Il core simulerà: 10 - 10 = 0.
                @ Essendo zero il risultato... BAM! 
                @ Il Flag Z (Zero) si imposta ad 1. I registri R1 ed R2 restano intatti a 10.
```

---

## 3.3 Saltar le recinzioni: Branching Base in ARM (`B`) 

Appurato come si attivano i segnali sul CPSR, occorre fornire al sistema il comando adibito affinché intercetti tale logica alterando a piacimento il susseguirsi istruzionale.
In ARM il balzo nel codice si attua prevaricando il *Program Counter (`R15 – PC`)* ricorrendo primariamente alle istruzioni `Branch (B)`.

### 1) Salto Incondizionato (`B`)
Il `B` liscio equivale al caro vecchio (e disprezzato) `GOTO` dei primi linguaggi. Permette un dirottamento forzato verso un'Etichetta in modo istantaneo ed incodizionato, senza ascoltare alcun Flag nel CPSR.

```assembly
_start:
    MOV R0, #1
    B mia_destinazione   @ Salto immediato scavalcando il MOV #2
    MOV R0, #2           @ <-- Questo codice non verrà MAI eseguito!

mia_destinazione:
    MOV R0, #3           @ L'azione atterra qui e il PC prosegue.
```

### 2) Salti Condizionati (Il suffisso logico)

Ecco svelata la magia dell'`if`! Un balzo `B` può essere subordinato aggiungendo le desinenze di test. Il salto accadrà **SOLO E SOLTANTO SE** i Flag dentro al CPSR collimano col resoconto desiderato, altrimenti lo rimpiazzerà procedendo inesorabilmente giù alla riga attigua.

| Istruzione | Condizione Logica | Stato Flag Verificato | Significato C++ / Algoritmo |
| :--- | :--- | :--- | :--- |
| **`BEQ`** | Branch if EQual | Z = 1 | `if (A == B)` |
| **`BNE`** | Branch if Not Equal | Z = 0 | `if (A != B)` |
| **`BGT`** | Branch Greater Than | Z = 0, N = V | `if (A > B)` |
| **`BGE`** | Branch Greater or Equal| N = V | `if (A >= B)` |
| **`BLT`** | Branch Less Than | N != V | `if (A < B)` |
| **`BLE`** | Branch Less or Equal | Z = 1 OR N != V | `if (A <= B)` |

*(L'elenco si riferisce in special modo ai test generati tra numeri CON Segno)*.

### 3) L'Esecuzione Condizionale a livello di Istruzione (Non solo Salti!)
I linguaggi tradizionali permettono di "condizionare" solo blocchi interi via *if*. La formidabile architettura ARM, invece, ti dona l'**Esecuzione Condizionale Globale**.
I suffissi temporali di confronto elencati in tabella (`EQ`, `NE`, `GT`, `LT`, etc.) non sono affatto relegati all'uso limitativo sui Branch (`B`), ma **possono essere applicati a pressoché quasi tutte le istruzioni base registrali (matematiche e logiche)** come `ADD`, `SUB`, `MUL`, `MOV` o `LDR`!

Combinando il test di una riga superiore, tu potrai sommare, assegnare o immagazzinare valori *solo se* la condizione viene rispettata, risparmiando salti viscerali continui ed incrementando notevolmente le performance per le selezioni a passo singolo.

```assembly
CMP R1, R2       @ R1 e R2 sono equivalenti?  [Genera Zero Flag: Z=1]

@ Se Z=1 (quindi EQ), esegui il MOV. Se Z=0, Ignorala come non fosse mai esistita!
MOVEQ R0, #10    @ Corrisponde a: if(R1 == R2) { R0 = 10; }

@ Lo stesso vale per procedure Aritmetiche!
ADDGT R3, R3, #1 @ Aggiungi a R3 + 1, SOLO e SOLTANTO SE (Greater Than) R1 > R2.
```

---

## 3.4 Tradurre alla Scrivania: If-Else Layout

Assemblare un blocco di selezione richiede pianificazione visiva. Dovremo ragionare spingendo l'Architettura verso la logica avversa scartante: un ramo (tipicamente quello negativo) sarà saltato fisicamente, se non dovesse realizzarsi, costringendoci perfino a usare balzi suppletivi per fuggire al completamento dal blocco "concorrente"!

### Traduzione classica
```c
if (R1 >= R2) {
    R0 = 10;
} else {
    R0 = 20;
}
```

```assembly
    CMP R1, R2         @ Test della condizione 
    BLT else_block     @ ATTENZIONE: Inverto la condizione per comodità! Se R1 < R2 (Less Than), balzo direttamente giù al ramo ELSE!
    
    @ --- RAMO IF --- (eseguito solo per fallimento del balzo precedente, ossia R1 >= R2 vero!)
    MOV R0, #10        
    B end_if           @ INDISPENSABILE: Terminato l'IF devo far saltare la CPU per Evitare che cada e fagociti il blocco Else affianco!
    
    @ --- RAMO ELSE ---
else_block:
    MOV R0, #20     

    @ --- FINE FLUSSO ---
end_if:
    @ Si approderà tutti qui...
```

---

## 3.5 Creazione Cicli ottimizzati: Il Trucco del `SUBS`

L'istinto iniziale per gestire cicli For in decrescita indicherebbe la scrittura di formidabili contatori, combinando decrescite lineori ed il solito `CMP`.
```assembly
    @ VERSIONE SCOLASTICA
loop_for:
    @ ... (eseguo istruzioni) ...
    SUB R2, R2, #1     @ Abbasso Indice iterativo 
    CMP R2, #0         @ Verifico la presenza a 0 ?
    BNE loop_for       @ Ritorno all'inizio se la stima regge (Not Equal a zero)
```

In ARM vige il "Rendere Veloci le cose Pratiche". Anziché sfiancare la macchina con `SUB` ed una `CMP` perenne, fondiamole nel compatto istinto combinatorio del **Suffisso S (`SUBS`)**!

```assembly
    @ VERSIONE OTTIMIZZATA ARM (Un'intera istruzione decurtata!)
loop_for:
    @ ... (eseguo istruzioni) ...
    SUBS R2, R2, #1    @ Decrementa e "simultaneamente" AGGIORNA LE FLAG NEL CPSR!
    BNE loop_for       @ Sente automaticamente il Flag e cicla finquando R2 tocca 0 (e scatterà l'equal!)
```

> ⚠️ **Attenzione / Errore Comune: "Il Fall-Through"**
> Al termine del corpo generale non sussistendo confini reali e netti, il processore (che avanza riga per riga la lettura PC) fagociterà e proseguirà l'esecuzione sui segmenti sottostanti anche se si trattano di etichette secondarie separate. Fai in modo di ingabbiare il blocco principale (`B stop`) senza far cadere la lettura in pozzi non richiamati attitudinalmente! 

---

## 3.6 Il Graal della Programmazione: Subroutines ed Indirizzi (`BL`)

Dividere ampie macro-richieste in agili funzioncine invocabili dal nostro Main (`_start`) in gergo si definiscono **Subroutines**. 

Saltare col normale `B` non ci porterà però alla soluzione di "ritorno a casa".
L'architettura ci porge allora `BL` (*Branch with Link*): esso scaturisce formalmente un balzo consueto, ma salvando intelligentemente la coordinata d'atterraggio nativa dell'istruzione seguente nel prezioso **Link Register (`LR` - R14)**.
In questo modo a Subrotine conclusa potremo disfare il balzo dicendogli semplicemente "Guida al Return basandoti sulle metriche depositate su LR": istruendo un provvidenziale `BX LR`.

```assembly
_start:
    MOV R0, #5
    BL raddoppia       @ Balza verso "raddoppia", e spara nel [LR] il ritorno (Riga dopo)
    
    @ ...Il programma proseguirà pacificamente qui a funzio concluso...
    
stop:
    B stop             @ Arresto di sicurezza Fall-through

raddoppia:
    LSL R0, R0, #1     @ Traslazione d'operande per originare X 2
    BX LR              @ "Branch eXchange" ritornanti all'istruzione in riga salvata nel [LR].
```

---

## 📝 Pronti all'Azione: Esercizi Pratici

Entra nella cartella `Esercizi/` di `Capitolo 3`. Presta rigorosa diligenza nell'osservare non solo i blocchi if, ma la gestione protetta del flow istruzionale che arresta il fall through grazie al classico loop ombra `B stop`.

*   **`es1.s` (Tradurre un If-Else Strutturato):**  
    Testa minuziosamente col `CMP` i caricamenti delle due variabili dalla struct in RAM (`number`). Usufruendo di un `BLT` indirizzato sapientemente genererai l'inversione d'innesco ad un blocco `else_block` protetto da sovrascritte accidentali da uno scutivo `B end_if`.

*   **`es2.s` (Cicli veloci col costrutto `SUBS`):**  
    Ammirerai la bellezza accattivante di un ciclo retroattivo. Avvierai `R0` vuotato per il deposito dei risultati, e grazie a `SUBS` applicherai decrescimento per un `BNE` fluido sprovvisto in assoluto del noioso `CMP`.

*   **`es3.s` (Modularità avanzata e `BX LR`):** 
    Studierai il richiamo su `BL` che delegherà i registri alla stringa d'elaborazioni annidate della sub-funzione "raddoppia", provvidente della moltiplicativa e conclusasi pacificamente e magicamente sul Main point originario grazie a `BX LR`. Riponi le label extra in coda all'Applicazione, cosicché il flusso scivoli senza cadervi inesortato.