.global _start
_start:
    @ --- Inizializzazione ---
    LDR R1, =vect_numeri    @ Carica l'indirizzo base del vettore in R1
    MOV R2, #6              @ Numero di elementi da analizzare (Contatore)
    MOV R3, =result         @ Carica l'indirizzo dove salveremo il risultato finale
    MOV R0, #0              @ R0 fungerà da accumulatore per la somma (inizializzato a 0)

loop_vect:
    @ --- Caricamento e Avanzamento ---
    @ LDR con post-incremento: legge il valore e sposta subito il puntatore di 4 byte
    LDR R4, [R1], #4        
    
    @ --- Controllo Condizionale ---
    CMP R4, #0              @ Confronta il numero estratto con lo zero
    
    @ DIFFICOLTÀ RISCONTRATA: Posizionamento dell'etichetta di salto.
    @ Invece di saltare a una funzione esterna, usiamo BLE (Branch if Less or Equal)
    @ per "scavalcare" l'istruzione di somma solo se il numero NON è positivo.
    BLE salta_somma         
    
    ADD R0, R0, R4          @ Se arriviamo qui, il numero è > 0: lo aggiungiamo alla somma

salta_somma:
    @ CULMINE DEL CICLO: L'etichetta deve stare QUI. 
    @ Se l'avessimo messa dopo il BNE, avremmo creato un loop infinito per i numeri negativi.
    @ Posta qui, garantisce che SUBS e BNE vengano eseguiti per OGNI elemento.
    SUBS R2, R2, #1         @ Decrementa il contatore e aggiorna le flag di stato
    BNE loop_vect           @ Se R2 non è ancora zero, continua con il prossimo elemento
    
    @ --- Conclusione ---
    STR R0, [R3]            @ Salva il totale accumulato in R0 nella memoria (result)

stop:
    B stop                  @ Ciclo infinito per fermare l'esecuzione

.data
    vect_numeri:
        .word 4, -2, 7, 0, -5, 10
    
    result:
        .word 0