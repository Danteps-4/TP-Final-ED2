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
ACTIVANDOSE EQU 0x26
CUENTA_REGRESIVA EQU 0x27

CONT1 EQU 0x28	    ; Los contadores para el delay de 1 seg de la cuenta regresiva
 
;Variables para las contraseñas
TEMPORAL EQU 0x30
VALOR_NUEVO EQU 0x31
CARACTERES_INGRESADOS EQU 0x32
IGUALDADES_CONTRASENA EQU 0x33
CONTRASENA EQU 0x34

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
    MOVLW b'01110111'	;Pullups PORTB="0" (si es para PROTEUS tienen que estar en "1"), T0CS=T0CKI (pin para detener el timer), Prescaler 256
    MOVWF OPTION_REG
    BANKSEL TRISB
    MOVLW b'11110000'
    MOVWF TRISB
    CLRF TRISC
    MOVWF WPUB		; Pullups ON (si es para PROTEUS tienen que estar en OFF)
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
    BANKSEL PORTA	    ; Habilito el PORTA como salidas para led, buzzer, etc
    CLRF PORTA
    BANKSEL ANSEL
    CLRF ANSEL
    BANKSEL TRISA
    CLRF TRISA
    
    BANKSEL INTCON
    CLRF INTCON
    MOVLW b'11001000'	    ; Se habilitan interrupciones globales, de perifericos y por PORTB
    IORWF INTCON,F
    
    CLRF ACTIVADA
    CLRF ACTIVANDOSE
    CLRF CONT1
    CLRF IGUALDADES_CONTRASENA
    
    ; ----CONFIGURACION PARA RECIBIR EN EL PIC POR COMUNICACION SERIE----
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
    
MAIN
    NOP
    NOP
    NOP
    GOTO MAIN

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
    
VALORES
    ADDWF PCL, F
    RETLW b'00000001'     ; KEYNUM 0  ? '1'
    RETLW b'00000100'     ; KEYNUM 1  ? '4'
    RETLW b'00000111'     ; KEYNUM 2  ? '7'
    RETLW 0xFF		  ; KEYNUM 3  ? '*' -> valor invalido porque lo uso despues para disparar la alarma

    RETLW b'00000010'     ; KEYNUM 4  ? '2'
    RETLW b'00000101'     ; KEYNUM 5  ? '5'
    RETLW b'00001000'     ; KEYNUM 6  ? '8'
    RETLW b'00000000'     ; KEYNUM 7  ? '0'

    RETLW b'00000011'     ; KEYNUM 8  ? '3'
    RETLW b'00000110'     ; KEYNUM 9  ? '6'
    RETLW b'00001001'     ; KEYNUM 10 ? '9'
    RETLW 0xFF		  ; KEYNUM 11 ? '#' -> valor invalido porque lo uso despues para habilitar la comunicacion

    RETLW b'00010001'     ; KEYNUM 12 ? 'A'
    RETLW b'00010010'     ; KEYNUM 13 ? 'B'
    RETLW b'00010011'     ; KEYNUM 14 ? 'C'
    RETLW b'00010100'     ; KEYNUM 15 ? 'D'
    
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
    RETURN			    ;SI llegó a 16, salgo
    GOTO SCAN_NEXT		    ;NO llegó a 16, busca proxima fila
    
SR_KEY
    MOVF KEYNUM,W
    CALL TABLA
    MOVWF PORTD
    
    MOVF KEYNUM,W
    SUBLW d'3'			    ; Se presiono la tecla "*"????
    BTFSC STATUS,Z
    GOTO ACTIVAR_BUZZER		    ; Si se presiono, voy a chequear el buzzer
    
    
    MOVF KEYNUM,W
    SUBLW d'11'			    ; Se presiono la tecla "#"????
    BTFSC STATUS,Z
    GOTO HABILITAR_COMUNICACION	    ; Si se presiono, voy a habilitar la comuncacion serial para recibir datos
    
CHEQUEO_CONTRASENA 
    MOVF KEYNUM,W
    CALL VALORES		    ; Llamo a la tabla para hacer la conversion de los valores
    MOVWF VALOR_NUEVO
    
    MOVLW CONTRASENA
    ADDWF IGUALDADES_CONTRASENA,W
    MOVWF FSR
    MOVF INDF,W
    SUBWF VALOR_NUEVO,W		    ; Se presiono la tecla con el valor de la CONTRASENA????
    BTFSS STATUS,Z
    GOTO CONTRASENA_INCORRECTA	    ; No coincide, reinicio
    INCF IGUALDADES_CONTRASENA,F    ; Coincide, aumento el indice
    
    MOVF IGUALDADES_CONTRASENA,W    ; Verifico si ya se ingresaron todos los digitos (2 en este caso)
    SUBLW 0x02
    BTFSC STATUS,Z
    GOTO CHEQUEO_ALARMA		    ; Si, son iguales todos los digitos de la CONTRASENA
    RETURN

CONTRASENA_INCORRECTA
    CLRF IGUALDADES_CONTRASENA
    RETURN
    
