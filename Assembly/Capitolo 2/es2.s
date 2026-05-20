.global _start         
_start:                 
    @ --- FASE 1: CARICAMENTO ---
    LDR R1, =number
    LDR R2, [R1]
    LDR R4, =result     @ RISOLTO: Uso R4 per l'indirizzo, così non sovrascrivo R6
    
    @ --- FASE 2: ISOLAMENTO BIT DI SEGNO ---
    @ LSR di 31 posizioni spinge il bit più a sinistra (MSB) nella posizione 0.
    @ Tutti gli altri bit a sinistra vengono riempiti con 0.
    LSR R6, R2, #31     @ R6 conterrà 0 (positivo) o 1 (negativo)

    @ --- FASE 3: SALVATAGGIO ---
    @ RISOLTO: Uso R4 (che punta a 'result') come destinazione, salvando il valore di R6.
    STR R6, [R4]        @ Salva il bit estratto in memoria

stop:
    B stop              

    @ --- SEZIONE DATI ---
.data
number:
    .word -32           @ Testiamo con un numero negativo (bit 31 = 1)
                        
result:
    .word 0             @ Conterrà 1 se il numero è negativo, 0 se positivo
