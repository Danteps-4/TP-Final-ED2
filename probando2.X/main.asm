;-------------------------------
; CONFIGURACI�N
;-------------------------------
    LIST P=16F887
    #include "p16f887.inc"

    __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
    __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

;-------------------------------
; VARIABLES
;-------------------------------
NUMTECLA EQU 0x20
FILETEST EQU 0x21
SALVAW EQU 0x23
SALVAS EQU 0x24
ACTIVADA EQU 0x25

;-------------------------------
; PROGRAMA PRINCIPAL
;-------------------------------
    ORG 0x00
    GOTO INICIO
    ORG 0x04
    GOTO ISR
    ORG 0x05

INICIO
    BANKSEL OPTION_REG
    MOVLW b'01110111'	;Prescaler 256
    MOVWF OPTION_REG
    
    BANKSEL PORTB   
    CLRF PORTB		;Limpio PORTB
    BANKSEL ANSELH
    CLRF ANSELH		;Limpio ANSELH para I/O digitales
    BANKSEL TRISB
    MOVLW b'11110000'
    MOVWF TRISB		;Habilito RB4-RB7 como entradas y RB0-RB3 como salidas
    BANKSEL PORTC
    MOVLW b'10000000'
    MOVWF PORTC		;Activo el display
    BANKSEL TRISC
    CLRF TRISC		;Seteo todo el PORTC como salidas para usar como display
    BANKSEL PORTA
    CLRF PORTA
    BANKSEL ANSEL
    CLRF ANSEL		;Limpio ANSEL para I/O digitales
    BANKSEL TRISA
    CLRF TRISA		;Habilito el PORTA todo como salidas (para poner el led que indica que la alarma esta activada y el buzzer)
   
    
    BANKSEL INTCON
    BSF INTCON,GIE	;seteo GIE -> interrupciones globales
    BSF INTCON,T0IE	;seteo T0IE -> interrupciones por TIMER0
    BCF INTCON,T0IF	;limpio TOIF -> banderae de interrupcion por TIMER0
    BSF INTCON,PEIE	;seteo PEIE -> interrupciones por perifericos
    BSF INTCON,RBIE	;seteo RBIE -> interrupciones por RB4-RB7
    BCF INTCON,RBIF	;limpio RBIF -> bandera de interrupcion por RB4-RB7
    BCF INTCON,INTF
    
    BANKSEL IOCB
    MOVLW b'11110000'
    MOVWF IOCB		;Seteo que se pueda interrumpir por RB4-RB7
    
LOOP
    NOP
    NOP
    NOP
    GOTO LOOP

TABLA
    ADDWF PCL,F
    RETLW b'10000110'	;1
    RETLW b'10100111'	;4
    RETLW b'10000111'	;7
    RETLW b'11100011'	;*
    
    RETLW b'11011011'	;2
    RETLW b'11101101'	;5
    RETLW b'11111111'	;8
    RETLW b'10111111'	;0
    
    RETLW b'11001111'	;3
    RETLW b'11111101'	;6
    RETLW b'11100111'	;9
    RETLW b'11110110'	;#

ISR 
    MOVWF SALVAW
    SWAPF STATUS,W
    MOVWF SALVAS
    
    BTFSC INTCON,T0IF
    CALL INT_TMR0
    
    BTFSC INTCON,RBIF
    CALL INT_TECLADO
    
    SWAPF SALVAS,W
    MOVWF STATUS
    SWAPF SALVAW,F
    SWAPF SALVAW,W
    
    RETFIE

INT_TMR0
    BCF INTCON,T0IF
    RETURN

RETARDO10MS    
    BANKSEL TMR0
    MOVLW D'216'    ;Precarga de 216 para que el retardo dure 10ms
    MOVWF TMR0
ESPERA
    BANKSEL INTCON
    BTFSS INTCON,T0IF
    GOTO ESPERA
    RETURN    

INT_TECLADO
    CALL RETARDO10MS
    
    CLRF NUMTECLA
    MOVLW b'00000110'
    MOVWF FILETEST
OTRATECLA
    BANKSEL PORTB
    MOVF FILETEST,W
    MOVWF PORTB
    
    BTFSS PORTB,RB4
    GOTO BUSCATECLA
    INCF NUMTECLA,F
    
    BTFSS PORTB,RB5
    GOTO BUSCATECLA
    INCF NUMTECLA,F
    
    BTFSS PORTB,RB6
    GOTO BUSCATECLA
    INCF NUMTECLA,F
    
    BTFSS PORTB,RB7
    GOTO BUSCATECLA
    INCF NUMTECLA,F
    
    BSF STATUS,C
    RLF FILETEST,F
    MOVLW 0xC
    SUBWF NUMTECLA,W
    BTFSC STATUS,Z
    GOTO DONE_TECLADO_INT   ;Lleg� a 12, salgo
    GOTO OTRATECLA	    ;NO lleg� a 12, busca proxima fila
  
BUSCATECLA
    CALL RETARDO10MS
    
    MOVF NUMTECLA,W
    CALL TABLA
    BANKSEL PORTC
    MOVWF PORTC
    
    MOVF NUMTECLA,W
    SUBLW 0x08		    ;Se presiono la tecla 1?
    BTFSS STATUS,Z
    GOTO DONE_TECLADO_INT   ;No se presion�, no prendo el led
    GOTO ACTIVAR_ALARMA	    ;Si se presion�, se prende el led y se activa la alarma
    
ACTIVAR_ALARMA
    MOVLW 0x01
    MOVWF ACTIVADA
    BSF PORTA,RB0
    
DONE_TECLADO_INT
    BCF INTCON,RBIF
    BCF INTCON,T0IF
    RETURN
    
    END