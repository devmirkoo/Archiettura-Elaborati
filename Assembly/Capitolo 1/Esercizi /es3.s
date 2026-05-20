.global _start
_start:

; Assumiamo X=R0, A=R1, B=R2, C=R3
ADD R4, R1, R2   ; R4 (t1) = A + B
ADD R5, R3, #5   ; R5 (t2) = C + 5
SUB R0, R4, R5   ; X = t1 - t2
