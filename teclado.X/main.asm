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
KEYNUM EQU 0x20
AUX_FILE EQU 0x21
AUX_KEYNUM EQU 0x22
SALVAW EQU 0x23
SALVAS EQU 0x24
ACTIVADA EQU 0x25
 
;Variables para las contrase?as
TEMPORAL EQU 0x30
VALOR_NUEVO EQU 0x31
CARACTERES_INGRESADOS EQU 0x32
IGUALDADES_CONTRASENA EQU 0x33
CONTRASENA EQU 0x34
VALOR_NUEVO_2 EQU 0X35
Delay1 EQU 0x36
Delay2 EQU 0x37
Delay3 EQU 0x38
 
UNIDADES EQU 0x40
DECENAS EQU 0x41
CONT1 EQU 0x42
AUX1 EQU 0x43

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
    ;GIE-PEIE-T0IE-INTE-RBIE-T0IF-INTF-RBIF
    MOVLW b'11001000'	    ; Se habilitan interrupciones globales, de perifericos y por PORTB
    IORWF INTCON,F
    
    CLRF ACTIVADA
    CLRF CONT1
    CLRF IGUALDADES_CONTRASENA
    
    ; Desactivar módulo USART
    BANKSEL TXSTA
    BCF TXSTA, TXEN    ; Apaga la transmisión
    BANKSEL RCSTA
    BCF RCSTA, SPEN    ; Apaga el puerto serie (TX y RX)
        
    CALL Delay500ms
    BANKSEL PORTA
    BSF PORTA,RA3
    ; ----CONFIGURACION PARA RECIBIR EN EL PIC POR COMUNICACION SERIE----
    ; Configure SPBRG for desired baud rate
    BANKSEL SPBRG
    MOVLW d'25'
    MOVWF SPBRG
    ; Configure TXSTA - TXEN=1 (transmision activada) , SYNC=0 (asincrono) , BRGH=1 (high transmision baud rate)
    ; CSRC-TX9-TXEN-SYNC-SENDB-BRGH-TRMT-TX9D
    BANKSEL TXSTA
    MOVLW b'00100100'
    MOVWF TXSTA
    ; Configure RCSTA - SPEN=1 (enable serial port) , CREN=1 (enable receiver)
    BANKSEL RCSTA
    MOVLW b'10010000'
    MOVWF RCSTA
    
    BANKSEL PIE1
    ;ADIE RCIE TXIE SSPIE CCP1IE TMR2IE TMR1IE
    MOVLW b'00100000'
    MOVWF PIE1
    
    BANKSEL PORTA
    BSF PORTA,RB2	
    
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
    
    BANKSEL PIR1
    BTFSC PIR1, RCIF
    CALL INT_SERIALPORT
    
    BANKSEL INTCON
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
    
INT_SERIALPORT
    
    ;1 => ACTIVAR ALARMA
    ;2 => DESACTIVAR ALARMA
    ;3 => CAMBIAR CONTRASENIA
    ;4 => ENVIAR ESTADO ALARMA
    
    BANKSEL RCREG
    MOVF RCREG,W		    ; Se captura la informacion
    MOVWF TEMPORAL
    
    MOVLW 0x30			    ; Se lo convierte a numero porque viene en ASCII
    SUBWF TEMPORAL,W
    MOVWF TEMPORAL		    ; Se guarda el numero convertido

    CALL DISPLAY_7SEGMENTOS	    ; TODO: Quitar esto
    MOVWF PORTD			    ; Se muestra en el display
    
    MOVF TEMPORAL,W		    ; Se cheque si se envio un 1
    SUBLW 0X01
    BTFSC STATUS,Z
    CALL ACTIVAR_ALARMA
    
    MOVF TEMPORAL,W		    ; Se chequea si se envio un 2
    SUBLW 0X02
    BTFSC STATUS,Z
    CALL DESACTIVAR_ALARMA
    
    MOVF TEMPORAL,W		    ; Se chequea si se envio un 4
    SUBLW 0X04
    BTFSC STATUS,Z
    CALL ENVIAR_ESTADO_ALARMA
    
    RETURN
    
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
    RETURN			    ;SI lleg? a 16, salgo
    GOTO SCAN_NEXT		    ;NO lleg? a 16, busca proxima fila
    
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
    
    BANKSEL IGUALDADES_CONTRASENA
    MOVF IGUALDADES_CONTRASENA,W
    BANKSEL EEADR
    MOVWF EEADR
    
    BANKSEL EECON1
    BCF EECON1, EEPGD
    BSF EECON1, RD
    BANKSEL EEDATA
    MOVF EEDATA,W
    BANKSEL VALOR_NUEVO_2
    MOVWF VALOR_NUEVO_2		    ; Obtengo la informacion desde la eeprom y la guardo en VALOR_NUEVO_2
    
    MOVF VALOR_NUEVO_2,W		    ; Comparo los dos valores
    SUBWF VALOR_NUEVO,W
    BTFSS STATUS,Z
    GOTO CONTRASENA_INCORRECTA	    ; No coincide, reinicio
    INCF IGUALDADES_CONTRASENA,F    ; Coincide, aumento el indice
    
    MOVF IGUALDADES_CONTRASENA,W    ; Verifico si ya se ingresaron todos los digitos (2 en este caso)
    SUBLW 0x04
    BTFSC STATUS,Z
    GOTO CHEQUEO_ALARMA		    ; Si, son iguales todos los digitos de la CONTRASENA
    RETURN

