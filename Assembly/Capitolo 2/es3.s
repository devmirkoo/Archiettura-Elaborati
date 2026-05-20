.global _start         
_start:                 
    @ --- FASE 1: CARICAMENTO DATI ---
    LDR R0, =number     @ R0 = Indirizzo base dei numeri
    LDR R5, [R0]        @ R5 = Primo numero (-256)
    LDR R6, [R0, #4]    @ R6 = Secondo numero (128)
    
    LDR R4, =result     @ R4 = Indirizzo base dove salvare il risultato a 64 bit

    @ --- FASE 2: MOLTIPLICAZIONE A 64 BIT (CON SEGNO) ---
    @ SMULL (Signed Multiply Long)
    @ R8 = Parte bassa (32 bit meno significativi)
    @ R9 = Parte alta (32 bit più significativi - bit di segno)
    SMULL R8, R9, R5, R6

    @ --- FASE 3: SALVATAGGIO RISULTATO (64 bit in memoria) ---
    @ Il risultato a 64 bit occupa due "word" (8 byte totali).
    STR R8, [R4]        @ Salva la parte bassa all'indirizzo R4 (offset 0)
    STR R9, [R4, #4]    @ Salva la parte alta all'indirizzo R4 + 4 byte

stop:
    B stop              

    @ --- SEZIONE DATI ---
.data
number:
    .word -256, 128     @ Due numeri a 32 bit con segno
                        
result:
    .word 0, 0          @ Spazio per 64 bit (due word da 32 bit ciascuna)
