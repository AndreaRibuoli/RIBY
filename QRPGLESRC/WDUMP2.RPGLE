     H COPYRIGHT('(C) Copyright Andrea Ribuoli 2021')
     D/COPY QTEMP/QRPGLESRC,WDUMP2_H
     D WDUMP2          PI                    OPDESC
     D   InString                    64      CONST OPTIONS(*VARSIZE)
     D   OutString                   64      OPTIONS(*VARSIZE)
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
     D Desc_t          S             10I 0
     D Data_t          S             10I 0
     D DescI1          S             10I 0
     D DescI2          S             10I 0
     D InLen           S             10I 0
     D*
     C                   DUMP(A)
     C                   CALLP     CEEDOD(1:Desc_t:Data_t:DescI1:DescI2:Inlen:
     C                                    *OMIT)
     C                   EVAL      OutString = InString
     C                   RETURN
