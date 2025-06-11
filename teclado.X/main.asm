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
DISPARADA EQU 0x26
SEQUENCE_POS EQU 0x27		
QUE_INTERRUPCION EQU 0x28	    ; =1 si fue por teclado, =2 si fue ...
 
;Para el guardado de las teclas presionadas
TECLA_0 EQU 0x30
TECLA_1 EQU 0x31
 
;Para el guardado de las contraseñas
;Password 1
CLAVE1_1 EQU 0x40
CLAVE1_2 EQU 0x41
;Password 2
CLAVE2_1 EQU 0x42
CLAVE2_2 EQU 0x43
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
    MOVLW b'11110111'	;Pullups PORTB=OFF, T0CS=T0CKI (pin para detener el timer), Prescaler 256
    MOVWF OPTION_REG
    BANKSEL TRISB
    MOVLW b'11110000'
    MOVWF TRISB
    CLRF TRISC
    ;MOVWF WPUB
    MOVWF IOCB
    BANKSEL PORTB
    CLRF PORTB
    MOVF PORTB,F
    MOVLW b'10000000'
    MOVWF PORTC
    BANKSEL INTCON
    CLRF INTCON
    MOVLW b'11001000'	; Se habilitan interrupciones globales, de perifericos y por PORTB
    IORWF INTCON,F
    
    BANKSEL PORTD	;Habilito el PORTD todo como salidas (para poner el led que indica que la alarma esta activada y el buzzer)
    CLRF PORTD
    BANKSEL TRISD
    CLRF TRISD		
    BANKSEL PORTE	;Habilito el PORTE y RE0 para el boton de sensor de movimiento que activa la alarma
    CLRF PORTE
    BANKSEL ANSEL
    CLRF ANSEL
    BCF STATUS,RP1
    BANKSEL TRISE
    MOVLW b'00000001'
    MOVWF TRISE
    
    ;Inicializacion de las passwords
    ;Password 1 (1-4)
    BCF STATUS,RP0
    BCF STATUS,RP1
    MOVLW d'0'
    MOVWF CLAVE1_1
    MOVLW d'1'
    MOVWF CLAVE1_2
    ;Password 2 (1-7)
    MOVLW d'0'
    MOVWF CLAVE2_1
    MOVLW d'2'
    MOVWF CLAVE2_2
    
LOOP
    MOVF DISPARADA,W
    SUBLW 0x01
    BTFSS STATUS,Z
    GOTO CHEQUEAR_BOTON
    BANKSEL PORTD
    BSF PORTD,RD1
    
    GOTO LOOP
    
CHEQUEAR_BOTON
    BANKSEL PORTE
    BTFSC PORTE,RE0
    GOTO VERIFICAR_ACTIVACION
    GOTO LOOP

VERIFICAR_ACTIVACION
    ; ¿La alarma está activada?
    MOVF ACTIVADA,W
    SUBLW 0x01
    BTFSS STATUS,Z
    GOTO LOOP

    ; Activada y botón presionado ? disparar alarma
    MOVLW 0x01
    MOVWF DISPARADA

    BSF PORTD,RD1        ; Encender buzzer
    GOTO LOOP
    
TABLA
    ADDWF PCL,F
    RETLW b'10000110'	;1
    RETLW b'11100110'	;4
    RETLW b'10000111'	;7
    RETLW b'11110110'	;*
    
    RETLW b'11011011'	;2
    RETLW b'11101101'	;5
    RETLW b'11111111'	;8
    RETLW b'10111111'	;0
    
    RETLW b'11001111'	;3
    RETLW b'11111101'	;6
    RETLW b'11100111'	;9
    RETLW b'11110110'	;#
    
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
    MOVLW 0x01
    MOVWF QUE_INTERRUPCION	; La interrupcion fue por teclado -> entonces: QUE_INTERRUPCION = 1
    BANKSEL PORTB
    MOVF PORTB,F
    BCF INTCON,RBIF
    BCF INTCON,RBIE
    BANKSEL TMR0
    MOVLW d'60'			; Para que dure 50 ms antirebote
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
    
    ; Se chequea por que interrupcion vino el TMR0
    MOVF QUE_INTERRUPCION,W
    SUBLW 0x01
    BTFSC STATUS,Z
    GOTO POR_TECLADO		; La interrupcion vino del teclado

FINAL_DE_INT_TMR0
    BANKSEL INTCON
    BCF INTCON,RBIF
    BSF INTCON,RBIE
    CLRF QUE_INTERRUPCION
    RETURN
    
POR_TECLADO
    CALL SCAN
    BANKSEL PORTB
    CLRF PORTB
    MOVF PORTB,F
    GOTO FINAL_DE_INT_TMR0
    
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
    MOVLW 0x0C
    SUBWF KEYNUM,W
    BTFSC STATUS,Z
    RETURN			;Llegó a 12, salgo
    GOTO SCAN_NEXT		;NO llegó a 12, busca proxima fila
    
SR_KEY
    MOVF KEYNUM,W
    CALL TABLA
    BANKSEL PORTC
    MOVWF PORTC
    
    MOVF KEYNUM,W
    SUBLW d'2'		    
    BTFSC STATUS,Z		; Se presiono la tecla "#"?
    GOTO COMPARAR_PASSWORD	; entonces se compara la password
    
    ; No se presiono la tecla "#", se presiono un numero cualquiera
    BCF STATUS,RP0
    BCF STATUS,RP1
    MOVF SEQUENCE_POS,W		
    ADDWF PCL,F
    GOTO POS0
    GOTO POS1
POS0
    MOVF KEYNUM,W
    MOVWF TECLA_0	    ;Muevo el valor de la tecla presionada a TECLA0
    INCF SEQUENCE_POS,F
    RETURN
POS1
    MOVF KEYNUM,W
    MOVWF TECLA_1	    ;Muevo el valor de la tecla presionada a TECLA1
    CLRF SEQUENCE_POS	    ;Reseteo la secuencia porque es la ultima posicion
    RETURN

COMPARAR_PASSWORD
    ;Comparar con CLAVE1
    MOVF TECLA_0,W
    XORWF CLAVE1_1,W
    BTFSS STATUS,Z
    GOTO CLAVE2
    
    MOVF TECLA_1,W
    XORWF CLAVE1_2,W
    BTFSS STATUS,Z
    GOTO CLAVE2
    
    GOTO CLAVE_CORRECTA
    
CLAVE2
    RETURN
    
CLAVE_CORRECTA
    MOVLW 0x01
    SUBWF ACTIVADA
    BTFSC STATUS,Z
    GOTO DESACTIVAR_ALARMA
    GOTO ACTIVAR_ALARMA
    
ACTIVAR_ALARMA
    BANKSEL PORTD
    BSF PORTD,RB0
    MOVLW 0x01
    MOVWF ACTIVADA
    RETURN

DESACTIVAR_ALARMA
    BANKSEL PORTD
    BCF PORTD,RD0
    BCF PORTD,RD1
    CLRF DISPARADA
    CLRF ACTIVADA
    RETURN
    
    END