CONTRASENA_INCORRECTA
    ;TODO: Hacer sonar la alarmita por 5ms
    CLRF IGUALDADES_CONTRASENA
    RETURN
    
CHEQUEO_ALARMA
    MOVF ACTIVADA,W		    ; Chequeo si la alarma esta activada
    SUBLW d'1'			    ; Le resto 1 a ACTIVADA
    BTFSS STATUS,Z
    GOTO ACTIVAR_ALARMA
    GOTO DESACTIVAR_ALARMA
    
ACTIVAR_ALARMA
    CALL SEND_ACTIVANDO_ALARMA ; Aviso que la alarma se esta 
    ; Cargo la cuenta regresiva
    BANKSEL UNIDADES
    MOVLW d'5'
    MOVWF UNIDADES
    MOVLW d'1'
    MOVWF DECENAS

CUENTA_REGRESIVA
    MOVLW d'54'
    MOVWF AUX1
    
OTRA_CUENTA_REGRESIVA
    CALL MOSTRAR_DISPLAY
    DECFSZ AUX1,F
    GOTO OTRA_CUENTA_REGRESIVA
    
    MOVF UNIDADES,W
    SUBLW 0x00
    BTFSS STATUS,Z
    GOTO DECREMENTAR_UNIDADES
    
    ; Si UNIDADES=0, verificar DECENAS
    MOVF DECENAS,W
    SUBLW 0x00
    BTFSS STATUS,Z
    GOTO CARGAR_UNIDADES
    
    BANKSEL PORTD	    ; Si SI es 0
    CLRF PORTD		    ; Limpio el PORTD indicando que se activo
    MOVLW 0x01
    MOVWF ACTIVADA	    ; Muevo un "1" a ACTIVADA para decir que la alarma esta activada
    BANKSEL PORTA
    BSF PORTA,RA0	    ; Prendo el led conectado a RA0
    BANKSEL PORTE
    BSF PORTE,RE0
    RETURN

MOSTRAR_DISPLAY
    ; Mostrar UNIDADES
    BANKSEL PORTE
    BSF PORTE,RE0
    BANKSEL UNIDADES
    MOVF UNIDADES,W
    CALL DISPLAY_7SEGMENTOS
    MOVWF PORTD
    CALL DELAY_10MS
    BANKSEL PORTE
    BCF PORTE,RE0
    
    ; Mostrar DECENAS
    BANKSEL PORTE
    BSF PORTE,RE1
    BANKSEL DECENAS
    MOVF DECENAS,W
    CALL DISPLAY_7SEGMENTOS
    MOVWF PORTD
    CALL DELAY_10MS
    BANKSEL PORTE
    BCF PORTE,RE1
    
    RETURN
    
DECREMENTAR_UNIDADES
    BANKSEL UNIDADES
    DECF UNIDADES,F
    GOTO CUENTA_REGRESIVA
    
CARGAR_UNIDADES
    BANKSEL UNIDADES
    MOVLW d'9'
    MOVWF UNIDADES
    DECF DECENAS,F
    GOTO CUENTA_REGRESIVA

DELAY_10MS
    ; Configuraciones del delay
    MOVLW d'1'
    MOVWF CONT1
    BANKSEL OPTION_REG
    BCF OPTION_REG,T0CS
    BANKSEL INTCON
    BCF INTCON,T0IF
    BSF INTCON,T0IE
    
ESPERA_EXTERIOR    
    BANKSEL TMR0
    MOVLW d'220'
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
    ;BANKSEL PIE1
    ;MOVLW b'00000000'
    ;MOVWF PIE1
    
    BANKSEL PORTA
    BSF PORTA,RB2		    ; Prendo un led indicando que esta en comunicacion
    CLRF CARACTERES_INGRESADOS	    ; Limpio caracteres ingresados
