# Esercitazione Assembly ARM (Seconda Prova in Itinere)

## Esercizio #1 – Data Processing
Scrivere un programma Assembly ARM che legga dalla memoria quattro numeri interi positivi `a`, `b`, `c` e `d`. A partire da una label dichiarata mediante direttiva `.global`, il programma dovrà:
- calcolare `(a + b)`;
- sottrarre `c` dal risultato ottenuto;
- moltiplicare il risultato per `d`;
- dividere infine il valore ottenuto per 4 utilizzando esclusivamente istruzioni di shift.

Il risultato finale dovrà essere salvato in memoria.

---

## Esercizio #2 – Shift Logico
Scrivere un programma Assembly ARM che esegua:
- shift logico a sinistra di 4 posizioni;
- shift logico a destra di 3 posizioni;
- OR logico tra i due risultati;
- AND logico del valore ottenuto con la maschera `0xFF`.

Il risultato finale dovrà essere salvato in memoria.

---

## Esercizio #3 – Vettori
Scrivere un programma Assembly ARM che, dato un vettore `V` di 12 elementi:
- calcoli la somma degli elementi di indice pari;
- calcoli la somma degli elementi di indice dispari;
- determini la differenza tra le due somme.

Il risultato finale dovrà essere salvato in memoria.

---

## Esercizio #4 – Stringhe
Scrivere un programma Assembly ARM che, data una stringa terminata dal carattere nullo:
- conti il numero di lettere minuscole;
- conti il numero di cifre numeriche.

La differenza tra i due valori dovrà essere salvata in memoria.

---

## Esercizio #5 – Subroutine senza uso dello stack
Implementare una subroutine `minmax` che riceva tre interi nei registri `r0`, `r1` e `r2`. La subroutine dovrà:
- restituire in `r0` il valore minimo;
- restituire in `r1` il valore massimo.

Il programma principale dovrà salvare i risultati in memoria. Non utilizzare lo stack.

---

## Esercizio #6 – Subroutine con uso dello stack
Scrivere una procedura `transform` che riceva:
- in `r0` l’indirizzo base di un vettore;
- in `r1` il numero di elementi;
- in `r2` un valore `k`.

La procedura dovrà moltiplicare per `k` gli elementi pari del vettore e contare quanti elementi sono stati modificati. Il numero di elementi modificati dovrà essere restituito in `r0` e poi salvato in memoria. Si utilizzi, se necessario, lo stack.
