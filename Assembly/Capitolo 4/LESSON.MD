# Capitolo 4: Strutture Dati Complesse e lo Stack

Per poter risolvere problematiche algoritmiche reali (gestione di database, stringhe di testo o logiche videoludiche), la singola manipolazione di una variabile temporanea `x` o `y` non è sufficiente. In questo ultimo capitolo ci dedicheremo al controllo di ingenti masse di dati contigui in memoria (**Vettori** e **Stringhe**) e al concetto critico della preservazione del "contesto" di esecuzione mediante l'impiego della memoria **Stack** (Pila).

---

## 4.1 I Vettori (Arrays) in Memoria

Un vettore (array) non è altro che una sequenza di dati memorizzati fisicamente l'uno accando all'altro (indirizzi continui) nella Random Access Memory (RAM). 
Ricorda il teorema di base dell'architettura ARM a 32-bit: ogni "parola" (`.word` = numero intero nativo) occupa esattamente **4 Byte**. 

Ciò significa che, muoversi lungo il vettore richiede balzi progressivi (+4, +8, +12 byte):
- Indice [0] ➔ Posizione Originale (es. RAM: `0x1000`)
- Indice [1] ➔ Offset di 4 Byte (es. RAM: `0x1004`)
- Indice [2] ➔ Offset di 8 Byte (es. RAM: `0x1008`)

### Dichiarare costrutti in `.data` e il Post-Incremento

In Assembly gli array pre-fabbricati o gli "spazi vuoti" di lavoro vengono allocati all'interno della direttiva riservata `.data`. 
Una direttiva vitale, che interviene ad arginare i crolli di sistema è il `.balign 4`. Poiché i blocchi ARM richiedono per Legge architetturale di essere allineati modularmente su multipli numerici di 4, si impone all'assemblatore di garantire l'allineamento inserendo questo parametro obbligatorio prima delle Word.

```assembly
.data
    .balign 4                      @ Regola d'oro: Allineamento base per word intere
    vettore_pieno: 
        .word 10, -5, 30, 42, 7    @ Creo un vettore predefinito lungo 5 elementi (20 Byte tot)
    vettore_vuoto: 
        .space 40                  @ Alloco "a vuoto" 40 byte (= 10 Word / interi pronti per esser popolati)
```

**Offset e Post-incremento automatico**  
Per scandagliare rapidamente un vettore in un ciclo senza impazzire ad aggiungere a mano `ADD R1, R1, #4` ad ogni turno, ARM dispone della magia del **Post-incremento**. Usando `[Reg], #N` nel comando di lettura `LDR`, l'hardware assorbirà prima brutalmente il dato all'indirizzo originario e dopodiché, contestualmente, spingerà avanti l'indirizzo del tuo puntatore di 4 passi, pronto pre-sistemato per il prossimo giro ciclico!

```assembly
@ In un ipotetico loop
LDR R4, [R1], #4    @ "Carica il numero in R4. Dopo, sposta permanentemente l'indirizzo di R1 in avanti di 4 byte!"
```

---

## 4.2 Le Stringhe e le letture al Byte (LDRB)

E i Vettori di caratteri di testo, le antiche **Stringhe**? 
Ogni Lettera, incodificata secondo lo standard base Tabella ASCII (es. la lettera 'a' = decimale 97, la 'A' = 65), è straordinariamente contenuta in un singolo, agile, **1 Byte**. E non 4 come logica di parola originaria ARM!

Per gestire l'allocazione massiccia ram si usa `.asciz "testo"`. L'estensione "z" finale significa "Zero Terminated" (C-Style), ossia il compilatore appenderà da solo un misterioso byte nullo `0x00` in coda al nome, che fungerà a te da "guardarail" algoritmico ("se leggi 0, la parola ha finito le lettere!").

> **Regola d'Oro per Stringhe:** Non puoi usare il generico `LDR` da 4 byte per l'alfabeto, per sbaglio risucchieresti intere parole compresse assieme causandoti crash! La sintassi speciale adibita ai caratteri è **`LDRB`** (Load Register Byte) che recupera dalla RAM una celletta pura da singolo Byte per turno; e qualora tu la volessi sovrascrivere o rimpiazzare il formato consueto sarà l'equivalente destinale **`STRB`** (Store Byte).

---

## 4.3 Gestire l'indirizzamento Dinamico: Il "Treno" dell'LSL

Talora un array richiede saltuariamente aggiornamenti discontigui, es. "*Modifica solamente gli Indici Dispari*".
Se avessi un puntatore ad indirizzo Base `R1` e un calcolatore/indice iterativo in accrescimento dentro `R2` (`R2`=0, `R2`=1, `R2`=2), non potresti incrociarli brutalmente con un semplice offset matematico, giacché se dicessi: 
`STR [numero], [R1, R2]` il salto che la CPU intenderà avverrà per "Singolo Byte" (R1 + 1 pos.Byte, +2 pos.Byte) ma tu stai manipolando i numeri Word da 4!

