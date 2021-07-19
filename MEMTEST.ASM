*------------------------------------------------------------------------------
* EXPAND MEMORY TEST
* PHYSICAL ADDRESS $40000-$BFFFF
*
* The algorithm for the memory test was based on the following website/PDF.
*
* https://github.com/anachrocomputer/RC2014tester
*
* https://ballyalley.com/ml/ml_source/RAM%20Test%20[From%20Z80%20Assembly%20Language%20Subroutines].pdf
*
* http://www.ganssle.com/articles/ramtest.htm
*
* assemble
*  lwasm --output=memtest.bin --list=memtest.lst -r -9 memtest.asm
*------------------------------------------------------------------------------
        OPT     c
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
        
        LDU     #FILL_TEST_PAT
        CLRB
FILL_L:
        PSHS    B
        LDA     B,U
        PSHS    A
        LDY     #FILL_PAT
        LBSR    OUTHEX2
        LDX     #MSG_FILL
        LBSR    PRINT
        PULS    A
        LBSR    FILL_MEM
        LBSR    COMP_MEM
        LBCS    ERROR
        BSR     PRINT_OK
        PULS    B
        INCB
        CMPB    #18
        BCS     FILL_L
        
        LDX     #MSG_RW_55AA
        LBSR    PRINT
        LDD     #$55AA
        LBSR    WRM_MEM
        BCS     ERROR
        BSR     PRINT_OK

        LDX     #MSG_RW_AA55
        LBSR    PRINT
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

*        LDX     #MSG_RAND_STR
*        BSR     PRINT
*        LBSR    RND_STR
*        BCS     ERROR
*        BSR     PRINT_OK
        
        LDX     #MSG_EXEC_RAM
        BSR     PRINT
        LBSR    EXEC_RAM
        BCS     ERROR
        BSR     PRINT_OK
        
        ;address/data line stress
        LDX     #MSG_AD_STRESS
        BSR     PRINT
        ;ramのアドレスラインがALL0とALL1に対して高速に読み書き
        LDD     #$40BF
        *$5000-:$40000
        *$6000-:$BF000
        STD     $FD85
        LDX     #$5000  $40000
        LDU     #$6FFF  $BFFFF
        LDY     #256
        LDA     #$FF
        CLRB            256times
TESTL1
        STA     ,X
        STA     ,U
        CMPA    ,X
        BNE     ERROR
        STB     ,X
        LEAY    -1,Y
        BNE     TESTL1
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
*random string
RND_STR
        *make 727bytes random string
        LDX     #STRING
        LDY     #727/2+1
RND_STR1
        LBSR    RANDOM
        STD     ,X++
        LEAY    -1,Y
        BNE     RND_STR1
        *write random string to ext ram
        BSR     RND_STR_W
        *compare random string
        BSR     RND_STR_C
        RTS

*-------------------------------------------------
*write random string
RND_STR_W
        CLRA
        LDY     #STRING
RND_SW_L1
        PSHS    D
        LBSR    SET_MAP_PAGE

        LDX     #MAP_CPU
RND_SW_L2
        CMPY    #STRINGE
        BNE     RND_SW_3
        LDY     #STRING
RND_SW_3
        LDA     ,Y+
        STA     ,X+
        CMPX    #(MAP_CPU+$1000)
        BNE     RND_SW_L2
        PULS    D
        INCB
        CMPB    #PADDR_T
        BLS     RND_SW_L1
        INCA
        BNE     RND_SW_L1
        RTS

*-------------------------------------------------
*compare random string
RND_STR_C
        *CLRA
        LDA     #1
        LDY     #STRING
RND_SC_L1
        PSHS    D
        LBSR    SET_MAP_PAGE

        LDX     #MAP_CPU
RND_SC_L2
        CMPY    #STRINGE
        BNE     RND_SC_1
        LDY     #STRING
RND_SC_1
        LDA     ,Y+
        CMPA    ,X+
        BNE     RND_SC_ER
        CMPX    #(MAP_CPU+$1000)
        BNE     RND_SC_L1
        PULS    D
        INCB
        CMPB    #PADDR_T
        BLS     RND_SC_L1
        DECA
        BNE     RND_SC_L1
        ANDCC   #$FE    clear carry
        RTS
RND_SC_ER
        *STX     
        ORCC    #1      set carry
        PULS    D,PC
*-------------------------------------------------
*execute on ext-ram
EXEC_RAM
        LDB     #PADDR_F
EXC_RAM_L
        PSHS    B
        LBSR    SET_MAP_PAGE

        LDX     #MAP_CPU
        LDY     #(4096-8)/2
        *store
        * LEAY 1,Y
        * 2044 times
        LDD     #$3121
EX_RAM_L1
        STD     ,X++
        LEAY    -1,Y
        BNE     EX_RAM_L1
        *store
        *830001   SUBD #1
        *1026F001 LBNE TESTLOOP
        *39       RTS
        LDD     #$8300
        STD     ,X++
        LDD     #$0110
        STD     ,X++
        LDD     #$26F0
        STD     ,X++
        LDD     #$0139
        STD     ,X++
        
        LDY     #0
        LDD     #16
        JSR     MAP_CPU
        CMPY    #32704          2044*16
        BNE     EXEC_RAM_E
        PULS    B
        INCB
        CMPB    #PADDR_T
        BLS     EXC_RAM_L
        ANDCC   #$FE    ;clear carry
        RTS
EXEC_RAM_E
        LDX     #MAP_CPU
        ORCC    #$01    ;set carry
        RTS
;---------------------------------------------------------------------------
;XORSHIFT-16bitによる乱数生成
; RANDOM_SEED ^= RANDOM_SEED << 7
; RANDOM_SEED ^= RANDOM_SEED >> 9
; RANDOM_SEED ^= RANDOM_SEED << 8
;	OUT	D	random($0000-$FFFF)
;---------------------------------------------------------------------------
RANDOM
	; seed ^= seed << 7
	LDA	RANDOM_SEED+1
	LDB	RANDOM_SEED
	RORB
	RORA
	RORB
	ANDB	#$80
	EORA	RANDOM_SEED
	EORB	RANDOM_SEED+1
	STD	RANDOM_SEED
	; RANDOM_SEED ^= RANDOM_SEED >> 9
	LDB	RANDOM_SEED
	LSRB
	EORB	RANDOM_SEED+1
	STB	RANDOM_SEED+1
	; RANDOM_SEED ^= RANDOM_SEED << 8
	LDA	RANDOM_SEED+1
	EORA	RANDOM_SEED
	STA	RANDOM_SEED
	;d=RANDOM_SEED
	RTS
RANDOM_SEED
        FDB     15955
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
MSG_FILL
        FCC     /FILL MEMORY WITH $/
FILL_PAT
        FCC     /00:/
        FDB     0

FILL_TEST_PAT
        FCB     $00,$01,$02,$04,$08,$10,$20,$40,$80
        FCB     $FF,$FE,$FD,$FB,$F7,$EF,$DF,$BF,$7F

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

MSG_EXEC_RAM
        FCC     /EXECUTE ON EXT-RAM:/
        FDB     0
MSG_RAND_STR
        FCC     /RANDOM STRING:/
        FDB     0
MSG_AD_STRESS
        FCC     /ADDRESS DATA STRESS:/
        FDB     0
MSG_OK
        FCC     /OK/
        FCB     $0D,$0A,0

MSG_ERR
        FCC     /ERROR AT $/
ERRORAD FCC     /xxxxx:xx/
        FCB     $0D,$0A,0
STRING  RMB     727
STRINGE
        RMB     1
