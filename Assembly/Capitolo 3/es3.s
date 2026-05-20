global _start
_start:
    LDR R1, =number    @ Carica l'indirizzo della variabile number
    LDR R0, [R1]       @ Carica il valore di number (valore: 2) in R0
    LDR R2, =result    @ Carica l'indirizzo dove salvare il risultato

    BL raddoppia       @ Chiama la subroutine e salva l'indirizzo di ritorno in LR
    
    STR R0, [R2]       @ Salva il valore raddoppiato in memoria

stop:
    B stop             @ Termina l'esecuzione. Agisce da "muro": il codice sotto non verrà eseguito per caso.

@ --- SUBROUTINES ---
@ Posizionare le funzioni qui sotto è l'opzione migliore perché:
@ 1. Evita il "fall-through" (il processore non ci cade dentro per errore).
@ 2. Rende il codice più modulare e leggibile.
raddoppia:
    LSL R0, R0, #1     @ Moltiplica R0 per 2 usando lo shift logico a sinistra
    BX LR              @ Ritorna all'istruzione successiva alla BL usando il Link Register
.data
    number:
        .word 2

    result:
        .word 0