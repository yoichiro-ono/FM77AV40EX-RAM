*-------------------------------------------------
* EXPAND MEMORY TEST
* PHYSICAL ADDRESS $40000-$BFFFF
* assemble
* lwasm --output=memtest.bin --list=memtest.lst -r -9 memtest.asm
*-------------------------------------------------
MAP_CPU EQU     $5000
MAPPAGE EQU     MAP_CPU/4096
PADDR_F EQU     $40
PADDR_T EQU     $BF
        ORG     $3000
        SETDP   $FD
MAIN    PSHS    DP,CC,D,X,Y,U
        LDA     #$FD
        TFR     A,DP
        LBSR    MMRINI

        LDX     #MSG_FILL_00
        LBSR    PRINT
        CLRA
        LBSR    FILL_MEM
        LBSR    COMP_MEM
        BCS     ERROR
        BSR     PRINT_OK
        
        LDX     #MSG_FILL_FF
        BSR     PRINT
        LDA     #$FF
        LBSR    FILL_MEM
        LBSR    COMP_MEM
        BCS     ERROR
        BSR     PRINT_OK

        LDX     #MSG_RW_55AA
        BSR     PRINT
        LDD     #$55AA
        LBSR    WRM_MEM
        BCS     ERROR
        BSR     PRINT_OK

        LDX     #MSG_RW_AA55
        BSR     PRINT
        LDD     #$AA55
        LBSR    WRM_MEM
        BCS     ERROR
        BSR     PRINT_OK

        ; Clear RAM to all AA
        LDA     #$AA
        LBSR    FILL_MEM

        LDX     #MSG_ASC_MARCH
        BSR     PRINT
        LBSR    ASC_MARCH
        BCS     ERROR
        BSR     PRINT_OK

        LDX     #MSG_DSC_MARCH
        BSR     PRINT
        LBSR    DSC_MARCH
        BCS     ERROR
        BSR     PRINT_OK
        
MAINEND
        LDB     #$30+MAPPAGE
        STB     <($FD80+MAPPAGE)
        PULS    DP,CC,D,X,Y,U,PC

;-------------------------------------------------
PRINT_OK
        LDX     #MSG_OK
        BRA     PRINT

*-------------------------------------------------
ERROR   ;X=ERROR ADDRESS
        ;PADDR=MAP PAGE
        LEAY    ERRORAD,PCR
        LDA     PADDR,PCR
        BSR     OUTHEX2
        LDA     ERADDR,PCR
        ANDA    #$0F
        BSR     OUTHEX1
        LDA     ERADDR+1,PCR
        BSR     OUTHEX2
        LEAY    1,Y
        LDA     ERDATA,PCR
        BSR     OUTHEX2
        LDX     #MSG_ERR
        BSR     PRINT
        BRA     MAINEND
*-------------------------------------------------
PRINT   PSHS    U
        BSR     SUBHLT
        CLRB
        LDU     #$FC84
PRINT1  LDA     ,X+
        BEQ     PRINT2
        STA     ,U+
        INCB
        BRA     PRINT1
PRINT2  LDA     #$03
        STD     $FC82
        BSR     SUBRST
        PULS    U,PC
*-------------------------------------------------
SUBHLT  ORCC    #$40            disable firq
SUBHLT1 LDA     <$FD05
        BMI     SUBHLT1
        LDA     #$80
        STA     <$FD05
SUBHLT2 LDA     <$FD05
        BPL     SUBHLT2
        RTS
*-------------------------------------------------
SUBRST  CLR     <$FD05
        ANDCC   #$AF            enable firq
        RTS
*-------------------------------------------------
OUTHEX2 PSHS    A
        LSRA
        LSRA
        LSRA
        LSRA
        BSR     OUTHEX1
        PULS    A
        ;BRA     OUTHEX1
*-------------------------------------------------
OUTHEX1 ANDA    #$0F
        ADDA    #$30
        CMPA    #$3a
        BLO     OUTH1_2
        ADDA    #7
OUTH1_2 STA     ,Y+
        RTS
*-------------------------------------------------
SET_MAP_PAGE
        STB     <($FD80+MAPPAGE)
        STB     PADDR,PCR
        RTS
PADDR   FCB     0
ERDATA  FCB     0
ERADDR  FDB     0
*-------------------------------------------------
*fill memory
FILL_MEM
        LDB     #PADDR_F
FILL_M_L
        PSHS    B
        BSR     SET_MAP_PAGE
        BSR     FILL_PAGE
        PULS    B
        INCB
        CMPB    #PADDR_T
        BLS     FILL_M_L
        RTS
*-------------------------------------------------
*compare memory
COMP_MEM
        LDB     #PADDR_F
COMP_M_L
        PSHS    B
        BSR     SET_MAP_PAGE
        BSR     COMP_PAGE
        PULS    B
        BCS     COMP_M_E
        INCB
        CMPB    #PADDR_T
        BLS     COMP_M_L
        ANDCC   #$FE    ;clear carry
COMP_M_E
        RTS
*-------------------------------------------------
*write/read match
WRM_MEM
        TFR     D,Y
        LDB     #PADDR_F
