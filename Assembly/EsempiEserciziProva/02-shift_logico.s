.global _start          @ Punto di ingresso del programma

_start:
    @ --- FASE 1: INIZIALIZZAZIONE E CARICAMENTO (Load) ---
    LDR R3, =number     @ R3 = indirizzo della variabile 'number' in memoria
    LDR R1, [R3]        @ R1 = valore di 'number' (25, che in base 2 è 0...00011001)
    LDR R4, =result     @ R4 = indirizzo della variabile 'result', dove memorizzeremo l'output finale
    
    MOV R2, R1          @ Copia R1 in R2. Ora sia R1 che R2 contengono il valore 25.
                        @ Questo passaggio ci serve perché l'esercizio richiede di applicare
                        @ due operazioni diverse (shift sx e shift dx) sullo stesso numero di partenza.

    @ --- FASE 2: OPERAZIONI DI SHIFT (Scorrimento logico) ---
    
    @ 1. Shift logico a sinistra di 4 posizioni
    @ Matematicamente equivale a moltiplicare per 2^4 (16). Quindi 25 * 16 = 400 (In esa: 0x190)
    @ A livello bit: uno spostamento (0000 0001 1001) << 4 diventa (0001 1001 0000)
    LSL R1, R1, #4      @ R1 = R1 << 4
    
    @ 2. Shift logico a destra di 3 posizioni
    @ Matematicamente equivale a dividere per 2^3 (8). Quindi 25 / 8 = 3.
    @ A livello bit: uno spostamento (0001 1001) >> 3 diventa (0000 0011)
    LSR R2, R2, #3      @ R2 = R2 >> 3

    @ --- FASE 3: OPERAZIONI LOGICHE BIT A BIT (Bitwise) ---
    
    @ 3. OR logico tra i due risultati (Combina i bit impostati a '1')
    @ R1 = 0x190 (b'0001 1001 0000)
    @ R2 = 0x003 (b'0000 0000 0011)
    @ OR = 0x193 (b'0001 1001 0011). Mantiene gli 1 presi da entrambi i registri. (Decimale 403)
    ORR R0, R1, R2      @ R0 = R1 | R2

    @ 4. AND logico del valore ottenuto con la maschera 0xFF (Mascheramento)
    @ L'istruzione AND con 0xFF (che è 11111111 in binario) serve ad "estrarre"
    @ o mantenere validi solo gli ultimi 8 bit (il byte meno significativo) e ad azzerare il resto.
    @ Valore in R0: 0001 1001 0011 (0x193)
    @ Maschera:     0000 1111 1111 (0x0FF)
    @ AND (Ris.):   0000 1001 0011 (0x093 = 147 in decimale)
    AND R0, R0, #0xFF   @ R0 = R0 & 0xFF

    @ --- FASE 4: SALVATAGGIO (Store) ---
    STR R0, [R4]        @ Salva il risultato finale calcolato (147, ovvero 0x093) in RAM all'indirizzo 'result'

stop:
    B stop              @ Loop infinito per evitare che la CPU continui a leggere memoria ineseguibile

@ --- AREA DATI ---
.data
number:
    .word 25            @ Variabile di ingresso (decimale 25)
result:
    .word 0             @ Variabile di uscita, inizializzata a 0. Verrà sovrascritta con il risultato finale.
