;-------------------------------
; CONFIGURACI?N
;-------------------------------
    LIST P=16F887
    #include "p16f887.inc"

    __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
    __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

;-------------------------------
; VARIABLES
;-------------------------------
DIGI1 EQU 0x20
DIGI2 EQU 0x21
R1 EQU 0x30
R2 EQU 0x31


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
    CLRF TRISD
    BANKSEL PORTE
    CLRF PORTB
    BANKSEL ANSEL
    CLRF ANSEL
    BANKSEL TRISE
    CLRF TRISE
    
    BANKSEL DIGI1
    MOVLW d'2'
    MOVWF DIGI1
    MOVLW d'4'
    MOVWF DIGI2
    
TODOS_DIG
    MOVLW DIGI1
    MOVWF FSR
    MOVLW b'00000001'
    BANKSEL PORTE
    MOVWF PORTE
OTRO_DIG
    MOVF INDF,W
    CALL DISPLAY_7SEGMENTOS
    BANKSEL PORTD
    MOVWF PORTD
    CALL RETARDO_10MS
    BCF STATUS,C
    BANKSEL PORTE
    RLF PORTE,F
    INCF FSR,F
    BTFSS PORTE,2
    GOTO OTRO_DIG
    GOTO TODOS_DIG
    

RETARDO_10MS
    MOVLW   d'255'
    MOVWF   R1         ; R1 = ciclo interior
OUTER_LOOP
    MOVLW   d'4'
    MOVWF   R2         ; R2 = ciclo exterior
INNER_LOOP
    NOP                ; 1 ciclo
    NOP
    NOP
    NOP
    NOP
    NOP
    DECFSZ  R2,F       ; 1 ciclo si no es cero, 2 si es cero
    GOTO    INNER_LOOP ; 2 ciclos
    DECFSZ  R1,F
    GOTO    OUTER_LOOP
    RETURN

DISPLAY_7SEGMENTOS
    ADDWF PCL,F
    RETLW b'10111111'	;0
    RETLW b'10000110'	;1
    RETLW b'11011011'	;2
    RETLW b'11001111'	;3
    RETLW b'11100110'	;4
    RETLW b'11101101'	;5
    RETLW b'11111101'	;6
    RETLW b'10000111'	;7
    RETLW b'11111111'	;8
    RETLW b'11100111'	;9
 
    END