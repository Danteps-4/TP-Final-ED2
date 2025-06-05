    LIST P=16F887
    #include <P16F887.INC>

    ;__CONFIG _CONFIG1, _INTRC_IO & _WDT_OFF & _PWRTE_ON & _MCLRE_OFF & _CP_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF
    ;__CONFIG _CONFIG2, _LVP_OFF

    ORG 0x00          ; Vector de reset
    GOTO INICIO
    ORG 0x04          ; Vector de interrupción
    GOTO INTERRUPCION

; ========================
; Programa principal
; ========================
INICIO:
    CLRWDT
    ; Configurar puertos
    BANKSEL TRISB
    BSF TRISB, 0       ; RB0 como entrada
    BANKSEL TRISC
    CLRF TRISC         ; RCx como salidas
    BANKSEL PORTC
    CLRF PORTC         ; Apagar LEDs
    BANKSEL IOCB
    MOVLW b'11110000'
    MOVWF IOCB

    ; Configurar interrupción externa
    BANKSEL INTCON
    BSF INTCON, INTE   ; Habilita interrupción externa en RB0
    BCF INTCON, INTEDG ; Interrupción por flanco de bajada
    BSF INTCON, PEIE   ; Habilita interrupciones periféricas
    BSF INTCON, GIE    ; Habilita interrupciones globales
    BSF INTCON, RBIE
    BCF INTCON, RBIF

LOOP:
    NOP
    NOP
    NOP
    GOTO LOOP          ; Espera pasiva, interrupciones hacen el trabajo

; ========================
; Rutina de interrupción
; ========================
INTERRUPCION:
    BTFSS INTCON, INTF ; ¿Es interrupción por RB0?
    RETFIE             ; Si no lo es, salir

    ; Acciones cuando ocurre flanco de bajada en RB0
    BANKSEL PORTC
    MOVF PORTC, W
    XORLW 0x01         ; Toggle RC0 (enciende o apaga el LED)
    MOVWF PORTC

    BCF INTCON, INTF   ; Limpiar bandera de interrupción externa
    RETFIE

    END
