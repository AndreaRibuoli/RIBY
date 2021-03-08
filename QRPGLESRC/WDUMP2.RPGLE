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
     D DescT           S             10I 0
     D DataT           S             10I 0
     D DesI1           S             10I 0
     D DesI2           S             10I 0
     D ILn             S             10I 0
     D ErrCd           S             12A
     D*
     C                   DUMP(A)
     C                   CALLP     CEEDOD(1:DescT:DataT:DesI1:DesI2:ILn:ErrCd)
     C                   EVAL      OutString = ErrCd
     C                   RETURN
