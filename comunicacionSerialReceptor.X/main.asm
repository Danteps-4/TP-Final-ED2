;-------------------------------
; CONFIGURACIÓN
;-------------------------------
    LIST P=16F887
    #include "p16f887.inc"

    __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
    __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
    
    ORG 0x00
    GOTO INICIO
    ORG 0x05
    
INICIO
    ; Configure SPBRG for desired baud rate
    BANKSEL SPBRG
    MOVLW d'25'
    MOVWF SPBRG
    ; Configure TXSTA - TXEN=1 (transmision activada) , SYNC=1 (asincrono) , BRGH=1 (high transmision baud rate)
    BANKSEL TXSTA
    MOVLW b'00100100'
    MOVWF TXSTA
    ; Configure RCSTA - SPEN=1 (enable serial port) , CREN=1 (enable receiver)
    BANKSEL RCSTA
    MOVLW b'10010000'
    MOVWF RCSTA
    
    BANKSEL TRISB
    CLRF TRISB
    BANKSEL PORTB
    CLRF PORTB
    
MAIN
    BANKSEL PIR1
    BTFSS PIR1,RCIF	    ;Se chequea si llego la informacion completa
    GOTO MAIN	
    BANKSEL RCREG
    MOVF RCREG,W	    ;Se muestra la informacion por el PORTB
    MOVWF PORTB
    GOTO MAIN
    
    END
    

