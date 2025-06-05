# 1 "main2.asm"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 286 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "main2.asm" 2
;-------------------------------
; CONFIGURACIÓN
;-------------------------------
    LIST P=16F887
    #INCLUDE "p16f887.inc"

    __CONFIG 0x2FF4
    __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

;-------------------------------
; VARIABLES
;-------------------------------
CONTADOR1 EQU 0x20
CONTADOR2 EQU 0x21

;-------------------------------
; PROGRAMA PRINCIPAL
;-------------------------------
    ORG 0x00
    GOTO INICIO

    ORG 0x05

INICIO
    CLRF TRISB ; PORTB como salida
    CLRF PORTB ; Limpiar PORTB

LOOP
    BSF PORTB,0
    CALL DELAY

    BCF PORTB,0
    CALL DELAY

    GOTO LOOP

;-------------------------------
; SUBRUTINA DE RETARDO
;-------------------------------
DELAY
    MOVLW 250
    MOVWF CONTADOR1
RETARDO1
    MOVLW 250
    MOVWF CONTADOR2
RETARDO2
    NOP
    NOP
    DECFSZ CONTADOR2, F
    GOTO RETARDO2
    DECFSZ CONTADOR1, F
    GOTO RETARDO1
    RETURN

    END
