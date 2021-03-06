     H COPYRIGHT('(C) Copyright Andrea Ribuoli 2021')
     D/COPY QTEMP/QRPGLESRC,WDUMP_OP_H
     D WDUMP_OP        PI                    OPDESC
     D   InString                   100      CONST OPTIONS(*VARSIZE)
     D   OutString                  200      OPTIONS(*VARSIZE)
     D*
     D CEEDOD          PR
     D ParmNum                       10I 0 CONST
     D                               10I 0
     D                               10I 0
     D                               10I 0
     D                               10I 0
     D                               10I 0
     D                               12A   OPTIONS(*OMIT)
     D*
     D DescType        S             10I 0
     D DataType        S             10I 0
     D DescInfo1       S             10I 0
     D DescInfo2       S             10I 0
     D InLen           S             10I 0
     D HexLen          S             10I 0
     D*
     C                   DUMP(A)
     C*                  CALLP     CEEDOD(1         : DescType : DataType :
     C*                                   DescInfo1 : DescInfo2: Inlen    :
     C*                                   *OMIT)
     C*                  CALLP     CEEDOD(2         : DescType : DataType :
     C*                                   DescInfo1 : DescInfo2: HexLen   :
     C*                                   *OMIT)
     C                   EVAL      OutString = InString
     C                   RETURN
