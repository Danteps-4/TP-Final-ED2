;-------------------------------
; CONFIGURACIÓN
;-------------------------------
    LIST P=16F887
    #include "p16f887.inc"

    __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_ON & _MCLRE_ON & _LVP_OFF

;-------------------------------
; VARIABLES
;-------------------------------
SALVAW EQU 0x70
SALVAS EQU 0x71

;-------------------------------
; PROGRAMA PRINCIPAL
;-------------------------------
    ORG 0x00
    GOTO INICIO
    ORG 0x04
    GOTO ISR
    ORG 0x05

INICIO
    BSF STATUS,RP0
    CLRWDT
    
    MOVLW b'11010000'
    ANDWF OPTION_REG,W
    IORLW b'00000001'
    MOVWF OPTION_REG
    BCF STATUS,RP0
    MOVLW b'11110000'
    MOVWF TMR0
    
    BCF INTCON,T0IF
    BSF INTCON,T0IE
    BSF INTCON,GIE
    
LOOP
    NOP
    NOP
    NOP
    CLRWDT
    NOP
    GOTO LOOP

ISR
    MOVWF SALVAW
    SWAPF STATUS,W
    MOVWF SALVAS
    
    BTFSC INTCON,T0IF
    GOTO INT_TMR0
    
    SWAPF SALVAS,W
    MOVWF STATUS
    SWAPF SALVAW,F
    SWAPF SALVAW,W
    
    RETFIE
    
INT_TMR0
    MOVLW b'11110000'
    MOVWF TMR0
    
    BCF INTCON,T0IF
    
    RETURN
    
    END