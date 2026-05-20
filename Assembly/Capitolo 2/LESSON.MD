# Capitolo 2: Accesso alla Memoria, Shift dei Bit e Moltiplicazioni a 64 Bit

Ora che sappiamo come manipolare i registri e spostare numeri costanti (`MOV`), dobbiamo colmare una lacuna cruciale: **come comunichiamo con la RAM?** La memoria nei registri è poca (solo 16 slot), quindi apprenderemo come leggere e scrivere grandi masse di dati.
Inoltre, esploreremo come operare chirurgicamente a livello del singolo bit tramite le operazioni di **Shift e Rotazione**, per poi concludere con le imponenti operazioni di **Moltiplicazione a 64 bit**.

---

## 2.1 Architettura ARM e RAM: Un design "Load/Store"

Come detto nel Principio 3 (Chap.1), "più piccolo è più veloce". I processori ARM non permettono alle istruzioni matematiche (`ADD`, `SUB`) di agire direttamente sulla memoria RAM.
Se vuoi sommare due numeri che risedono nella RAM, **devi prima portarli nei registri**, sommarli, e **poi riportare il risultato in RAM**.
Questo design si chiama **Load/Store Architecture**.

Per questo scopo, ARM prevede due potenti istruzioni per interfacciare CPU e Memoria:
*   **`LDR` (Load Register):** RAM ➔ Registro (Lettura)
*   **`STR` (Store Register):** Registro ➔ RAM (Scrittura)

---

## 2.2 Leggere la Memoria: `LDR`

`LDR` preleva un'intera *Word* (32 bit / 4 Byte) dall'indirizzo di memoria specificato e la copia in un registro di destinazione.

### Fase 1: Caricare l'indirizzo (Puntatore)
Prima di leggere un dato creato nella sezione `.data`, dobbiamo "puntare" ad esso ottenendo il suo indirizzo a 32 bit. Si usa una pseudo-istruzione di LDR con il simbolo `=`:

