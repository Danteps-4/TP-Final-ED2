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
KEYNUM EQU 0x20
AUX_FILE EQU 0x21
AUX_KEYNUM EQU 0x22
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
    BANKSEL ANSELH
    CLRF ANSELH
    BANKSEL OPTION_REG
    MOVLW b'01110111'	;Pullups PORTB=on, T0CS=T0CKI (pin para detener el timer), Prescaler 256
    MOVWF OPTION_REG
    BANKSEL TRISB
    MOVLW b'11110000'
    MOVWF TRISB
    CLRF TRISC
    MOVWF WPUB		; Pullups ON
    MOVWF IOCB
    BANKSEL PORTB
    CLRF PORTB
    MOVF PORTB,F
    BANKSEL PORTD
    MOVLW b'11111111'	    ; Al principio, prendo todos los segmentos del display
    MOVWF PORTD
    BANKSEL TRISD
    CLRF TRISD
    BANKSEL PORTE	    ; Habilito el PORTE como salidas para el ?multiplexado?
    CLRF PORTE
    BSF PORTE,0
    BANKSEL ANSEL
    CLRF ANSEL
    BCF STATUS,RP1
    BANKSEL TRISE
    CLRF TRISE
    BANKSEL PORTA	    ; Habilito el PORTA como salidas para led activada, buzzer, etc
    CLRF PORTA
    BANKSEL ANSEL
    CLRF ANSEL
    BANKSEL TRISA
    CLRF TRISA
    
    BANKSEL INTCON
    CLRF INTCON
    MOVLW b'11001000'	; Se habilitan interrupciones globales, de perifericos y por PORTB
    IORWF INTCON,F
    
    CLRF ACTIVADA
    
LOOP
    NOP
    NOP
    NOP
    GOTO LOOP
    
TABLA
    ADDWF PCL,F
    RETLW b'10000110'	;1
    RETLW b'11100110'	;4
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
    
    RETLW b'11110111'	;A
    RETLW b'11111100'	;B
    RETLW b'10111001'	;C
    RETLW b'11011110'	;D
    
ISR
    ; Guardo el contexto
    MOVWF SALVAW
    SWAPF STATUS,W
    MOVWF SALVAS
    
    BTFSC INTCON,T0IF
    CALL INT_TMR0
    
    BTFSC INTCON,RBIF
    CALL INT_TECLADO
    
    ; Recupero el contexto
    SWAPF SALVAS,W
    MOVWF STATUS
    SWAPF SALVAW,F
    SWAPF SALVAW,W
    
    RETFIE
    
INT_TECLADO
    BANKSEL PORTB
    MOVF PORTB,F
    BCF INTCON,RBIF
    BCF INTCON,RBIE
    BANKSEL TMR0
    MOVLW d'180'
    MOVWF TMR0
    BANKSEL OPTION_REG
    BCF OPTION_REG,T0CS		; Para iniciar funcionamiento del timer
    BANKSEL INTCON
    BCF INTCON,T0IF
    BSF INTCON,T0IE
    RETURN
    
INT_TMR0
    BANKSEL OPTION_REG
    BSF OPTION_REG,T0CS
    BANKSEL INTCON
    BCF INTCON,T0IF
    BCF INTCON,T0IE
    CALL SCAN
    BANKSEL PORTB
    CLRF PORTB
    MOVF PORTB,F
    BANKSEL INTCON
    BCF INTCON,RBIF
    BSF INTCON,RBIE
    RETURN
    
SCAN
    MOVF KEYNUM,W
    MOVWF AUX_KEYNUM
    CLRF KEYNUM
    MOVLW b'00001110'
    MOVWF AUX_FILE
SCAN_NEXT
    BANKSEL PORTB
    MOVF AUX_FILE,W
    MOVWF PORTB
    BTFSS PORTB,RB4
    GOTO SR_KEY
    INCF KEYNUM,F
    
    BTFSS PORTB,RB5
    GOTO SR_KEY
    INCF KEYNUM,F

    BTFSS PORTB,RB6
    GOTO SR_KEY
    INCF KEYNUM,F

    BTFSS PORTB,RB7
    GOTO SR_KEY
    INCF KEYNUM,F
    
    BSF STATUS,C
    RLF AUX_FILE,F
    MOVLW d'16'
    SUBWF KEYNUM,W
    BTFSC STATUS,Z
    RETURN		    ;Llegó a 16, salgo
    GOTO SCAN_NEXT	    ;NO llegó a 16, busca proxima fila
    
SR_KEY
    MOVF KEYNUM,W
    CALL TABLA
    MOVWF PORTD
    
    MOVF KEYNUM,W
    SUBLW d'1'		    ; Se presiono la tecla "4"????
    BTFSC STATUS,Z
    GOTO CHEQUEO_ALARMA	    ; SI se presiono, voy a chequear la alarma
    RETURN		    ; NO se presiono, vuelvo
CHEQUEO_ALARMA
    MOVF ACTIVADA,W	    ; Chequeo si la alarma esta activada
    SUBLW d'1'		    ; Le resto 1 a ACTIVADA
    BTFSS STATUS,Z
    GOTO ACTIVAR_ALARMA
    GOTO DESACTIVAR_ALARMA
    
ACTIVAR_ALARMA
    MOVLW 0x01
    MOVWF ACTIVADA	    ; Muevo un "1" a ACTIVADA para decir que la alarma esta activada (fase 1 de ACTIVADA - para realizar la cuenta regresiva mas adelante)
    BANKSEL PORTA
    BSF PORTA,RA0	    ; Prendo el led conectado a RA0
    RETURN
    
DESACTIVAR_ALARMA
    CLRF ACTIVADA	    ; Limpio ACTIVADA
    BANKSEL PORTA
    BCF PORTA,RA0	    ; Apago el led conectado a RA0
    RETURN
    
    END