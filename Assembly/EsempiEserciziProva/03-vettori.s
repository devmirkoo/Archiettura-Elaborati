.global _start          @ Punto di ingresso del programma

_start:
    @ --- FASE 1: INIZIALIZZAZIONE REGISTRI ED INDIRIZZI ---
    LDR R3, =vect       @ R3 = indirizzo base del array/vettore 'vect' in memoria
    LDR R7, =result     @ R7 = indirizzo della variabile 'result' per l'output finale
    
    MOV R2, #0          @ R2 = Offset di memoria in byte. Partiamo da 0. Servirà per scorrere i byte.
    MOV R4, #0          @ R4 = Indice logico del vettore (i). Da 0 a 11 (poiché sono 12 elementi).
    MOV R5, #0          @ R5 = Accumulatore per le somme degli elementi in posizione PARI (0, 2, 4...).
    MOV R6, #0          @ R6 = Accumulatore per le somme degli elementi in posizione DISPARI (1, 3, 5...).
    MOV R12, #12        @ R12 = Costante per la terminazione del ciclo (12 elementi totali).

@ --- FASE 2: CICLO DI LETTURA E SOMMA (Loop) ---
loop:
    LDR R1, [R3, R2]    @ Carica in R1 il valore del vettore all'indirizzo base R3 + l'offset R2.
    
    @ Verifica della parità dell'indice logico 'i' in R4:
    @ In binario, un numero è dispari se il suo bit meno significativo (LSB) è 1.
    @ Eseguiamo un AND bit a bit tra l'indice e 1 (ossia la maschera 0x01).
    AND R0, R4, #1      @ Se l'indice (R4) è pari, R0 = 0. Se dispari, R0 = 1.
    CMP R0, #0          @ Confronto il risultato dell'AND con 0. Aggiorna lo stato (Z flag).
    
    @ Sfruttiamo i suffissi condizionali di ARM per evitare di fare due salti (branch) distinti:
    @ ADDEQ (Add if Equal) si esegue solo se Z=1 (R0 == 0 -> indice pari)
    ADDEQ R5, R5, R1    @ R5 = R5 + elemento letto. Aggiunge alla somma dei pari.
    
    @ ADDNE (Add if Not Equal) si esegue solo se Z=0 (R0 != 0 -> indice dispari)
    ADDNE R6, R6, R1    @ R6 = R6 + elemento letto. Aggiunge alla somma dei dispari.
    
    @ --- Avanzamento nei registri ---
    ADD R2, R2, #4      @ Incremento dell'offset di memoria di 4 byte (una parola a 32 bit).
    ADD R4, R4, #1      @ Incremento dell'indice logico del ciclo 'i'.
    
    @ --- Controllo di fine iterazione ---
    CMP R4, R12         @ Confronta l'indice attuale (R4) con 12 (il numero di elementi).
    BNE loop            @ Branch if Not Equal:  Se R4 != 12, salta all'etichetta 'loop' (itera di nuovo).

    @ --- FASE 3: CALCOLO DIFFERENZA E SALVATAGGIO ---
    SUB R0, R5, R6      @ Differenza = Somma_Pari (R5) - Somma_Dispari (R6)
    STR R0, [R7]        @ Salva il risultato nella variabile puntata da R7 ('result')

stop:
    B stop              @ Termina l'esecuzione per evitare bug di lettura.

@ --- AREA DATI ---
.data
vect:                   @ Vettore di TEST, riempito con 12 elementi contigui a 32 bit.
    .word 5, 2, 8, 3, 10, 4, 12, 1, 6, 7, 0, 9
result:
    .word 0             @ Spazio in cui memorizzare il risultato finale