```assembly
LDR R0, =variabile_mia   @ "Carica l'INDIRIZZO (Pointer) di 'variabile_mia' in R0"
```
*`R0` ora non contiene il numero, ma ad es: `0x00008044` (L'indirizzo di memoria in cui riposa il contenuto).*

### Fase 2: Estrarre il contenuto (Dereferenziazione)
Una volta che si ha l'indirizzo in un registro di base, si utilizzano le parentesi quadre `[ ]` per dire al processore: *"Vai nell'indirizzo che hai letto dentro questo registro e prendimi quello che vedi colà"*.

```assembly
LDR R1, [R0]   @ "Leggi 32-bit di memoria all'indirizzo in R0, salva in R1"
```

> **Regola d'Oro del Puntatore (Le Quadre `[ ]`):**  
> In Assembly, un registro puro `R0` si comporta come una variabile numerica. Quando scriviamo `[R0]`, stiamo usando le sue cifre come "Indirizzo Civico" per consultare l'hotel della RAM. Le parentesi quadre equivalgono all'operatore puntatore `*` del linguaggio C.

### Gli Offset: Muoversi nei Vettori/Array
Spesso in `.data` si dichiarano dati contigui (es. `10, 20, 30`). Per leggere il secondo valore, basta spostarsi in memoria. Poiché ogni registro / dato standard di ARM pesa **4 Byte**, l'elemento successivo disterà sempre 4 slot.

```assembly
LDR R1, [R0]       @ Carica il 1° elemento (all'offset 0)
LDR R2, [R0, #4]   @ Carica il 2° elemento (all'offset di 4 Byte)
LDR R3, [R0, #8]   @ Carica il 3° elemento (all'offset di 8 Byte)
```

---

## 2.3 Scrivere la Memoria: `STR`

Speculare al Load, lo `STR` riversa il contenuto di un Registro in una determinata area (Indirizzo) di RAM.

Attenzione al posizionamento degli operandi! In `LDR` la destinazione è a sinistra, in `STR` la destinazione della scrittura (l'indirizzo in parentesi quadre) sta a destra:
`STR [Sorgente], [Indirizzo_Destinazione]`

```assembly
@ Equivalente C:  *risultato = x;
MOV R5, #100       @ Il mio valore da salvare, depositato in R5
LDR R4, =risultato @ Carico l'indirizzo in cui scrivere
STR R5, [R4]       @ "Prendi il valore [100] di R5 e schiantalo nella RAM alla cella puntata da R4"
```

---

## 2.4 Manipolazione dei Bit: Shift e Rotazione

A volte non ci importa del "numero" ma della singola posizione dei bit al suo interno (`1` e `0`). Eseguire shift dei bit apre le porte all'ottimizzazione matematica estrema. Spostare i bit a Sinistra (Left) oppure a Destra (Right) emula fisicamente la moltiplicazione e divisione su base 2.

### `LSL` (Logical Shift Left) - "Moltiplicatore rapido"
Sposta tutti i bit verso *sinistra*. Per ogni scorrimento a sx, in ingresso (da destra) vengono inseriti zeri formali. 
Uno spostamento matematicamente è pari ad una **Moltiplicazione per Potenze di 2 ($2^n$)**.

```assembly
@ Voglio fare in C: int y = x * 32;
MOV R1, #5         @ Imposto R1 a 5. (Binario: ...00101)
LSL R5, R1, #5     @ R5 = R1 sciftato left di 5 bit = R1 * 2^5 = 5 * 32. 
                   @ R5 conterrà il numero 160.
```

### `LSR` (Logical Shift Right) - "Il Divisore e l'Estrapolatore"
Sposta i bit verso *destra*. I bit estremi destri (meno significativi) escono, mentre entrano zeri fittizi da sinistra.
LSR equivale a una **Divisione intera per Potenze di 2 ($2^n$)**. È formidabile anche per estrarre maschere di bit!

```assembly
@ CASO STUDIO: Voglio estrapolare il Bit di Segno in matematica Complesso Due.
@ In Architettura a 32 Bit, il bit più massiccio da sinistra (il MSB - Bit 31) definisce 
@ se un numero è Positivo [0] o Negativo [1]. 

LDR R2, =-32       @ R2 ha il bit MSB acceso (1)
LSR R6, R2, #31    @ Scifto tutto di ben 31 posizioni a destra! 
                   @ I primi 31 si perdono nell'etere; l'ultimo bit finisce nella posizione di partenza.
                   @ Se era negativo, R6 ora vale un puro `1`, se positivo conterrà `0`.
```

### `ASR` (Arithmetic Shift Right) e `ROR` (Rotate Right)
*   **ASR**: Lo shift distrugge il bit di segno buttando dentro zeri. ASR fa lo shift a destra *mantenendo* e copiando progressivamente il bit del segno. Ideale per dividere coerentemente i numeri negativi (`int y = X / 4`, dove X è negativo).
*   **ROR**: Nessun bit si perde; il bit in uscita a destra rientra circolare dallo slot a sinistra! Utile in hashing e cryptografia.

> ⚠️ **Attenzione / Errore Comune: "Dividere con LSR"**
> Considera un binario: `-4`. Se provi a dividerlo a metà sfruttando LSL (`LSR R1, R0, #1`), sposti sì tutti a dx ma butti dentro degli `0`. Hai inserito in cima uno zero? Complimenti: il tuo numero da negativo è ora diventato uno sproporzionato numero positivo da +2 Miliardi (per via della conversione due). **Usa sempre ASR con i numeri dotati di segno.**

---

## 2.5 L'Aritmetica Pesante: La Moltiplicazione a 64 Bit

L'Addizione è basica, la Moltiplicazione no.
Moltiplicare tra loro due numeri a 32 bit può produrre fisiologicamente risultati enormi... che richiedono **64 bit**!

L'istruzione normale (`MUL R0, R1, R2`) scarta brutalmente tutto ciò che sfora i primi 32 bit, creando overflow silenziosi catastrofici in caso di valori elevati. Affrontando numeri reali (Signed), si ricorre alla controparte estesa:

### `SMULL` (Signed Multiply Long)
Accetta quattro operandi e moltiplica due registri con i relativi segni. Suddivide l'immensa dimensione di output su **Due Distinti Registri** destinatari.
*   Il primo conterrà i primi 32 bit del numero (Parte Bassa).
*   Il secondo conterrà i successivi 32 bit + Segno (Parte Alta).

Sintassi: `SMULL [Hi-Parte], [Lo-Parte], [Sorgente1], [Sorgente2]`
*(Nota: molti manuali invertono l'ordine delle parti - Lo, Hi - a seconda dell'assemblatore; noi usiamo RegBassa, RegAlta).*

```assembly
@ Sintassi comunemente impiegata in GNU ARM: 
@ SMULL R-Lo_Dest, R-Hi_Dest, R-Sorg1, R-Sorg2

LDR R5, =100000000 @ Cento milioni
LDR R6, =250000000 @ Duecentocinquanta milioni
SMULL R8, R9, R5, R6 
@ Ora R8 stiva i bit 0-31 del super numero.
@ R9 memorizza i bit 32-63 del numero colossale finale. E NON perdiamo alcun carry!
```
Per estrarre o salvare questi super valori in Memoria (`STR`), **si usano due salvataggi separati con offset di 4 Byte!**

---

## 📝 Pronti all'Azione: Esercizi Pratici

Entra nella cartella `Esercizi/` di `Capitolo 2`. Ecco cosa andrai ad affrontare per cementificare i nuovi concetti, tutti basati su un interazione di `.data`:

*   **`es1.s` (Moltiplicazione rapida con `LSL`)**
    Leggerai una variabile statica `number`. Senza invocare alcun `MUL`, la dovrai moltiplicare pregevolmente per `32` applicando ad `R1` uno shift verso sx, iniettandone il super valore ottenuto in RAM in `.word result`.
    
*   **`es2.s` (Estrazione fine di MASCHERA di Bit - `LSR`)**
    Un calcolo scientifico richiede unicamente che si verifichi se la cifra originata all'indirizzo memoria `.word number (-32)` sia positiva (0) o negativa (1). Dovrai sfruttare l'LSR per prelevare il 31esimo bit (MSB), svuotando tutto il resto della stringa e salvandone univocamente l'estratto su `.word result`.
    
*   **`es3.s` (Esondazione dello storico a 64 Bit - `SMULL`)**
    Impara definitivamente la Load/Store per gli Array vettoriali! Caricherai da `.word number` sia l'elemento offset #0 che l'offset #4 (il secondo numero contiguo).
    Eseguita l'estesa e mastodontica `SMULL` su due registri low e high res, dovrai parcheggiare *due differenti salvataggi Memory STR* sfalsati analogamente a scaglioni di 4 Byte sull'allocazione `.word result 0, 0` che offre giusto il doppio dello spazio nativo!