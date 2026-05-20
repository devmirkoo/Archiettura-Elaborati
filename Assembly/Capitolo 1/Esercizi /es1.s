.global _start
_start:

	
; Assumiamo x=R0, y=R1, z=R2
SUB R0, R1, R2   ; x = y - z
ADD R1, R0, R1   ; y = x + y 