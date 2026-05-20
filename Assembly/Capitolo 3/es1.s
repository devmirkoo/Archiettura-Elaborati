global _start
_start:
    LDR R3, =number    @ Carica l'indirizzo base dei dati in R3
    LDR R1, [R3]       @ Legge il primo numero (1) in R1
    LDR R2, [R3, #4]   @ Legge il secondo numero (2) in R2
    LDR R4, =result    @ Carica l'indirizzo dove salvare il risultato in R4


    CMP R1, R2         @ Confronta R1 e R2
    BLT else_block     @ Se R1 < R2, salta al blocco alternativo

    MOV R0, #10        @ Blocco IF: eseguito se R1 >= R2
    B end_if           @ Salta alla fine per ignorare l'else
    
    else_block:
        MOV R0, #20     @ Blocco ELSE: eseguito se R1 < R2

    end_if:
        STR R0, [R4]   @ Salva il valore finale di R0 nella memoria (result)

stop:
    B stop             @ Ciclo infinito per terminare l'esecuzione safely

.data
    number: 
        .word 1, 2
    result:
        .word 0
