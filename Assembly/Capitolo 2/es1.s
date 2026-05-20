.global _start          @ Rende l'etichetta _start visibile al linker
_start:                 @ Etichetta di inizio corretta (deve corrispondere a .global)

    @ --- FASE 1: CARICAMENTO ---
    LDR R7, =number     @ Carica l'indirizzo della variabile 'number' in R7
    LDR R1, [R7]        @ Carica il valore contenuto in 'number' (1) nel registro R1
    LDR R4, =result     @ Carica l'indirizzo della variabile 'result' in R4 (usiamo R4 come puntatore)

    @ --- FASE 2: ELABORAZIONE (Moltiplicazione rapida) ---
    @ La traccia richiedeva di salvare il risultato in R5.
    @ LSL #5 sposta i bit a sinistra di 5 posizioni, che equivale a moltiplicare per 2^5 = 32.
    LSL R5, R1, #5      @ R5 = R1 * 32. (Se R1 era 1, ora R5 contiene 32)

    @ --- FASE 3: SALVATAGGIO ---
    STR R5, [R4]        @ Salva il contenuto di R5 nell'indirizzo di memoria puntato da R4 (result)

stop:
    B stop              @ Loop infinito di sicurezza

    @ --- SEZIONE DATI ---
.data
number:
    .word 1             @ CORREZIONE: Aggiunto il punto (.) davanti a word. 
                        @ In ARM Assembly le direttive iniziano sempre col punto.
result:
    .word 0             @ CORREZIONE: .word alloca una parola a 32 bit inizializzata a 0
