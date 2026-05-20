.global _start          @ Punto di ingresso del programma

_start:
    @ --- FASE 1: INIZIALIZZAZIONE ---
    LDR R1, =string     @ R1 = indirizzo base della stringa in memoria
    LDR R7, =result     @ R7 = indirizzo della variabile 'result' per l'output finale
    
    MOV R2, #0          @ R2 = Offset/Indice per scorrere i caratteri della stringa (i = 0)
    MOV R3, #0          @ R3 = Contatore per le lettere MINUSCOLE
    MOV R4, #0          @ R4 = Contatore per le cifre NUMERICHE

@ --- FASE 2: CICLO DI LETTURA E CONTROLLO ---
loop:
    @ LDRB (Load Register Byte): Carica un singolo byte (1 carattere ASCII) dalla memoria.
    LDRB R0, [R1, R2]   @ R0 = Carattere corrente (string[R2])
    
    @ Controllo del terminatore di stringa (Null character '\0' o valore ASCII 0)
    CMP R0, #0          @ Il carattere è nullo?
    BEQ end_loop        @ Branch if Equal: se è nullo, la stringa è finita, salta a end_loop

    @ --- CONTROLLO LETTERE MINUSCOLE (Range ASCII 'a'-'z' ovvero 97-122) ---
    CMP R0, #'a'        @ Confronta il carattere con 'a'
    BLT check_digit     @ Branch if Less Than: se è minore di 'a', non è minuscola, controlla se è un numero
    CMP R0, #'z'        @ Confronta il carattere con 'z'
    BGT check_digit     @ Branch if Greater Than: se è maggiore di 'z', non è minuscola, controlla se è un numero
    
    @ Se arriviamo qui, il carattere è compreso tra 'a' e 'z'
    ADD R3, R3, #1      @ Incrementa il contatore delle lettere minuscole
    B next_char         @ Salta direttamente al prossimo carattere (non può essere anche un numero)

@ --- CONTROLLO CIFRE NUMERICHE (Range ASCII '0'-'9' ovvero 48-57) ---
check_digit:
    CMP R0, #'0'        @ Confronta il carattere con '0'
    BLT next_char       @ Branch if Less Than: se minore, non è un numero, passa al prossimo carattere
    CMP R0, #'9'        @ Confronta il carattere con '9'
    BGT next_char       @ Branch if Greater Than: se maggiore, non è un numero, passa al prossimo carattere
    
    @ Se arriviamo qui, il carattere è compreso tra '0' e '9'
    ADD R4, R4, #1      @ Incrementa il contatore delle cifre numeriche

@ --- FASE 3: AVANZAMENTO ITERAZIONE ---
next_char:
    ADD R2, R2, #1      @ Incrementa l'indice della stringa di 1 (spostamento di 1 byte al carattere successivo)
    B loop              @ Torna all'inizio del ciclo per leggere il nuovo carattere

@ --- FASE 4: CALCOLO FINALE E SALVATAGGIO ---
end_loop:
    SUB R0, R3, R4      @ R0 = Numero lettere minuscole (R3) - Numero cifre (R4)
    STR R0, [R7]        @ Salva il risultato nella variabile 'result'

stop:
    B stop              @ Ciclo infinito di terminazione sicura

@ --- AREA DATI ---
.data
result:
    .word 0             @ Spazio in cui memorizzare il risultato finale (differenza)

string:
    .asciz "Arm v7 test 2026"  @ Direttiva .asciz: inserisce la stringa in memoria terminandola automaticamente col byte nullo (\0)
