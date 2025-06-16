;========================================
; PIC16F887 - Leer VersionReg del RC522
; Mostrarlo por PORTA
;========================================
    LIST P=16F887
    #include <P16F887.INC>

;----------------------------------------
; Configuración de fusibles
;----------------------------------------
    __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
    __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

;----------------------------------------
; Variables
;----------------------------------------
    CBLOCK 0x20
        temp
        byte_in
        bit_ctr
    ENDC

;----------------------------------------
; Inicio
;----------------------------------------
    ORG 0x00
    GOTO MAIN

;----------------------------------------
; Retardo simple
;----------------------------------------
DELAY:
    MOVLW D'10'
    MOVWF temp
DL1:
    NOP
    NOP
    DECFSZ temp, f
    GOTO DL1
    RETURN

;----------------------------------------
; Enviar un byte por SPI (bit-banging MSB first)
; Entrada: WREG
SPI_SEND:
    MOVWF temp
    MOVLW 8
    MOVWF bit_ctr
SND_LOOP:
    RLF temp, f
    BTFSC STATUS, C
    BSF PORTC, 5      ; MOSI = 1
    BTFSS STATUS, C
    BCF PORTC, 5      ; MOSI = 0
    BSF PORTC, 3      ; SCK = 1
    CALL DELAY
    BCF PORTC, 3      ; SCK = 0
    CALL DELAY
    DECFSZ bit_ctr, f
    GOTO SND_LOOP
    RETURN

;----------------------------------------
; Recibir un byte por SPI (bit-banging)
; Salida: byte_in
SPI_READ:
    CLRF byte_in
    MOVLW 8
    MOVWF bit_ctr
RD_LOOP:
    BSF PORTC, 3      ; SCK = 1
    CALL DELAY
    BCF PORTC, 3      ; SCK = 0
    RLF byte_in, f
    BTFSC PORTC, 4    ; MISO
    BSF byte_in, 0
    CALL DELAY
    DECFSZ bit_ctr, f
    GOTO RD_LOOP
    RETURN

;----------------------------------------
; Main
;----------------------------------------
MAIN:
    ; Configuración de puertos
    BANKSEL TRISA
    CLRF TRISA        ; PORTA como salida
    CLRF TRISC        ; PORTC como salida
    BSF TRISC, 4      ; RC4 (MISO) como entrada

    BANKSEL PORTA
    CLRF PORTA
    CLRF PORTC        ; Asegura valores iniciales bajos

MAIN_LOOP:
    ; Seleccionar RC522 (SS bajo)
    BCF PORTC, 2      ; SDA = 0

    ; Enviar dirección de lectura de VersionReg (0x37): 0x37 << 1 | 0x80 = 0xB4
    MOVLW 0xB4
    CALL SPI_SEND

    ; Leer respuesta
    CALL SPI_READ

    ; Deseleccionar RC522 (SS alto)
    BSF PORTC, 2      ; SDA = 1

    ; Mostrar valor en PORTA
    MOVF byte_in, W
    MOVWF PORTA

    GOTO MAIN_LOOP

    END