CHEQUEO_ALARMA
    MOVF ACTIVADA,W		    ; Chequeo si la alarma esta activada
    SUBLW d'1'			    ; Le resto 1 a ACTIVADA
    BTFSS STATUS,Z
    GOTO ACTIVAR_ALARMA
    GOTO DESACTIVAR_ALARMA
    
ACTIVAR_ALARMA
    MOVLW 0x01
    MOVWF ACTIVANDOSE		    ; Pongo un "1" en ACTIVANDOSE para decir que estoy en la cuenta regresiva
    
    MOVLW 0x09
    MOVWF CUENTA_REGRESIVA	    ; Cargo CUENTA_REGRESIVA con el numero 9 para hacer la cuenta regresiva
 
OTRA_CUENTA_REGRESIVA
    MOVF CUENTA_REGRESIVA,W
    CALL DISPLAY_7SEGMENTOS
    MOVWF PORTD		    ; Lo muestro en el display
    
    CALL DELAY_1SEG	    ; LLamo a un delay de 1 seg
    
    DECFSZ CUENTA_REGRESIVA,F
    GOTO OTRA_CUENTA_REGRESIVA	; Si no es 0, vuelvo a contar
    
    BANKSEL PORTD	    ; Si SI es 0
    CLRF PORTD		    ; Limpio el PORTD indicando que se activo
    
    CLRF ACTIVANDOSE	    ; Limpio la variable ACTIVANDOSE
    
    MOVLW 0x01
    MOVWF ACTIVADA	    ; Muevo un "1" a ACTIVADA para decir que la alarma esta activada
    BANKSEL PORTA
    BSF PORTA,RA0	    ; Prendo el led conectado a RA0
    RETURN

DELAY_1SEG
    ; Configuraciones del delay
    MOVLW d'20'
    MOVWF CONT1
    BANKSEL OPTION_REG
    BCF OPTION_REG,T0CS
    BANKSEL INTCON
    BCF INTCON,T0IF
    BSF INTCON,T0IE
    
ESPERA_EXTERIOR    
    BANKSEL TMR0
    MOVLW d'60'
    MOVWF TMR0
ESPERA
    BANKSEL INTCON
    BTFSS INTCON,T0IF
    GOTO ESPERA
    BCF INTCON,T0IF
    DECFSZ CONT1,F
    GOTO ESPERA_EXTERIOR
    
    BANKSEL OPTION_REG
    BSF OPTION_REG,T0CS
    BANKSEL INTCON
    BCF INTCON,T0IF
    BCF INTCON,T0IE
    
    RETURN
    
DESACTIVAR_ALARMA
    CLRF ACTIVADA	    ; Limpio ACTIVADA
    BANKSEL PORTA
    BCF PORTA,RA0	    ; Apago el led conectado a RA0
    BCF PORTA,RA1
    RETURN

ACTIVAR_BUZZER
    MOVF ACTIVADA,W	    ; Chequeo si la alarma esta activada
    SUBLW 0x01
    BTFSC STATUS,Z
    BSF PORTA,RA1	    ; SI esta activada, activo el buzzer
    RETURN		    ; NO esta activada, vuelvo

HABILITAR_COMUNICACION
    BANKSEL PORTA
    BSF PORTA,RB2		    ; Prendo un led indicando que esta en comunicacion
    CLRF CARACTERES_INGRESADOS	    ; Limpio caracteres ingresados
ESPERA_COMUNICACION
    BANKSEL PIR1
    BTFSS PIR1,RCIF		    ;Se chequea si llego la informacion completa
    GOTO ESPERA_COMUNICACION	    ;Vuelve al bucle, esperando que llegue todo
    
    ; Llegó toda la informacion
    BANKSEL RCREG
    MOVF RCREG,W		    ; Se captura la informacion
    MOVWF TEMPORAL
    
    MOVLW 0x30			    ; Se lo convierte a numero porque viene en ASCII
    SUBWF TEMPORAL,W
    MOVWF TEMPORAL		    ; Se guarda el numero convertido
    
    
    MOVLW CONTRASENA		    ; Hago el guardar en CONTRASENA + indice (CARACTERES_INGRESADOS)
    ADDWF CARACTERES_INGRESADOS,W
    MOVWF FSR
    MOVF TEMPORAL,W
    MOVWF INDF
    
    CALL DISPLAY_7SEGMENTOS
    MOVWF PORTD			    ; Se muestra en el display
    
    INCF CARACTERES_INGRESADOS,F    ; Incremento el valor de caracteres ingresados (para probar solo voy a usar contraseñas de 2 digitos)
    MOVF CARACTERES_INGRESADOS,W
    SUBLW d'2'			    
    BTFSS STATUS,Z		    ; Pregunto si los caracteres ingresados son 2
    GOTO ESPERA_COMUNICACION	    ; No son 2, sigo guardando caracteres
    
    BANKSEL PORTA		    ; Si son 2, salgo de la comunicacion
    BCF PORTA,RA2		    ; Apago el led indicando que se termino la comunicacion
    
    RETURN
    
    END