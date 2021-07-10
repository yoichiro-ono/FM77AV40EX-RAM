        ORG     $7000
        BRA     MAIN
TESTS   FCB     $00
TESTE   FCB     $0F
ERR     FCB     0
ERRADR  FDB     0
MAIN    LDX     #$6000
        LDY     #$FD86
        LDB     TESTS,PCR
        CLR     ERR,PCR
SET_LOOP
        CMPB    TESTE,PCR
        BGT     CHECK
        STB     ,Y
        BSR     SET_MEM
        INCB
        BRA     SET_LOOP
CHECK   LDB     TESTS,PCR
CHECK_LOOP
        CMPB    TESTE,PCR
        BGT     MAIN_END
        STB     ,Y
        BSR     CHK_MEM
        BCS     MAIN_END
        INCB
        BRA     CHECK_LOOP
MAIN_END
        RTS
SET_MEM
        PSHS    D,X
SET_MEM_L
        STB     ,X+
        INCB
        CMPX    #$7000
        BCS     SET_MEM_L
        PULS    D,X,PC
CHK_MEM
        PSHS    D,X
CHK_MEM_L
        CMPB    ,X+
        BNE     CHK_MEM_ERR
        INCB
        CMPX    #$7000
        BCS     SET_MEM_L
        PULS    D,X,PC
CHK_MEM_ERR
        STX     ERRADR,PCR
        COMB
        PULS    D,X,PC
        END
