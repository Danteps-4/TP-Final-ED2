;-------------------------------
; CONFIGURACIÓN
;-------------------------------
    LIST P=16F887
    #include "p16f887.inc"

    __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
    __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

VALOR EQU 0x21
COUNT1 EQU 0x22
COUNT2 EQU 0x23
    
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
    ; Configure RCSTA - SPEN=1 (enable serial port)
    BANKSEL RCSTA
    MOVLW b'10000000'
    MOVWF RCSTA
    
    MOVLW b'01000001'
    MOVWF VALOR		;Se carga VALOR con el char "1" en ASCII
    
MAIN
    BANKSEL TXREG
    MOVF VALOR,W
    MOVWF TXREG		;Se carga el TXREG con el valor a transmitir
    
L1
    BANKSEL PIR1
    BTFSS PIR1,TXIF	;Se chequea la bandera de que se lleno el TXREG
    GOTO L1		;Todavia no se envio
    BCF STATUS,RP0	;Ya se envio
    GOTO MAIN
    
    END
    
    
