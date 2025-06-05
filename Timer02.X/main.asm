;-------------------------------
; CONFIGURACIÓN
;-------------------------------
    LIST P=16F887
    #include "p16f887.inc"

    __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _MCLRE_ON & _LVP_OFF

;-------------------------------
; VARIABLES
;-------------------------------
SALVAW EQU 0x20
SALVAS EQU 0x21
CONT1 EQU 0x22
FLAG EQU 0x23

;-------------------------------
; PROGRAMA PRINCIPAL
;-------------------------------
    ORG 0x00
    GOTO INICIO
    ORG 0x04
    GOTO ISR
    ORG 0x05

INICIO
    BANKSEL ANSEL
    CLRF ANSEL
    MOVLW b'11010001'
    MOVWF OPTION_REG
    BANKSEL TRISA
    CLRF TRISA
    BCF STATUS,RP0
    MOVLW 0x64
    MOVWF TMR0
    
    BCF INTCON,T0IF
    BSF INTCON,T0IE
    BSF INTCON,GIE
    
    MOVLW D'5'
    MOVWF CONT1
    CLRF PORTA
    GOTO $
    
ISR
    MOVWF SALVAW
    SWAPF STATUS,W
    MOVWF SALVAS
    
    BTFSC INTCON,T0IF
    GOTO INT_TMR0
    GOTO FIN_INT

INT_TMR0
    MOVLW 0x64
    MOVWF TMR0
    DECFSZ CONT1,F
    GOTO L1
    MOVLW D'5'
    MOVWF CONT1
    INCF FLAG,F
    BTFSS FLAG,0
    BCF PORTA,0
    BTFSC FLAG,0
    BSF PORTA,0
    
L1
    BCF INTCON,T0IF

FIN_INT
    SWAPF SALVAS,W
    MOVWF STATUS
    SWAPF SALVAW,F
    SWAPF SALVAW,W
    
    RETFIE
    
    END