Il segreto sta nell'ancorare un'operazione di Logica Shift alla destra dello statement, così `R2` produrrà agilmente un "treno espanso": *Indice Corrente × 4*. Essere esperti matematicamente aiuta a scrivere un codice robusto.

```assembly
STR R10, [R1, R2, LSL #2]  @ Tattica Avanzata! L'indice iterativo `R2` (es. Posizione[2])
                           @ verca ingrandito Left Shift di 2 posizioni (ovverosia R2 * 2^2 = R2 * 4).
                           @ Così ottieni: Pos[2] * 4 byte di scarto = 8 byte di salto offset fisicato perfetto!
```

---

## 4.4 Modularità Avanzata: Le Subroutine e lo Standard AAPCS

Nel Capitolo 3 abbiamo appreso base l'idea di richiamare funzioni esterne per snellire il blocco "Main", usando `BL` (Branch with Link) e tornando a casa con `BX LR`.
Nella programmazione reale, tuttavia, le subroutine non agiscono a mani vuote: devono ricevere dei "Parametri" e restituire un "Risultato" coerente. In ARM vige a tale scopo uno standard istituzionale chiamato **AAPCS** (*ARM Architecture Procedure Call Standard*).

### La convenzione dei Registri Nudi (Subroutine a base semplice)
Secondo le norme AAPCS, se la tua Subroutine richiede dati di partenza, il chiamante (il tuo `_start`) deponi i valori tassativamente in file nei primissimi quattro registri in un esatto ordine:
*   **`R0`, `R1`, `R2`, `R3`**: I veicoli di trasporto per Argomenti e Parametri (es. un intero da testare, l'indirizzo array, o una stringa RAM).
*   **`R0`**: Lo stesso primo veicolo `R0` ha lo scopo esclusivo di **ospitare l'Output (es. il byte Result)** prima di spegnersi e tornare al padre chiamante.

Ecco un esempio di una Subroutine **chiusa ed indipendente**, eseguibile al 100% coi nudi registri (nessuno stack è per ora invocato perché la matematica operata al suo interno non necessita di altre sotto-chiamate):

```assembly
_start:
    LDR R0, =25      @ 1° Parametro d'ingresso (es: x=25)
    LDR R1, =5       @ 2° Parametro d'ingresso (es: y=5)
    
    BL calcola_sconto  @ Invoco la funzione "Calcola_Sconto"
    
    @ Al ritorno PC l'AAPCS garantisce che R0 possieda l'Output magico finale ("20")
    STR R0, [R10]    @ Salvo il Risultato Finale
    
stop:
    B stop

@ --- SUBROUTINE INDIPENDENTE (No Stack) ---
calcola_sconto:
    SUB R0, R0, R1   @ R0 accumulerà l'onere del risultato: (25 - 5 = 20)
    BX LR            @ Usa il tracciante LR per l'immediato rincaso.
```

---

## 4.5 Le Subroutine in coppia con lo Stack (SP)

Tutto fantastico finché gli esercizi sono elementari. Ma riflettici: **cosa accade se si avesse a che fare con una Subroutine abnorme, che impiegasse decine di registri locali (Le famose variabili `$v`: R4-R11) e che chiamasse di getto a sua volta svariate alterne subroutine (`BL`) nel mezzo del suo scorrimento?**
Una tragedia computazionale. Qualsiasi ulteriore balzo di `BL` rimpiazzerebbe disperatamente l'impronta GPS depositata in `LR` all'avvio frangendola, e l'usurpazione dei registri intaccherebbe irrimediabilmente i dati del Main di partenza che li credeva sacri.

Qui interviene **sua Maestà lo Stack Pointer (`SP` - R13)**, un registro specializzato alla manipolazione esplicita di una struttura Last-In-First-Out (LIFO) in RAM con una singolare modalità di "accrescimento all'incontrario" in memoria Discendente; un "tavolo" in cui parcheggiare temporaneamente i contenuti a rischio, fra cui l'`LR` prezioso delle subroutine madre, e ripescarli quando necessari. In ARM lo stack cresce **verso il basso** (da indirizzi alti a indirizzi bassi).

Prima dell'esecuzione algoritmica di una SubRoutine corposa, dobbiamo accatastare sul tavolo della RAM **tutti** i registri fragili. Esistono storicamente due metodi per "salvare il contesto" (Prologo ed Epilogo): l'approccio manuale (nativo e incalcolabilmente nobile) e l'approccio astratto (tramite macro).

### Metodo 1: Gestione Manuale della Subroutine (Senza PUSH / POP)

Questa è la manipolazione "nuda e cruda" essenziale per l'indirizzamento di argomenti superiori (Oltre il canonico R3, un Linguaggio C userebbe questo metodo forzando RAM!) o per erigere Buffer massivi Locali incamerati. 

```assembly
@ --- FUNZIONE MASTER (Utilizzo Subroutine Protetta da Stack) ---
grande_calcolatore:
    @ ============= PROLOGO (G. Manuale) =============
    @ 1. Emetto l'Allocazione: Scavo lo Stack discendente abbassando lo SP di 12 byte (3 Word spazio)
    SUB SP, SP, #12
    
    @ 2. Adagio i registri V ($v1,$v2 non alterabili per Regola!) e l'LR originario nei solchi ricavati.
    STR R4, [SP, #0]    @ Impianto stabile base (Offset #0 dalla vetta decrescente SP)
    STR R5, [SP, #4]    @ Risalgo in cima di 1 Word (Offset #4) e poso R5
    STR LR, [SP, #8]    @ Impacchetto le "Briciole di pollicino" LR salvandone il tracciato nativo
    @ ================================================

    @ --- CORPO DELLA SUA FUNZIONE ---
    MOV R4, R0          @ "Sporco" tranquillamente R4 (il Parametro di base inglobato R0)
    MOV R5, R1          
    
    BL calcola_sconto   @ BAM! Invocazione BL Annidata! (Sovrascriverà l'LR ma lo Stack ci protegge l'antenato!)
    
    @ Manipolazioni pesanti, l'esito torna con AAPCS inglobato su R0.. e si rientra!
    
    @ ============= EPILOGO (G. Manuale) =============
    @ 3. Rialzo il Tesoro: Prelevo esattamente nell'ordine depositato
    LDR R4, [SP, #0]
    LDR R5, [SP, #4]
    LDR LR, [SP, #8]    @ Miracolo! Ritrovo intatto l'LR originale che un'altra BL aveva sterminato.
    
    @ 4. De-Allocazione Doverosa: Elimino i Buffer temporanei (Restituendo i Miei 12 Byte!)
    ADD SP, SP, #12
    
    @ 5. Ritorno Ufficiale della Madre: AAPCS rispettato
    BX LR
    @ ================================================
```

### Metodo 2: L'utilizzo delle Macro di sistema (`PUSH` e `POP`)

Per sopperire alla noiosa ridondanza umana, gli assemblatori ARM moderni offrono due formidabili pseudo-istruzioni (`PUSH` e `POP`) che raggruppano da sé tutta la FASE UNO e FASE DUE viste pocanzi, abbassando o alzando lo scarto SP automaticamente per multipli interni dedotti dalle variabili in lista `{}`.

```assembly
mia_funzione_annidata_veloce:
    @ --- PROLOGO (Auto-Gestito) ---
    PUSH {R4, R5, LR}   @ Il sistema da solo alloca -12Byte e salva nell'astratto

    @ --- CORPO DELLA FUNZIONE ---
    
    @ --- EPILOGO (Auto-Gestito) ---
    @ Rimpasto i valori. Curiosità estrema: Anziché ricaricare [LR] e fare [BX LR],
    @ possiamo iniettare l'esito dirattamente nel PC chiudendo i giochi in una linea!!
    POP {R4, R5, PC}    
```

> ⚠️ **Attenzione / Errore Comune: "L'Asimmetria Fiscale dello SP"**
> Indistintantamente tu ricorra all'uso "Manuale" o alle istruzioni astratte Macro "Push / Pop", lo Stack è rigoroso e instabile. Se decidi di scavare la discesa per -12 Byte, in fondo al file di esecuzione tu **dovrai tassativamente** rigonfiarne simmetricamente le medesime +12 celle vuotate (O poppando lo stesso raggruppamento o invocando l'ADD). Lo Sbilanciamento dello Stack Pointer a chiusura Subroutine causa inevitabilmente il dirottamento PC, facendo arrestare di netto il computer intero per violazione critica o Kernel Panic in Assembly.

