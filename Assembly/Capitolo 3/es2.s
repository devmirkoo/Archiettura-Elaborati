global _start
_start:
    @ --- NOTA PER IL FUTURO (ERRORI FIXATI) ---
    @ 1. Usare ADD (l'istruzione SUM non esiste).
    @ 2. Inizializzare sempre l'accumulatore (MOV R0, #0).
    @ 3. Sommare il registro contatore (R2), non l'indirizzo (R1).
    @ ------------------------------------------

    LDR R1, =number   @ Carica l'indirizzo della variabile 'number'
    LDR R2, [R1]      @ Carica il valore 5 nel registro R2 (contatore)
    LDR R3, =result   @ Carica l'indirizzo per il salvataggio finale
    
    MOV R0, #0        @ Inizializza l'accumulatore (evita valori casuali)
    
    loop_for:
        ADD R0, R0, R2  @ Somma il contatore all'accumulatore (R0 = R0 + R2)

        SUBS R2, R2, #1 @ Decrementa R2 e aggiorna i Flag (S)
        BNE loop_for    @ Continua finché R2 non è zero

    STR R0, [R3]     @ Salva il risultato finale (15) in memoria     


stop:
    B stop

.data
    number:
        .word 5
    result:
        .word 0