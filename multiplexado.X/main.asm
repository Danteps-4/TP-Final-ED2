;-------------------------------
; CONFIGURACIÓN
;-------------------------------
    LIST P=16F887
    #include "p16f887.inc"

    __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
    __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

;-------------------------------
; VARIABLES
;-------------------------------
CONT1 EQU 0x20
CONT2 EQU 0x21
 
;-------------------------------
; PROGRAMA PRINCIPAL
;-------------------------------
    ORG 0x00
    GOTO INICIO
    ORG 0x05

INICIO
    BANKSEL PORTD
    CLRF PORTD
    BANKSEL TRISD
    CLRF TRISD		    ; Seteo PORTD todo como salidas para el display
    BANKSEL PORTE
    CLRF PORTE
    BANKSEL ANSEL
    CLRF ANSEL
    BANKSEL TRISE
    CLRF TRISE		    ; Seteo PORTE todo como salidas para el multiplexado
    
LOOP
    BANKSEL PORTD
    MOVLW b'11111111'
    MOVWF PORTD
    BANKSEL PORTE
    BSF PORTE,0		    ; Habilito el display
    GOTO LOOP

    END