ESPERA_COMUNICACION
 
   BANKSEL PIR1
    BTFSS PIR1,RCIF		    ;Se chequea si llego la informacion completa
    GOTO ESPERA_COMUNICACION	    ;Vuelve al bucle, esperando que llegue todo
    
    ; Llego toda la informacion
    BANKSEL RCREG
    MOVF RCREG,W		    ; Se captura la informacion
    MOVWF TEMPORAL
    
    MOVLW 0x30			    ; Se lo convierte a numero porque viene en ASCII
    SUBWF TEMPORAL,W
    MOVWF TEMPORAL		    ; Se guarda el numero convertido
    
    ; Guardado en EEPROM
    BANKSEL CARACTERES_INGRESADOS
    MOVF CARACTERES_INGRESADOS,W
    BANKSEL EEADR
    MOVWF EEADR			    ; Direccion EEPROM = CARACTERES_INGRESADOS (va a ir sumandose de a 1)
    BANKSEL TEMPORAL
    MOVF TEMPORAL,W
    BANKSEL EEDATA
    MOVWF EEDATA			    ; Cargo data a escribir
    BANKSEL EECON1
    BCF EECON1, EEPGD		    ; Point to data memory
    BSF EECON1, WREN		    ; Enable writes
    
    BCF INTCON,GIE		    ; Deshabilita interrupciones globales

    MOVLW 0x55
    MOVWF EECON2             ; Parte 1 del "unlock"
    MOVLW 0xAA
    MOVWF EECON2             ; Parte 2 del "unlock"
    ; 6. Iniciar escritura
    BSF   EECON1, WR

    ; 7. Esperar a que se complete (puede hacerse con polling de WR)
WAIT_WRITE
    BTFSC EECON1, WR
    GOTO  WAIT_WRITE	    ; Espera a que se borre el bit WR
    
    BSF   INTCON, GIE	    ; 8. Rehabilitar interrupciones
    BCF   EECON1, WREN	    ; 9. Deshabilitar escritura para seguridad
    
    BANKSEL TEMPORAL
    MOVF TEMPORAL,W
    CALL DISPLAY_7SEGMENTOS
    BANKSEL PORTD
    MOVWF PORTD			    ; Se muestra en el display
    
    BANKSEL CARACTERES_INGRESADOS
    INCF CARACTERES_INGRESADOS,F    ; Incremento el valor de caracteres ingresados (para probar solo voy a usar contrase?as de 2 digitos)
    MOVF CARACTERES_INGRESADOS,W
    SUBLW d'4'			    
    BTFSS STATUS,Z		    ; Pregunto si los caracteres ingresados son 4
    GOTO ESPERA_COMUNICACION	    ; No son 4, sigo guardando caracteres
    
    BANKSEL PORTA		    ; Si son 4, salgo de la comunicacion
    BCF PORTA,RA2		    ; Apago el led indicando que se termino la comunicacion
    
    ;BANKSEL PIE1
    ;MOVLW b'00100000'
    ;MOVWF PIE1
    RETURN
    
ENVIAR_ESTADO_ALARMA
    MOVF ACTIVADA,W		    ; Chequeo si la alarma esta activada
    SUBLW 0x01
    BTFSC STATUS,Z
    GOTO SEND_ALARMA_ACTIVA	    ; SI esta activada
    GOTO SEND_ALARMA_DESACTIVADA    ; NO esta activada
    ;A => ALARMA ACTIVADA
    ;B => ALARMA DESACTIVADA
    ;C => ACTIVANDO ALARMA
SEND_ALARMA_ACTIVA
    MOVLW 'A'
    GOTO SEND_CHAR
    
SEND_ALARMA_DESACTIVADA
    MOVLW 'B'
    GOTO SEND_CHAR

SEND_ACTIVANDO_ALARMA
    MOVLW 'C'
    GOTO SEND_CHAR

SEND_CHAR
    BANKSEL PIR1
    BTFSS   PIR1, TXIF
    GOTO    $-1
    BANKSEL TXREG
    MOVWF   TXREG
    RETURN

Delay500ms
    BANKSEL Delay1
    movlw   d'5'      ; Bucle externo: 50 veces
    movwf   Delay1

Delay1_loop:
    movlw   d'200'
    movwf   Delay2

Delay2_loop:
    movlw   d'250'
    movwf   Delay3

Delay3_loop:
    nop
    nop
    decfsz  Delay3, f
    goto    Delay3_loop

    decfsz  Delay2, f
    goto    Delay2_loop

    decfsz  Delay1, f
    goto    Delay1_loop

    return
    
    END