WRM_MEM_L
        BSR     SET_MAP_PAGE
        EXG     D,Y
        BSR     WRM_PAGE
        EXG     D,Y
        BCS     WRM_MEM_E
        INCB
        CMPB    #PADDR_T
        BLS     WRM_MEM_L
        ANDCC   #$FE    ;clear carry
WRM_MEM_E
        RTS
*-------------------------------------------------
*ascending march
ASC_MARCH
        LDB     #PADDR_F
ASC_M_L
        PSHS    B
        BSR     SET_MAP_PAGE
        BSR     ASC_M_PAGE
        PULS    B
        BCS     ASC_M_E
        INCB
        CMPB    #PADDR_T
        BLS     ASC_M_L
        ANDCC   #$FE    ;clear carry
ASC_M_E
        RTS
*-------------------------------------------------
*descending march
DSC_MARCH
        LDB     #PADDR_T+1
DSC_M_L
        DECB
        PSHS    B
        BSR     SET_MAP_PAGE
        LBSR    DSC_M_PAGE
        PULS    B
        BCS     DSC_M_E
        CMPB    #PADDR_F
        BNE     DSC_M_L
        ANDCC   #$FE    ;clear carry
DSC_M_E
        RTS
*-------------------------------------------------
*fill page(4KBytes)
FILL_PAGE
        LDX     #MAP_CPU
FILL_PG_1
        STA     ,X+
        CMPX    #(MAP_CPU+$1000)
        BNE     FILL_PG_1
        RTS
*-------------------------------------------------
*compare page(4KBytes)
COMP_PAGE
        PSHS    A
        LDX     #MAP_CPU
COMP_PG_1
        CMPA    ,X+
        BNE     COMP_PG_E
        CMPX    #(MAP_CPU+$1000)
        BNE     COMP_PG_1
        ANDCC   #$FE     ;clear carry
        PULS    A,PC
COMP_PG_E
        LDA     ,-X
        STA     ERDATA
        STX     ERADDR
        ORCC    #$1     ;set carry
        PULS    A,PC
*-------------------------------------------------
*Write/Write/Read match page(4KBytes)
WRM_PAGE
        LDX     #MAP_CPU
WRM_P_L
        STA     ,X
        STB     ,X
        CMPB    ,X
        BNE     WRM_P_ERR
        LEAX    1,X
        CMPX    #(MAP_CPU+$1000)
        BCS     WRM_P_L
        ANDCC   #$FE     ;clear carry
        RTS
WRM_P_ERR
        PSHS    A
        LDA     ,X
        STA     ERDATA,PCR
        STX     ERADDR,PCR
        PULS    A

        ORCC    #$1     ;set carry
        RTS
*-------------------------------------------------
*ascending march page(4KBytes)
ASC_M_PAGE
        LDX     #MAP_CPU
        LDD     #$AA55
ASC_MP_L
        CMPA    ,X
        BNE     ASC_MP_ERR
        STB     ,X+
        CMPX    #(MAP_CPU+$1000)
        BNE     ASC_MP_L
        ANDCC   #$FE     ;clear carry
        RTS
ASC_MP_ERR
        PSHS    A
        LDA     ,X
        STA     ERDATA,PCR
        STX     ERADDR,PCR
        PULS    A
        ORCC    #$1     ;set carry
        RTS
*-------------------------------------------------
*descending march page(4KBytes)
DSC_M_PAGE
        LDX     #MAP_CPU+$1000
        LDD     #$55AA
DSC_MP_L
        CMPA    ,-X
        BNE     DSC_MP_ERR
        STB     ,X
        CMPX    #MAP_CPU
        BNE     DSC_MP_L
        ANDCC   #$FE     ;clear carry
        RTS
DSC_MP_ERR
        PSHS    A
        LDA     ,X
        STA     ERDATA,PCR
        STX     ERADDR,PCR
        PULS    A
        ORCC    #$1     ;set carry
        RTS
*-------------------------------------------------
*mmr initialize
MMRINI
        BSR     MMROFF
        LDD     #$8508
        STD     <$FD94
*        LDA     #1
*        STA     <$FD90
*        LDX     #$FD80
*        LDD     #$3010
*MMRINI1 STA     ,X+
*        INCA
*        DECB
*        BNE     MMRINI1
MMRON   LDA     <$FD93
        ORA     #$80
        STA     <$FD93          enable mmr
        RTS
*-------------------------------------------------
MMROFF  LDA     <$FD93
        ANDA    #$7F            disable mmr
        STA     <$FD93
        RTS
*-------------------------------------------------
*messages
MSG_FILL_00
        FCC     /FILL MEMORY WITH $00:/
        FCB     0

MSG_FILL_FF
        FCC     /FILL MEMORY WITH $FF:/
        FCB     0

MSG_RW_55AA
        FCC     'WRITE/WRITE/READ MEMORY WITH $55AA:'
        FCB     0

MSG_RW_AA55
        FCC     'WRITE/WRITE/READ MEMORY WITH $AA55:'
        FCB     0

MSG_ASC_MARCH
        FCC     /ASCENDING MARCH:/
        FCB     0

MSG_DSC_MARCH
        FCC     /DESCENDING MARCH:/
        FCB     0

MSG_OK
        FCC     /OK/
        FCB     $0D,$0A,0

MSG_ERR
        FCC     /ERROR AT $/
ERRORAD FCC     /xxxxx:xx/
        FCB     $0D,$0A,0