---

## 📝 Pronti all'Azione: Esercizi Pratici
Avventurati nella formattazione ad interazioni memory. Esgui compilazioni mirate nella cartella `Capitolo 4/Esercizi`.

*   **`es1.s` (Vettoriale base - Selezione Paritetica Positiva):**  
    Simula per intero lo scorrimento di `.word` applicando e manipolando l'`LDR` dotato di Post-Incremento `[R1], #4`. Unirà le filosofie del Chap3 impiegando un Branch condizionale sfaldante `BLE salta_somma` cosicché scavalchi elegantemente l'`ADD` accumulatore preservando l'ingaggio solo col flag limitante (>0).
    
*   **`es2.s` (Il Filtro Maiuscole per le Stringhe - Il C++ Array Characters):**  
    Punteggerai su `LDRB` (Load Singolo Byte). Ti misurerai al buio col terminale invisibile della string ASCII `0` in coda alla parola ".asciz". Per rimpallare le lettere, sfrutta logiche alfabetiche di distanza sottrattiva: Sottrai un Immediato equivalente a #32 al `[byte character letter]` processato e rilascialo sovrapponendolo istintamente allo scan nativo tramite ripescaggio `STRB` ad offset autoincremento!
    
*   **`es3.s` (L'Espressione a Shift di Coda per Allocazione Mista):**  
    Alloca a zero l'Array `.word` ed adopera come "filtro matematico pari/dispari iterativo" il Check flaggiativo logico `TST R2, #1` e valuta l'esecuzione Branching. Successenzialmente farai i conti finali col Treno "Str-Offset Espanso" in scala per depositare specifici salti multipli di 4 usando un fine operazione magica `STR [..., ..., LSL #2]`.