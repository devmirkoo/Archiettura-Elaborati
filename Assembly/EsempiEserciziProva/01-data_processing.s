.global _start          @ Rende l'etichetta _start visibile al linker (punto di ingresso del programma)
_start:                 @ Etichetta che indica l'inizio dell'esecuzione del codice

    @ --- FASE 1: CARICAMENTO DATI DALLA MEMORIA AI REGISTRI (Load) ---
    LDR R3, =numbers    @ Carica in R3 l'INDIRIZZO di memoria dell'etichetta 'numbers' (puntatore base)
    LDR R1, [R3]        @ Legge il valore a cui punta R3 (offset 0) e lo mette in R1. R1 = 20 (Variabile 'a')
    LDR R2, [R3, #4]    @ Legge all'indirizzo R3 + 4 byte. Sapendo che ogni numero (word) occupa 32 bit (4 byte), legge il 2° numero. R2 = 12 ('b')
    LDR R4, [R3, #8]    @ Legge all'indirizzo R3 + 8 byte (salta 2 numeri). Legge il 3° numero. R4 = 8 ('c')
    LDR R5, [R3, #12]   @ Legge all'indirizzo R3 + 12 byte (salta 3 numeri). Legge il 4° numero. R5 = 4 ('d')
    LDR R6, =result     @ Carica in R6 l'INDIRIZZO di memoria dell'etichetta 'result', dove salveremo la risposta

    @ --- FASE 2: ELABORAZIONE DEI DATI (Data Processing) ---
    @ Obiettivo matematico dell'algoritmo: Risultato = (((a + b) - c) * d) / 4

    ADD R0, R1, R2      @ R0 = R1 + R2 => R0 = 20 + 12 = 32. (Calcoliamo a + b)
    SUB R0, R0, R4      @ R0 = R0 - R4 => R0 = 32 - 8 = 24.  (Calcoliamo (a + b) - c)
    
    @ Moltiplicazione standard a 32 bit 
    MUL R0, R0, R5      @ R0 = R0 * R5 => R0 = 24 * 4 = 96.  (Calcoliamo ((a + b) - c) * d)
    
    @ Divisione ottimizzata tramite Shift Logico a Destra (LSR)
    @ Traslare i bit a destra di N posizioni equivale a dividere il numero per 2^N.
    @ LSR di #2 equivale a dividere per 2^2, ovvero dividere per 4.
    LSR R0, R0, #2      @ R0 = R0 >> 2 => R0 = 96 / 4 = 24.  (Calcoliamo la divisione finale. Nota: 96/4 fa 24 col resto scartato)

    @ --- FASE 3: SALVATAGGIO DEL RISULTATO (Store) ---
    STR R0, [R6]        @ Prende il valore contenuto in R0 (24) e lo scrive nella memoria all'indirizzo puntato da R6 ('result')

    @ --- FASE 4: TERMINE DEL PROGRAMMA ---
stop:                   @ Etichetta per definire un loop infinito
    B stop              @ Branch (salto) incondizionato all'etichetta 'stop'. Impedisce alla CPU di proseguire leggendo memoria "spazzatura"

    @ --- SEZIONE DATI: Variabili in RAM ---
    .data               @ Direttiva che indica all'assembler che qui iniziano i dati (non il codice eseguibile)
numbers:                @ Etichetta che definisce l'inizio dell'array di numeri
    .word 20, 12, 8, 4  @ Direttiva .word: alloca 4 numeri a 32 bit (4 byte ciascuno) in sequenza in memoria
result:                 @ Etichetta per la nostra variabile di output
    .word 0             @ Alloca uno spazio a 32 bit inizializzato a 0, pronto per essere sovrascritto dalla STR
