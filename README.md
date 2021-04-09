# RIBY
Tips for **Ruby 3.0** in *powerpc-os400*

----
When I was in High School I was quite good at Maths and I was often asked for help by classmates.
My nickname was *Riby*, out of my family name.

That's why I decided to name this GitHub repository **RIBY**: it is here to help the few that would be so courageous to face the hurdles of installing
Ruby gems in **IBM i PASE**.
Riby also has a curious assonance with **Ruby**, the programming language we will leverage on.

I would suggest an [IBM i chroot](https://github.com/IBM/ibmichroot) approach so you do not risk compromising any of your existing PASE configurations.

But let us start from the beginning, I will add content gradually based on the feedback of the... class!

The most recent content will be on top of the README so, if you will join later on, start reading from the bottom (or follow the index).

Let's go!

----
## INDEX

1. [to pave the way](#1-to-pave-the-way)
2. [to refurbish the flat](#2-to-refurbish-the-flat)
3. [to install Ruby 3.0](#3-to-install-ruby-30)
4. [to do everything once again](#4-to-do-everything-once-again)
5. [to study IBM i through PASE with Ruby](#5-to-study-ibm-i-through-pase-with-ruby)
6. [to gain confidence on Ruby language](#6-to-gain-confidence-on-ruby-language)
7. [to get acquainted with QSYS/QC2xx service programs](#7-to-get-acquainted-with-qsysqc2xx-service-programs)
8. [to execute a service program entry call from PASE](#8-to-execute-a-service-program-entry-call-from-pase)
9. [to gather information on space pointers from PASE](#9-to-gather-information-on-space-pointers-from-pase)
10. [to move around tagged pointers](#10-to-move-around-tagged-pointers)
11. [to investigate parameter passing](#11-to-investigate-parameter-passing)
12. [to investigate parameter passing again](#12-to-investigate-parameter-passing-again)
13. [to review the lesson on objects](#13-to-review-the-lesson-on-objects)
14. [to put previous lessons into practice](#14-to-put-previous-lessons-into-practice)
15. [to have fun by reliving old glories](#15-to-have-fun-by-reliving-old-glories)
16. [to have fun with QTEMP](#16-to-have-fun-with-qtemp)
17. [to retrieve job attributes](#17-to-retrieve-job-attributes)
18. [to retrieve command definition](#18-to-retrieve-command-definition)
19. [to pretend we do not care](#19-to-pretend-we-do-not-care)
20. [to increase our confidence](#20-to-increase-our-confidence)
21. [to connect](#21-to-connect)
22. [to get info about the DBMS](#22-to-get-info-about-the-dbms)
23. [to get the current setting of an attribute](#23-to-get-the-current-setting-of-an-attribute)
24. [to manage statements](#24-to-manage-statements)
25. [to diagnose on errors](#25-to-diagnose-on-errors)
26. [to finally execute statements](#26-to-finally-execute-statements)
27. [to commit our statements](#27-to-commit-our-statements)


----
### 27. to commit our statements

In a previous chapter we verified the DB connection attribute `SQL_ATTR_AUTOCOMMIT` (10003) was set to SQL\_FALSE.
This explains why our last statements:

1. *CREATE TABLE QGPL.RIBY_TBL (NOME CHAR(20))* 
2. *DROP TABLE QGPL.RIBY_TBL*

seemed to be non consistent: every time the Ruby process ends, all un-committed changes are rolled back.
So that there is no RIBY\_TBL file in QGPL when DROP request is executed!

Let us introduce *AUTOCOMMIT* in [a variant of our original script](invoke_SQLExecDirectW_wAC.rb).
We need `SQLSetConnectAttrW`. We also integrate the request for SERVER MODE (that is why we ask for user and password).

```
bash-4.4$ invoke_SQLExecDirectW_wAC.rb 'CREATE TABLE QGPL.RIBY_TBL (NOME CHAR(20))' 'ANDREA' 'password'
RC=0;
SQLSTATE=01567
ERROR=7905
MSG=La tabella RIBY_TBL in QGPL è stata creata ma non registrata su giornale.

bash-4.4$ invoke_SQLExecDirectW_wAC.rb 'DROP TABLE QGPL.RIBY_TBL' 'ANDREA' 'password'
```

##### Commitment Control


To reach a finer commitment control we will need to introduce a new API: [`SQLEndTran` API](https://www.ibm.com/docs/en/i/7.4?topic=functions-sqlendtran-commit-roll-back-transaction). 

```
SQLRETURN SQLEndTran (SQLSMALLINT    hType,
                      SQLHENV        handle,
                      SQLSMALLINT    fType);
```

| type         | value | hex     |
| ------------ |:-----:| ------- |
|  ARG_INT16   | -3    |  0xFFFD |  
|  ARG_INT32   | -5    |  0xFFFB | 
|  ARG_INT16   | -3    |  0xFFFD |  
|  ARG_END     | 0     |  0x0000 | 


```
     | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | A | B | C | D | E | F |
| 2x | hType |-------|  henv / hdbc  | fType |-----------------------|
```

| fType mnemonic                 | v |
| ------------------------------ |:-:|
| SQL\_COMMIT                    | 0 |     
| SQL\_ROLLBACK                  | 1 |   
| SQL\_COMMIT\_HOLD              | 2 |   
| SQL\_ROLLBACK\_HOLD            | 3 |   
| SQL\_SAVEPOINT\_NAME\_RELEASE  | 4 |
| SQL\_SAVEPOINT\_NAME\_ROLLBACK | 5 |

```
bash-5.0$ invoke_SQLExecDirectW_wCommit.rb 'CREATE TABLE QGPL.RIBY_TBL (NOME CHAR(20))' 'ANDREA' 'password'
RC=0;
SQLSTATE=01567
ERROR=7905
MSG=La tabella RIBY_TBL in QGPL è stata creata ma non registrata su giornale.

bash-5.0$ invoke_SQLExecDirectW_wCommit.rb 'DROP TABLE QGPL.RIBY_TBL' 'ANDREA' 'password'
```

##### More general considerations

In the field of DB2 integration it is now appropriate to arrange what we have learnt by experiments into something more structured. As always this is the most difficult part and will probably require time.

* We rarely used Ruby `pack`/`unpack` options except **H\*** and it is probably the right time to refine our knowledge on the options available to handle big-endian signed integers of various sizes.
* The mnemonics for Env/Connect/Stmt attribute values could be structured for the benefit of the programmer. 
* The relationships between Env, Connect and Stmt could be better handled in an object oriented fashion: why don't we introduce Ruby classes with specialized methods? 

----
### 26. to finally execute statements


We collected enough information to start using our statement handles. 
Let's begin with the simplest API: `SQLExecDirectW`

```
SQLRETURN SQLExecDirectW (SQLHSTMT      hstmt,
                          SQLWCHAR      *szSqlStr,
                          SQLINTEGER    cbSqlStr);
```

| type         | value | hex     |
| ------------ |:-----:| ------- |
|  ARG_INT32   | -5    |  0xFFFB |  
|  ARG_MEMPTR  | -11   |  0xFFF5 | 
|  ARG_INT32   | -5    |  0xFFFB |  
|  ARG_END     | 0     |  0x0000 | 

We will test for returned errors by means of `SQLErrorW` (specifying the `hstmt` parameter).

```
bash-4.4$ invoke_SQLExecDirectW.rb 'ADD SOMETHING'
RC=-1;
SQLSTATE=42601
ERROR=-199
MSG=Parola chiave ADD non prevista. Token validi: ( CL END GET SET TAG CALL DROP FREE HOLD LOCK OPEN WITH ALTER.

bash-4.4$ invoke_SQLExecDirectW.rb 'SELECT'
RC=-1;
SQLSTATE=42601
ERROR=-104
MSG=Token <FINE-ISTRUZIONI> non valido. Token validi: ( + * - ? : DAY INF LAG NAN RID ROW.

bash-4.4$ invoke_SQLExecDirectW.rb 'SELECT * FROM PIPPO'
RC=-1;
SQLSTATE=42704
ERROR=-204
MSG=PIPPO in ANDREA di tipo *FILE non trovato.

bash-4.4$ invoke_SQLExecDirectW.rb 'SELECT * FROM PIPPO/PIPPO'
RC=-1;
SQLSTATE=42833
ERROR=-5016
MSG=Nome oggetto qualificato PIPPO non valido.

bash-4.4$ invoke_SQLExecDirectW.rb 'SELECT * FROM QGPL.NONEXIST'
RC=-1;
SQLSTATE=42704
ERROR=-204
MSG=NONEXIST in QGPL di tipo *FILE non trovato.

bash-4.4$ invoke_SQLExecDirectW.rb 'SELECT * FROM QGPL.QCLSRC'
RC=-1;
SQLSTATE=42704
ERROR=-204
MSG=*FIRST in *N di tipo *MEM non trovato.

bash-4.4$ invoke_SQLExecDirectW.rb 'SELECT * FROM QGPL.PASERIE'
RC=-1;
SQLSTATE=42851
ERROR=-7011
MSG=PASERIE in QGPL non file tabella, vista o fisico.

bash-4.4$ invoke_SQLExecDirectW.rb 'CREATE TABLE QGPL.RIBY_TBL (NOME CHAR(20))'
RC=0;
SQLSTATE=01567
ERROR=7905
MSG=La tabella RIBY_TBL in QGPL è stata creata ma non registrata su giornale.

bash-4.4$ invoke_SQLExecDirectW.rb 'DROP TABLE QGPL.RIBY_TBL'
RC=-1;
SQLSTATE=42704
ERROR=-204
MSG=RIBY_TBL in QGPL di tipo *FILE non trovato.
```

The last 2 statements require an explanation. 
We will explain commit logic in the next chapter!


----
### 25. to diagnose on errors

Some chapters ago we planned for support when SQL errors occur.
Now we will introduce [another Wide-API](https://www.ibm.com/docs/en/i/7.4?topic=functions-sqlerror-retrieve-error-information) that will help in the retrieval of error information.
 
``` C
SQLRETURN SQLErrorW (SQLHENV       henv,
                     SQLHDBC       hdbc,
                     SQLHSTMT      hstmt,
                     SQLWCHAR      *szSqlState,
                     SQLINTEGER    *pfNativeError,
                     SQLWCHAR      *szErrorMsg,
                     SQLSMALLINT   cbErrorMsgMax,
                     SQLSMALLINT   *pcbErrorMsg);
```

| type         | value | hex     |
| ------------ |:-----:| ------- |
|  ARG_INT32   | -5    |  0xFFFB |  
|  ARG_INT32   | -5    |  0xFFFB |  
|  ARG_INT32   | -5    |  0xFFFB |  
|  ARG_MEMPTR  | -11   |  0xFFF5 | 
|  ARG_MEMPTR  | -11   |  0xFFF5 | 
|  ARG_MEMPTR  | -11   |  0xFFF5 | 
|  ARG_INT16   | -3    |  0xFFFD |  
|  ARG_MEMPTR  | -11   |  0xFFF5 | 
|  ARG_END     | 0     |  0x0000 | 

We will excercize the API on possible errors received when directly passing the 3 parameters of the `SQLConnectW` API as received from the script argument list.

We are building on the knowledge acquired in previous scripts.

```
     | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | A | B | C | D | E | F |
| 2x |    h e n v    |    h d b c    |   h s t m t   |---------------|
| 3x |                   * s z S q l S t a t e                       |
| 4x |                * p f N a t i v e E r r o r                    |
| 5x |                   * s z E r r o r M s g                       |
| 6x | cbEMx |-------------------------------------------------------|
| 7x |                  * p c b E r r o r M s g                      |

```

```
bash-4.4$ invoke_SQLConnectW_wErrorMsg.rb 'PROVA' '' ''
RC=-1;
SQLSTATE=42705
ERROR=-950
MSG=Il database relazionale PROVA non si trova nell'indirizzario del database relazionale.

bash-4.4$ invoke_SQLConnectW_wErrorMsg.rb '*LOCAL' '' '' 
RC=-1;
SQLSTATE=42977
ERROR=-7022
MSG=Utente *N diverso dall'utente corrente ANDREA.

bash-4.4$ invoke_SQLConnectW_wErrorMsg.rb '*LOCAL' '*CURRENT' '' 

bash-4.4$ 
```

----
### 24. to manage statements


Actual interaction with the DBMS occurs within *statements*. 
Inside an active connection we can open multiple statements.

This is the output of [invoke_SQLGetStmtAttrW.rb script](invoke_SQLGetStmtAttrW.rb) with the statement attributes that appear to be working with IBM DB2 for i 7.4:

```
$ invoke_SQLGetStmtAttrW.rb 
Environment handle 0x00000001
DB Connection handle 0x00000002
Statement handle 0x00000003
SQL_ATTR_APP_ROW_DESC (10010): 0x00000000
SQL_ATTR_APP_PARAM_DESC (10011): 0x00000000
SQL_ATTR_IMP_ROW_DESC (10012): 0x00000000
SQL_ATTR_IMP_PARAM_DESC (10013): 0x00000000
SQL_ATTR_FOR_FETCH_ONLY (10014): 0x00000000
SQL_ATTR_CURSOR_SCROLLABLE (10015): 0x00000000
SQL_ATTR_ROWSET_SIZE (10016): 0x00000001
SQL_ATTR_CURSOR_HOLD (10017): 0x00000000
SQL_ATTR_FULL_OPEN (10018): 0x00000000
SQL_ATTR_EXTENDED_COL_INFO (10019): 0x00000000
SQL_ATTR_BIND_TYPE (10049): 0x00000000
SQL_ATTR_CURSOR_TYPE (10050): 0x00000000
SQL_ATTR_CURSOR_SENSITIVITY (10051): 0x00000000
SQL_ATTR_ROW_BIND_TYPE (10056): 0x00000000
SQL_ATTR_PARAM_BIND_TYPE (10057): 0x00000000
SQL_ATTR_PARAMSET_SIZE (10058): 0x00000001
Attribute 10062 unknown
Attribute 10063 unknown
Attribute 10064 unknown
Attribute 10065 unknown
Attribute 10066 unknown
```


##### SERVER MODE

The most fundamental setting is the adoption of **SERVER MODE**. 
The IBM documentation introduces the concept this way:

 *The reason for running in SQL server mode is that many applications need to act as database servers. This means that a single job performs SQL requests on behalf of multiple users.*
 
The limitations encountered **without** adopting SQL server mode are:

* Only **one commit transaction** per activation group per single job.
* Only **one connection** to a relational database (RDB) per single job.
* All SQL statements run under **one user profile only**: the job user (regardless of the user ID passed on connect!). 

In one of the previous chapters we received:

```
SQL_ATTR_SERVER_MODE (10004): 0x00000000
```

So the default for *SQL\_ATTR\_SERVER\_MODE* is **SQL_FALSE (0)**. 
In order to adopt SERVER MODE we need to use another SQL CLI API: [`SQLSetEnvAttr`](https://www.ibm.com/docs/en/i/7.4?topic=functions-sqlsetenvattr-set-environment-attribute).

We will revisit previous Ruby scripts for collecting *Connect* and *Stmt* attributes when SERVER MODE is set (before DB connections are established).

##### SQLGetConnectAttrW (SERVER MODE)

```
Environment handle 0x00000001
SQL_ATTR_OUTPUT_NTS (10001): 0x00000001
SQL_ATTR_SYS_NAMING (10002): 0x00000000
SQL_ATTR_DEFAULT_LIB (10003): 0x00000000
SQL_ATTR_SERVER_MODE (10004): 0x00000001
SQL_ATTR_JOB_SORT_SEQUENCE (10005): 0x00000000
SQL_ATTR_ENVHNDL_COUNTER (10009): 0x00000000
SQL_ATTR_ESCAPE_CHAR (10010): 0x00004040
SQL_ATTR_DATE_FMT (10020): 0x00000001
SQL_ATTR_DATE_SEP (10021): 0x00000001
SQL_ATTR_TIME_FMT (10022): 0x00000001
SQL_ATTR_TIME_SEP (10023): 0x00000006
SQL_ATTR_DECIMAL_SEP (10024): 0x00000003
SQL_ATTR_INCLUDE_NULL_IN_LEN (10031): 0x00000001
SQL_ATTR_UTF8 (10032): 0x00000000
DB Connection handle 0x00000002
SQL_ATTR_XML_DECLARATION (2552): 0x00000007 0x00000000
SQL_ATTR_CURRENT_IMPLICIT_XMLPARSE_OPTION (2553): 0x00000000 0x00000000
SQL_ATTR_CONCURRENT_ACCESS_RESOLUTION (2595): 0x00000000 0x00000000
SQL_ATTR_AUTO_IPD (10001): 0x00000000 0x00000000
SQL_ATTR_ACCESS_MODE (10002): 0x00000001 0x00000000
SQL_ATTR_AUTOCOMMIT (10003): 0x00000000 0x00000000
SQL_ATTR_DBC_SYS_NAMING (10004): 0x00000000 0x00000000
SQL_ATTR_DBC_DEFAULT_LIB (10005): 0x00000000 0x00000002
SQL_ATTR_ADOPT_OWNER_AUTH (10006): 0x00000000 0x00000000
SQL_ATTR_SYSBAS_CMT (10007): 0x00000000 0x00000000
SQL_ATTR_DATE_FMT (10020): 0x00000001 0x00000000
SQL_ATTR_DATE_SEP (10021): 0x00000001 0x00000000
SQL_ATTR_TIME_FMT (10022): 0x00000001 0x00000000
SQL_ATTR_TIME_SEP (10023): 0x00000006 0x00000000
SQL_ATTR_DECIMAL_SEP (10024): 0x00000003 0x00000000
SQL_ATTR_TXN_EXTERNAL (10026): 0x00000000 0x00000000
SQL_ATTR_SAVEPOINT_NAME (10028): 0x00000000 0x00000002
SQL_ATTR_INCLUDE_NULL_IN_LEN (10031): 0x00000001 0x00000000
SQL_ATTR_UTF8 (10032): 0x00000000 0x00000000
SQL_ATTR_UCS2 (10035): 0x00000000 0x00000000
SQL_ATTR_MAX_PRECISION (10040): 0x0000001f 0x00000000
SQL_ATTR_MAX_SCALE (10041): 0x00000000 0x00000000
SQL_ATTR_MIN_DIVIDE_SCALE (10042): 0x00000000 0x00000000
SQL_ATTR_HEX_LITERALS (10043): 0x00000001 0x00000000
SQL_ATTR_CORRELATOR (10044): 0x00000000 0x00000000
SQL_ATTR_CONN_SORT_SEQUENCE (10046): 0x00000000 0x00000000
SQL_ATTR_INFO_USERID (10103): 0x00000000 0x00000002
SQL_ATTR_INFO_WRKSTNNAME (10104): 0x00000000 0x00000002
SQL_ATTR_INFO_APPLNAME (10105): 0x00000000 0x00000002
SQL_ATTR_INFO_ACCTSTR (10106): 0x00000000 0x00000002
SQL_ATTR_INFO_PROGRAMID (10107): 0x00000000 0x00000002
SQL_ATTR_DECFLOAT_ROUNDING_MODE (10112): 0x00000000 0x00000000
Attribute 0 unknown
```

Note that we are also reporting the returned length that is set to 2 for all wide-char empty strings.

##### SQLGetStmtAttrW (SERVER MODE)

```
Environment handle 0x00000001
SQL_ATTR_OUTPUT_NTS (10001): 0x00000001
SQL_ATTR_SYS_NAMING (10002): 0x00000000
SQL_ATTR_DEFAULT_LIB (10003): 0x00000000
SQL_ATTR_SERVER_MODE (10004): 0x00000001
SQL_ATTR_JOB_SORT_SEQUENCE (10005): 0x00000000
SQL_ATTR_ENVHNDL_COUNTER (10009): 0x00000000
SQL_ATTR_ESCAPE_CHAR (10010): 0x00004040
SQL_ATTR_DATE_FMT (10020): 0x00000001
SQL_ATTR_DATE_SEP (10021): 0x00000001
SQL_ATTR_TIME_FMT (10022): 0x00000001
SQL_ATTR_TIME_SEP (10023): 0x00000006
SQL_ATTR_DECIMAL_SEP (10024): 0x00000003
SQL_ATTR_INCLUDE_NULL_IN_LEN (10031): 0x00000001
SQL_ATTR_UTF8 (10032): 0x00000000
DB Connection handle 0x00000002
Statement handle 0x00000003
SQL_ATTR_APP_ROW_DESC (10010): 0x00000000
SQL_ATTR_APP_PARAM_DESC (10011): 0x00000000
SQL_ATTR_IMP_ROW_DESC (10012): 0x00000000
SQL_ATTR_IMP_PARAM_DESC (10013): 0x00000000
SQL_ATTR_FOR_FETCH_ONLY (10014): 0x00000000
SQL_ATTR_CURSOR_SCROLLABLE (10015): 0x00000000
SQL_ATTR_ROWSET_SIZE (10016): 0x00000001
SQL_ATTR_CURSOR_HOLD (10017): 0x00000000
SQL_ATTR_FULL_OPEN (10018): 0x00000000
SQL_ATTR_EXTENDED_COL_INFO (10019): 0x00000000
SQL_ATTR_BIND_TYPE (10049): 0x00000000
SQL_ATTR_CURSOR_TYPE (10050): 0x00000000
SQL_ATTR_CURSOR_SENSITIVITY (10051): 0x00000000
SQL_ATTR_ROW_BIND_TYPE (10056): 0x00000000
SQL_ATTR_PARAM_BIND_TYPE (10057): 0x00000000
SQL_ATTR_PARAMSET_SIZE (10058): 0x00000001
Attribute 10062 unknown
Attribute 10063 unknown
Attribute 10064 unknown
Attribute 10065 unknown
Attribute 10066 unknown
```
[NEXT-25](#25-to-diagnose-on-errors)

----
### 23. to get the current setting of an attribute

There are three sets of attributes (with some overlaps) that are queried with three different APIs. 
Two of which present an *SQL\-Wide* variant:

* [`SQLGetEnvAttr` API](https://www.ibm.com/docs/en/i/7.4?topic=functions-sqlgetenvattr-return-current-setting-environment-attribute)
* [`SQLGetConnectAttrW` API](https://www.ibm.com/docs/en/i/7.4?topic=functions-sqlgetconnectattr-get-value-connection-attribute)
* [`SQLGetStmtAttrW` API](https://www.ibm.com/docs/en/i/7.4?topic=functions-sqlgetstmtattr-get-value-statement-attribute)

They share a similar parameter list:

| type         | value | hex     |
| ------------ |:-----:| ------- |
|  ARG_INT32   | -5    |  0xFFFB |  
|  ARG_INT32   | -5    |  0xFFFB |  
|  ARG_MEMPTR  | -11   |  0xFFF5 | 
|  ARG_INT32   | -5    |  0xFFFB |  
|  ARG_MEMPTR  | -11   |  0xFFF5 | 
|  ARG_END     | 0     |  0x0000 | 


##### SQLGetEnvAttr

``` C
SQLRETURN SQLGetEnvAttr (SQLHENV      henv,
                         SQLINTEGER   Attribute,
                         SQLPOINTER   Value,
                         SQLINTEGER   BufferLength,
                         SQLINTEGER   *StringLength);
```

Surprisingly *SQLGetEnvAttr* offers two attributes that are character strings (*SQL\_ATTR\_DEFAULT\_LIB*) but there is no evidence they are still working. 


This is the output of [invoke_SQLGetEnvAttr.rb script](invoke_SQLGetEnvAttr.rb) with the environment attributes that appear to be working with IBM DB2 for i 7.4:

```
$ invoke_SQLGetEnvAttr.rb
Environment handle 0x00000001
SQL_ATTR_OUTPUT_NTS (10001): 0x00000001
SQL_ATTR_SYS_NAMING (10002): 0x00000000
SQL_ATTR_DEFAULT_LIB (10003): 0x00000000
SQL_ATTR_SERVER_MODE (10004): 0x00000000
SQL_ATTR_JOB_SORT_SEQUENCE (10005): 0x00000000
SQL_ATTR_ENVHNDL_COUNTER (10009): 0x00000000
SQL_ATTR_ESCAPE_CHAR (10010): 0x00004040
SQL_ATTR_DATE_FMT (10020): 0x00000001
SQL_ATTR_DATE_SEP (10021): 0x00000001
SQL_ATTR_TIME_FMT (10022): 0x00000001
SQL_ATTR_TIME_SEP (10023): 0x00000006
SQL_ATTR_DECIMAL_SEP (10024): 0x00000003
SQL_ATTR_INCLUDE_NULL_IN_LEN (10031): 0x00000001
SQL_ATTR_UTF8 (10032): 0x00000000
Attribute 10120 unknown
```

##### SQLGetConnectAttrW

``` C
SQLRETURN SQLGetConnectAttrW(   SQLHDBC      hdbc,
                                SQLINTEGER   fAttr,
                                SQLPOINTER   pvParam),;
                                SQLINTEGER   bLen,
                                SQLINTEGER   *sLen);
```

Without SERVER MODE we get the following list of active attribute, output of [invoke_SQLGetConnectAttrW.rb script](invoke_SQLGetConnectAttrW.rb):


```
$ invoke_SQLGetConnectAttrW.rb '*CURRENT' ''
Environment handle 0x00000001
DB Connection handle 0x00000002
SQL_ATTR_XML_DECLARATION (2552): 0x00000007
SQL_ATTR_CURRENT_IMPLICIT_XMLPARSE_OPTION (2553): 0x00000000
SQL_ATTR_CONCURRENT_ACCESS_RESOLUTION (2595): 0x00000000
SQL_ATTR_AUTO_IPD (10001): 0x00000000
SQL_ATTR_ACCESS_MODE (10002): 0x00000001
SQL_ATTR_AUTOCOMMIT (10003): 0x00000000
SQL_ATTR_DBC_SYS_NAMING (10004): 0x00000000
SQL_ATTR_DBC_DEFAULT_LIB (10005): 0x00000000
SQL_ATTR_ADOPT_OWNER_AUTH (10006): 0x00000000
SQL_ATTR_SYSBAS_CMT (10007): 0x00000000
SQL_ATTR_DATE_FMT (10020): 0x00000001
SQL_ATTR_DATE_SEP (10021): 0x00000001
SQL_ATTR_TIME_FMT (10022): 0x00000001
SQL_ATTR_TIME_SEP (10023): 0x00000006
SQL_ATTR_DECIMAL_SEP (10024): 0x00000003
SQL_ATTR_TXN_EXTERNAL (10026): 0x00000000
SQL_ATTR_SAVEPOINT_NAME (10028): 0x00000000
SQL_ATTR_INCLUDE_NULL_IN_LEN (10031): 0x00000001
SQL_ATTR_UTF8 (10032): 0x00000000
SQL_ATTR_UCS2 (10035): 0x00000000
SQL_ATTR_MAX_PRECISION (10040): 0x0000001f
SQL_ATTR_MAX_SCALE (10041): 0x00000000
SQL_ATTR_MIN_DIVIDE_SCALE (10042): 0x00000000
SQL_ATTR_HEX_LITERALS (10043): 0x00000001
SQL_ATTR_CORRELATOR (10044): 0x00000000
SQL_ATTR_CONN_SORT_SEQUENCE (10046): 0x00000000
SQL_ATTR_INFO_USERID (10103): 0x00000000
SQL_ATTR_INFO_WRKSTNNAME (10104): 0x00000000
SQL_ATTR_INFO_APPLNAME (10105): 0x00000000
SQL_ATTR_INFO_ACCTSTR (10106): 0x00000000
SQL_ATTR_INFO_PROGRAMID (10107): 0x00000000
SQL_ATTR_DECFLOAT_ROUNDING_MODE (10112): 0x00000000
Attribute 0 unknown
```
[NEXT-24](#24-to-manage-statements)

----
### 22. to get info about the DBMS

The [`SQLGetInfoW` API](https://www.ibm.com/docs/en/i/7.4?topic=functions-sqlgetinfo-get-general-information) is another useful Wide API.
It allows collecting various elements about the *DataBase Management System* we are connected to.

``` C
SQLRETURN SQLGetInfoW (SQLHDBC        hdbc,
                       SQLSMALLINT    fInfoType,
                       SQLPOINTER     rgbInfoValue,
                       SQLSMALLINT    cbInfoValueMax,
                       SQLSMALLINT    *pcbInfoValue);
```

We will focus on four information types that are returning null-terminated character strings:

``` C
#define SQL_DRIVER_NAME            6
#define SQL_DBMS_NAME             17
#define SQL_DBMS_VER              18
#define SQL_KEYWORDS             201
```

In the previous example we converted the DNS into *UTF\-16BE* to pass it as an input parameter. This time we will receive content as output. We know it will be encoded in *UTF\-16BE* and we will use Ruby `String#force_encoding('UTF-16BE')` to consistently tag the String object. Then we will apply `String#encode('utf-8')`.

| type         | value | hex     |
| ------------ |:-----:| ------- |
|  ARG_INT32   | -5    |  0xFFFB |  
|  ARG_INT16   | -3    |  0xFFFD |  
|  ARG_MEMPTR  | -11   |  0xFFF5 | 
|  ARG_INT16   | -3    |  0xFFFD |  
|  ARG_MEMPTR  | -11   |  0xFFF5 | 
|  ARG_END     | 0     |  0x0000 | 


The [latest script](invoke_SQLGetInfoW.rb) builds (again) on top of the previous one adding the second example of a Wide API. 

```
bash-4.4$ invoke_SQLGetInfoW.rb '*CURRENT' ''
Environment handle 0x00000001
DB Connection handle 0x00000002
SQL_DRIVER_NAME: QSQCLI.SRVPGM
SQL_DBMS_NAME: AS
SQL_DBMS_VER: 07040
SQL_KEYWORDS: ["AFTER", "ALIAS", "ALLOW", "APPLICATION", "ASSOCIATE", "ASUTIME", "AUDIT", "AUX", "AUXILIARY", "BEFORE", "BINARY", "BUFFERPOOL", "CACHE", "CALL", "CALLED", "CAPTURE", "CARDINALITY", "CCSID", "CLUSTER", "COLLECTION", "COLLID", "COMMENT", "CONCAT", "CONDITION", "CONTAINS", "COUNT_BIG", "CURRENT_LC_CTYPE", "CURRENT_PATH", "CURRENT_SERVER", "CURRENT_TIMEZONE", "CYCLE", "DATA", "DATABASE", "DAYS", "DB2GENERAL", "DB2GENRL", "DB2SQL", "DBINFO", "DEFAULTS", "DEFINITION", "DETERMINISTIC", "DISALLOW", "DO", "DSNHATTR", "DSSIZE", "DYNAMIC", "EACH", "EDITPROC", "ELSEIF", "ENCODING", "END-EXEC1", "ERASE", "EXCLUDING", "EXIT", "FENCED", "FIELDPROC", "FILE", "FINAL", "FREE", "FUNCTION", "GENERAL", "GENERATED", "GRAPHIC", "HANDLER", "HOLD", "HOURS", "IF", "INCLUDING", "INCREMENT", "INHERIT", "INOUT", "INTEGRITY", "ISOBID", "ITERATE", "JAR", "JAVA", "LABEL", "LC_CTYPE", "LEAVE", "LINKTYPE", "LOCALE", "LOCATOR", "LOCATORS", "LOCK", "LOCKMAX", "LOCKSIZE", "LONG", "LOOP", "MAXVALUE", "MICROSECOND", "MICROSECONDS", "MINUTES", "MINVALUE", "MODE", "MODIFIES", "MONTHS", "NEW", "NEW_TABLE", "NOCACHE", "NOCYCLE", "NODENAME", "NODENUMBER", "NOMAXVALUE", "NOMINVALUE", "NOORDER", "NULLS", "NUMPARTS", "OBID", "OLD", "OLD_TABLE", "OPTIMIZATION", "OPTIMIZE", "OUT", "OVERRIDING", "PACKAGE", "PARAMETER", "PART", "PARTITION", "PATH", "PIECESIZE", "PLAN", "PRIQTY", "PROGRAM", "PSID", "QUERYNO", "READS", "RECOVERY", "REFERENCING", "RELEASE", "RENAME", "REPEAT", "RESET", "RESIGNAL", "RESTART", "RESULT", "RESULT_SET_LOCATOR", "RETURN", "RETURNS", "ROUTINE", "ROW", "RRN", "RUN", "SAVEPOINT", "SCRATCHPAD", "SECONDS", "SECQTY", "SECURITY", "SENSITIVE", "SIGNAL", "SIMPLE", "SOURCE", "SPECIFIC", "SQLID", "STANDARD", "START", "STATIC", "STAY", "STOGROUP", "STORES", "STYLE", "SUBPAGES", "SYNONYM", "SYSFUN", "SYSIBM", "SYSPROC", "SYSTEM", "TABLESPACE", "TRIGGER", "TYPE", "UNDO", "UNTIL", "VALIDPROC", "VARIABLE", "VARIANT", "VCAT", "VOLUMES", "WHILE", "WLM", "YEARS"]
```
[NEXT-23](#23-to-get-the-current-setting-of-an-attribute)

----
### 21. to connect

CLI API functions have suffixes to indicate the format of their string arguments: those that accept Unicode end in W, and those that accept EBCDIC have no suffix.
This is how we have to interpret the [`SQLConnectW` API](https://www.ibm.com/docs/en/i/7.4?topic=functions-sqlconnect-connect-data-source):

``` C
SQLRETURN SQLConnectW (SQLHDBC          hdbc,
                       SQLWCHAR         *szDSN,
                       SQLSMALLINT      cbDSN,
                       SQLWCHAR         *szUID,
                       SQLSMALLINT      cbUID,
                       SQLWCHAR         *szAuthStr,
                       SQLSMALLINT      cbAuthStr);
```

Note that passing **SQL_NTS** (-3 = 0xFFFD) stands for *Null Terminated String* and could be passed for the SQLSMALLINTs required.

One of the aspects that I prefers of Ruby is the support for different encodings.
The **UTF\-16BE** one will directly support our needs with SQL Wide APIs.

Let us prepare the argument list types:
 
| type         | value | hex     |
| ------------ |:-----:| ------- |
|  ARG_INT32   | -5    |  0xFFFB |  
|  ARG_MEMPTR  | -11   |  0xFFF5 | 
|  ARG_INT16   | -3    |  0xFFFD |  
|  ARG_MEMPTR  | -11   |  0xFFF5 | 
|  ARG_INT16   | -3    |  0xFFFD |  
|  ARG_MEMPTR  | -11   |  0xFFF5 | 
|  ARG_INT16   | -3    |  0xFFFD |  
|  ARG_END     | 0     |  0x0000 | 

 
The use of memory for argument list with alignments follows:

```
     | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | A | B | C | D | E | F |
| 2x |    h d b c    |-----------------------------------------------|
| 3x |                   *   s   z   D   S   N                       |
| 4x | cbDSN |-------------------------------------------------------|
| 5x |                   *   s   z   U   I   D                       |
| 6x | cbUID |-------------------------------------------------------|
| 7x |                   * s z A u t h S t r                         |
| 8x | cbAut |-------------------------------------------------------|

```

The [new script](invoke_SQLConnectW.rb) builds on top of the previous one adding the first usage of a Wide API. 

A crucial role has the setting of the DNS that is simply a matter of proper encoding: 

``` ruby
dsn = '*LOCAL'.encode('UTF-16BE')
ILEarguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
ILEarguments[  32,  4] = dbc_handle[ 0, 4]               # hdbc
ILEarguments[  36, 12] = ['0'.rjust(24,'0')].pack("H*")  # padding
ILEarguments[  48, 16] = [Fiddle::Pointer[dsn].to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  64,  2] = ['FFFD'].pack("H*")             # SQL_NTS
```

```
bash-4.4$ invoke_SQLConnectW.rb
Environment handle 0x00000001
DB Connection handle 0x00000002
 0 1 2 3 4 5 6 7 8 9 A B C D E F
00000000000000000000000000000000
00000000000000000000000000000000
00000002000000000000000000000000
800000000000000000008016b26766f0
fffd0000000000000000000000000000
80000000000000000000000000000000
fffd0000000000000000000000000000
80000000000000000000000000000000
fffd0000000000000000000000000000
```

[NEXT-22](#22-to-get-info-about-the-dbms)

----
### 20. to increase our confidence

Our plan is to access DB2 by means of ILE SQL CLI APIs as provided by QSYS/QSQCLI service program preferring Wide APIs when available.
This means -for example- that as soon as in the previous chapter sorted listing we got:

```
QSQCLI    QSYS      *NO       SQLColAttribute
QSQCLI    QSYS      *NO       SQLColAttributeW
```

we will prefer adopting `SQLColAttributeW` rather than `SQLColAttribute`. 
It is obvious that for those APIs that are not handling strings of chars there will only be one template (e.g.: `SQLAllocHandle`).

We will also focus -pretty soon- on a solid error message handling because it will be very useful in inspecting our DB2 integration attempts.

Given these initial objectives let us start by studying the [SQLAllocHandle API](https://www.ibm.com/docs/en/i/7.4?topic=functions-sqlallochandle-allocate-handle). 

``` C
SQLRETURN SQLAllocHandle (SQLSMALLINT htype,
                          SQLINTEGER ihandle,
                          SQLINTEGER *handle);
```

It will offer a valid alternative to SQLAllocEnv(), SQLAllocConnect(), and SQLAllocStmt() functions.

The *htype* is a **SQLSMALLINT**. To identify the actual values associated to the constants in IBM documents we can browse the **QSYSINC/H(SQLCLI)** member source file:

```
 Columns . . . :    1  71           Browse                            QSYSINC/H
 SEU==>                                                                  SQLCLI
 FMT **  ...+... 1 ...+... 2 ...+... 3 ...+... 4 ...+... 5 ...+... 6 ...+... 7 
        *************** Beginning of data *************************************
  . . .      
0008.14 #define SQL_HANDLE_ENV                         1   
0008.15 #define SQL_HANDLE_DBC                         2   
0008.16 #define SQL_HANDLE_STMT                        3   
0008.17 #define SQL_HANDLE_DESC                        4   
0008.18 #define SQL_NULL_HANDLE                        0           
```

We can derive this useful table:

| handle type       | value | alternative        |
| ----------------- |:-----:| ------------------ |
| SQL\_HANDLE\_ENV  |   1   | SQLAllocEnv()      |
| SQL\_HANDLE\_DBC  |   2   | SQLAllocConnect()  |
| SQL\_HANDLE\_STMT |   3   | SQLAllocStmt()     |
| SQL\_HANDLE\_DESC |   4   |                    |


We can also verify that **SQLINTEGER** is a 32-bit integer and we need to arrange for proper alignments (refer to [Chapter 8](#8-to-execute-a-service-program-entry-call-from-pase) for details).

These are the types involved in defining the argument list:

| type         | value | hex     |
| ------------ |:-----:| ------- |
|  ARG_INT16   | -3    |  0xFFFD |  
|  ARG_INT32   | -5    |  0xFFFB |  
|  ARG_MEMPTR  | -11   |  0xFFF5 | 
|  ARG_END     | 0     |  0x0000 | 


Use of memory for argument list with alignments:

```
     | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | A | B | C | D | E | F |
| 2x | htype |-------|   ihandle     |-------------------------------|
| 3x |                   *   h   a   n   d   l   e                   |

```

We also collect information on return codes (type SQLINTEGER, RESULT_INT32 (-5)):

| return code          | value | 
| -------------------- |:-----:| 
| SQL\_SUCCESS         |   0   | 
| SQL\_ERROR           |  -1   |
| SQL\_INVALID\_HANDLE |  -2   |

The [resulting script](invoke_SQLAllocHandle.rb) will test the sequence of successful allocation for an Environment handle and a DB Connection one. 

A simple -but relevant- step forward in DB2 integration from Ruby!

```
bash-4.4$ invoke_SQLAllocHandle.rb
 0 1 2 3 4 5 6 7 8 9 A B C D E F
00000000000000000000000000000000
00000000000000000000000000000000
00000001000000000000000000000000
800000000000000000008016b2662390
Environment handle 0x00000001
 0 1 2 3 4 5 6 7 8 9 A B C D E F
00000000000000000000000000000000
00000000000000000000000000000000
00000002000000010000000000000000
800000000000000000008016b2673d10
DB Connection handle 0x00000002
```
[NEXT-21](#21-to-connect)

----
### 19. to pretend we do not care

Sooner or later we come to a central question: how do we access the **integrated database management system** (*DBMS*) provided by IBM i?
 
Ruby is an interpreted language and we start -again- wondering which can be the most basic but powerful way to dynamically interact with DB2 services. 

The **SQL Call Level Interface** imposes itself:

* it is based on an ISO (International Organization for Standardization) and IEC (International Electrotechnical Commission) joint standard (In 1994 control over the standard was transferred to the X/Open company)

In a future chapter we will investigate other options.

Years ago (2013) *Tom Liotta* published -for Code400.com's *Tips for the IBMi* forum- an ILE CL example to highlight the use of SQL CLI APIs. If you compile it, you will soon discover that the program object being generated references **QSYS/QSQCLI** service program. Despite the fact that a shared library is provided within PASE (`libdb400.a`) 
we will stick to a direct dynamic approach given the fluency we gained with previous Ruby scripts.

This chapter will again show case how useful is Ruby in understanding the internals of PASE-to-ILE integration.      

In a previous chapter we developed a tool that is useful again:

```
bash-4.4$ playing_with_api_and_spaces.rb QSQCLI | sort
QSQCLI    QSYS      *NO       SQLAllocConnect
QSQCLI    QSYS      *NO       SQLAllocEnv
QSQCLI    QSYS      *NO       SQLAllocHandle
QSQCLI    QSYS      *NO       SQLAllocStmt
QSQCLI    QSYS      *NO       SQLBindCol
QSQCLI    QSYS      *NO       SQLBindFileToCol
QSQCLI    QSYS      *NO       SQLBindFileToParam
QSQCLI    QSYS      *NO       SQLBindParam
QSQCLI    QSYS      *NO       SQLBindParameter
QSQCLI    QSYS      *NO       SQLCancel
QSQCLI    QSYS      *NO       SQLCloseCursor
QSQCLI    QSYS      *NO       SQLColAttribute
QSQCLI    QSYS      *NO       SQLColAttributeW
QSQCLI    QSYS      *NO       SQLColAttributes
QSQCLI    QSYS      *NO       SQLColAttributesW
QSQCLI    QSYS      *NO       SQLColumnPrivileges
QSQCLI    QSYS      *NO       SQLColumnPrivilegesW
QSQCLI    QSYS      *NO       SQLColumns
QSQCLI    QSYS      *NO       SQLColumnsW
QSQCLI    QSYS      *NO       SQLConnect
QSQCLI    QSYS      *NO       SQLConnectW
QSQCLI    QSYS      *NO       SQLCopyDesc
QSQCLI    QSYS      *NO       SQLDataSources
QSQCLI    QSYS      *NO       SQLDataSourcesW
QSQCLI    QSYS      *NO       SQLDescribeCol
QSQCLI    QSYS      *NO       SQLDescribeColW
QSQCLI    QSYS      *NO       SQLDescribeParam
QSQCLI    QSYS      *NO       SQLDisconnect
QSQCLI    QSYS      *NO       SQLDriverConnect
QSQCLI    QSYS      *NO       SQLDriverConnectW
QSQCLI    QSYS      *NO       SQLEndTran
QSQCLI    QSYS      *NO       SQLError
QSQCLI    QSYS      *NO       SQLErrorW
QSQCLI    QSYS      *NO       SQLExecDirect
QSQCLI    QSYS      *NO       SQLExecDirectW
QSQCLI    QSYS      *NO       SQLExecute
QSQCLI    QSYS      *NO       SQLExtendedFetch
QSQCLI    QSYS      *NO       SQLFetch
QSQCLI    QSYS      *NO       SQLFetchScroll
QSQCLI    QSYS      *NO       SQLForeignKeys
QSQCLI    QSYS      *NO       SQLForeignKeysW
QSQCLI    QSYS      *NO       SQLFreeConnect
QSQCLI    QSYS      *NO       SQLFreeEnv
QSQCLI    QSYS      *NO       SQLFreeHandle
QSQCLI    QSYS      *NO       SQLFreeStmt
QSQCLI    QSYS      *NO       SQLGetCol
QSQCLI    QSYS      *NO       SQLGetConnectAttr
QSQCLI    QSYS      *NO       SQLGetConnectAttrW
QSQCLI    QSYS      *NO       SQLGetConnectOption
QSQCLI    QSYS      *NO       SQLGetConnectOptionW
QSQCLI    QSYS      *NO       SQLGetCursorName
QSQCLI    QSYS      *NO       SQLGetCursorNameW
QSQCLI    QSYS      *NO       SQLGetData
QSQCLI    QSYS      *NO       SQLGetDescField
QSQCLI    QSYS      *NO       SQLGetDescFieldW
QSQCLI    QSYS      *NO       SQLGetDescRec
QSQCLI    QSYS      *NO       SQLGetDescRecW
QSQCLI    QSYS      *NO       SQLGetDiagField
QSQCLI    QSYS      *NO       SQLGetDiagFieldW
QSQCLI    QSYS      *NO       SQLGetDiagRec
QSQCLI    QSYS      *NO       SQLGetDiagRecW
QSQCLI    QSYS      *NO       SQLGetEnvAttr
QSQCLI    QSYS      *NO       SQLGetFunctions
QSQCLI    QSYS      *NO       SQLGetInfo
QSQCLI    QSYS      *NO       SQLGetInfoW
QSQCLI    QSYS      *NO       SQLGetLength
QSQCLI    QSYS      *NO       SQLGetPosition
QSQCLI    QSYS      *NO       SQLGetPositionW
QSQCLI    QSYS      *NO       SQLGetStmtAttr
QSQCLI    QSYS      *NO       SQLGetStmtAttrW
QSQCLI    QSYS      *NO       SQLGetStmtOption
QSQCLI    QSYS      *NO       SQLGetStmtOptionW
QSQCLI    QSYS      *NO       SQLGetSubString
QSQCLI    QSYS      *NO       SQLGetSubStringW
QSQCLI    QSYS      *NO       SQLGetTypeInfo
QSQCLI    QSYS      *NO       SQLGetTypeInfoW
QSQCLI    QSYS      *NO       SQLLanguages
QSQCLI    QSYS      *NO       SQLMoreResults
QSQCLI    QSYS      *NO       SQLNativeSql
QSQCLI    QSYS      *NO       SQLNativeSqlW
QSQCLI    QSYS      *NO       SQLNextResult
QSQCLI    QSYS      *NO       SQLNumParams
QSQCLI    QSYS      *NO       SQLNumResultCols
QSQCLI    QSYS      *NO       SQLParamData
QSQCLI    QSYS      *NO       SQLParamOptions
QSQCLI    QSYS      *NO       SQLPrepare
QSQCLI    QSYS      *NO       SQLPrepareW
QSQCLI    QSYS      *NO       SQLPrimaryKeys
QSQCLI    QSYS      *NO       SQLPrimaryKeysW
QSQCLI    QSYS      *NO       SQLProcedureColumns
QSQCLI    QSYS      *NO       SQLProcedureColumnsW
QSQCLI    QSYS      *NO       SQLProcedures
QSQCLI    QSYS      *NO       SQLProceduresW
QSQCLI    QSYS      *NO       SQLPutData
QSQCLI    QSYS      *NO       SQLReleaseEnv
QSQCLI    QSYS      *NO       SQLRowCount
QSQCLI    QSYS      *NO       SQLSetConnectAttr
QSQCLI    QSYS      *NO       SQLSetConnectAttrW
QSQCLI    QSYS      *NO       SQLSetConnectOption
QSQCLI    QSYS      *NO       SQLSetConnectOptionW
QSQCLI    QSYS      *NO       SQLSetCursorName
QSQCLI    QSYS      *NO       SQLSetCursorNameW
QSQCLI    QSYS      *NO       SQLSetDescField
QSQCLI    QSYS      *NO       SQLSetDescFieldW
QSQCLI    QSYS      *NO       SQLSetDescRec
QSQCLI    QSYS      *NO       SQLSetEnvAttr
QSQCLI    QSYS      *NO       SQLSetParam
QSQCLI    QSYS      *NO       SQLSetStmtAttr
QSQCLI    QSYS      *NO       SQLSetStmtAttrW
QSQCLI    QSYS      *NO       SQLSetStmtOption
QSQCLI    QSYS      *NO       SQLSetStmtOptionW
QSQCLI    QSYS      *NO       SQLSpecialColumns
QSQCLI    QSYS      *NO       SQLSpecialColumnsW
QSQCLI    QSYS      *NO       SQLStartTran
QSQCLI    QSYS      *NO       SQLStatistics
QSQCLI    QSYS      *NO       SQLStatisticsW
QSQCLI    QSYS      *NO       SQLTablePrivileges
QSQCLI    QSYS      *NO       SQLTablePrivilegesW
QSQCLI    QSYS      *NO       SQLTables
QSQCLI    QSYS      *NO       SQLTablesW
QSQCLI    QSYS      *NO       SQLTransact$
```

If we execute, and filter, the following dump:

```
$ dump -X64 -Tv /QOpenSys/usr/lib/libdb400.a | grep SQL
[34]    0x000020a8    .data      EXP     DS SECdef        [noIMid] SQLTransact
[35]    0x00002108    .data      EXP     DS SECdef        [noIMid] SQLTables
[36]    0x00002120    .data      EXP     DS SECdef        [noIMid] SQLTablePrivileges
[37]    0x00002138    .data      EXP     DS SECdef        [noIMid] SQLStatistics
[38]    0x00002150    .data      EXP     DS SECdef        [noIMid] SQLStartTran
[39]    0x00002168    .data      EXP     DS SECdef        [noIMid] SQLSpecialColumns
[40]    0x00002180    .data      EXP     DS SECdef        [noIMid] SQLSetStmtOption
[41]    0x00002198    .data      EXP     DS SECdef        [noIMid] SQLSetStmtAttr
[42]    0x000021b0    .data      EXP     DS SECdef        [noIMid] SQLSetParam
[43]    0x000021c8    .data      EXP     DS SECdef        [noIMid] SQLSetEnvAttr
[44]    0x000021e0    .data      EXP     DS SECdef        [noIMid] SQLSetDescRec
[45]    0x000021f8    .data      EXP     DS SECdef        [noIMid] SQLSetDescField
[46]    0x00002210    .data      EXP     DS SECdef        [noIMid] SQLSetCursorName
[47]    0x00002228    .data      EXP     DS SECdef        [noIMid] SQLSetConnectOption
[48]    0x00002240    .data      EXP     DS SECdef        [noIMid] SQLSetConnectAttr
[49]    0x00002258    .data      EXP     DS SECdef        [noIMid] SQLRowCount
[50]    0x00002270    .data      EXP     DS SECdef        [noIMid] SQLReleaseEnv
[51]    0x00002288    .data      EXP     DS SECdef        [noIMid] SQLPutData
[52]    0x000022a0    .data      EXP     DS SECdef        [noIMid] SQLProcedures
[53]    0x000022b8    .data      EXP     DS SECdef        [noIMid] SQLProcedureColumns
[54]    0x000022d0    .data      EXP     DS SECdef        [noIMid] SQLPrimaryKeys
[55]    0x000022e8    .data      EXP     DS SECdef        [noIMid] SQLPrepare
[56]    0x00002300    .data      EXP     DS SECdef        [noIMid] SQLParamOptions
[57]    0x00002318    .data      EXP     DS SECdef        [noIMid] SQLParamData
[58]    0x00002330    .data      EXP     DS SECdef        [noIMid] SQLNumResultCols
[59]    0x00002348    .data      EXP     DS SECdef        [noIMid] SQLNumParams
[60]    0x00002360    .data      EXP     DS SECdef        [noIMid] SQLNextResult
[61]    0x00002378    .data      EXP     DS SECdef        [noIMid] SQLNativeSql
[62]    0x00002390    .data      EXP     DS SECdef        [noIMid] SQLMoreResults
[63]    0x000023a8    .data      EXP     DS SECdef        [noIMid] SQLLanguages
[64]    0x000023c0    .data      EXP     DS SECdef        [noIMid] SQLGetTypeInfo
[65]    0x000023d8    .data      EXP     DS SECdef        [noIMid] SQLGetSubString
[66]    0x000023f0    .data      EXP     DS SECdef        [noIMid] SQLGetStmtOption
[67]    0x00002408    .data      EXP     DS SECdef        [noIMid] SQLGetStmtAttr
[68]    0x00002420    .data      EXP     DS SECdef        [noIMid] SQLGetPosition
[69]    0x00002438    .data      EXP     DS SECdef        [noIMid] SQLGetLength
[70]    0x00002450    .data      EXP     DS SECdef        [noIMid] SQLGetInfo
[71]    0x00002468    .data      EXP     DS SECdef        [noIMid] SQLGetFunctions
[72]    0x00002480    .data      EXP     DS SECdef        [noIMid] SQLGetEnvAttr
[73]    0x00002498    .data      EXP     DS SECdef        [noIMid] SQLGetDiagRec
[74]    0x000024b0    .data      EXP     DS SECdef        [noIMid] SQLGetDiagField
[75]    0x000024c8    .data      EXP     DS SECdef        [noIMid] SQLGetDescRec
[76]    0x000024e0    .data      EXP     DS SECdef        [noIMid] SQLGetDescField
[77]    0x000024f8    .data      EXP     DS SECdef        [noIMid] SQLGetData
[78]    0x00002510    .data      EXP     DS SECdef        [noIMid] SQLGetCursorName
[79]    0x00002528    .data      EXP     DS SECdef        [noIMid] SQLGetConnectOption
[80]    0x00002540    .data      EXP     DS SECdef        [noIMid] SQLGetConnectAttr
[81]    0x00002558    .data      EXP     DS SECdef        [noIMid] SQLGetCol
[82]    0x00002570    .data      EXP     DS SECdef        [noIMid] SQLFreeHandle
[83]    0x00002588    .data      EXP     DS SECdef        [noIMid] SQLFreeStmt
[84]    0x000025a0    .data      EXP     DS SECdef        [noIMid] SQLFreeEnv
[85]    0x000025b8    .data      EXP     DS SECdef        [noIMid] SQLFreeConnect
[86]    0x000025d0    .data      EXP     DS SECdef        [noIMid] SQLForeignKeys
[87]    0x000025e8    .data      EXP     DS SECdef        [noIMid] SQLFetchScroll
[88]    0x00002600    .data      EXP     DS SECdef        [noIMid] SQLFetch
[89]    0x00002618    .data      EXP     DS SECdef        [noIMid] SQLExtendedFetch
[90]    0x00002630    .data      EXP     DS SECdef        [noIMid] SQLExecute
[91]    0x00002648    .data      EXP     DS SECdef        [noIMid] SQLExecDirect
[92]    0x00002660    .data      EXP     DS SECdef        [noIMid] SQLError
[93]    0x00002678    .data      EXP     DS SECdef        [noIMid] SQLEndTran
[94]    0x00002690    .data      EXP     DS SECdef        [noIMid] SQLDriverConnect
[95]    0x000026a8    .data      EXP     DS SECdef        [noIMid] SQLDisconnect
[96]    0x000026c0    .data      EXP     DS SECdef        [noIMid] SQLDescribeParam
[97]    0x000026d8    .data      EXP     DS SECdef        [noIMid] SQLDescribeCol
[98]    0x000026f0    .data      EXP     DS SECdef        [noIMid] SQLDataSources
[99]    0x00002708    .data      EXP     DS SECdef        [noIMid] SQLCopyDesc
[100]   0x00002720    .data      EXP     DS SECdef        [noIMid] SQLConnect
[101]   0x00002738    .data      EXP     DS SECdef        [noIMid] SQLColumns
[102]   0x00002750    .data      EXP     DS SECdef        [noIMid] SQLColumnPrivileges
[103]   0x00002768    .data      EXP     DS SECdef        [noIMid] SQLColAttributes
[104]   0x00002780    .data      EXP     DS SECdef        [noIMid] SQLCloseCursor
[105]   0x00002798    .data      EXP     DS SECdef        [noIMid] SQLCancel
[106]   0x000027b0    .data      EXP     DS SECdef        [noIMid] SQLBindParameter
[107]   0x000027c8    .data      EXP     DS SECdef        [noIMid] SQLBindParam
[108]   0x000027e0    .data      EXP     DS SECdef        [noIMid] SQLBindFileToParam
[109]   0x000027f8    .data      EXP     DS SECdef        [noIMid] SQLBindFileToCol
[110]   0x00002810    .data      EXP     DS SECdef        [noIMid] SQLBindCol
[111]   0x00002828    .data      EXP     DS SECdef        [noIMid] SQLAllocStmt
[112]   0x00002840    .data      EXP     DS SECdef        [noIMid] SQLAllocHandle
[113]   0x00002858    .data      EXP     DS SECdef        [noIMid] SQLAllocEnv
[114]   0x00002870    .data      EXP     DS SECdef        [noIMid] SQLAllocConnect
[115]   0x00002888    .data      EXP     DS SECdef        [noIMid] SQLOverrideCCSID400
$
```

We discover that *libdb400.a* -although providing other useful features- has never been updated to support **SQL Wide APIs**.
These considerations will be the starting point for a series of chapters. Stay tuned! 

[NEXT-20](#20-to-increase-our-confidence)

----
### 18. to retrieve command definition

Another interesting API is **QCDRCMDD**. It renders CMD definitions in **XML** and **UTF-8** encoding: we are at home with Ruby that offers a pre-included support for XML in its standard library. 

Have a look at the [Ruby source code](inspecting_command.rb): this is the output of the `inspecting_command.rb power_ruby railsnew` request.

``` xml
<QcdCLCmd DTDVersion='1.0'>
  <Cmd CmdName='RAILSNEW' CmdLib='POWER_RUBY' CCSID='37' MaxPos='99' Prompt='Simplify usage of Rails new' MsgF='QCPFMSG' MsgFLib='__LIBL' ExecBatch='YES' ChgCmdExit='NO' RtvCmdExit='NO'>
    <Parm Kwd='RAILSAPP' PosNbr='1' KeyParm='NO' Type='CHAR' Min='1' Max='1' Prompt='New Rails Application Name' Len='24' Rstd='NO' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='YES' Choice='Character value'/>
    <Parm Kwd='HTTPSRV' PosNbr='2' KeyParm='NO' Type='CHAR' Min='1' Max='1' Prompt='Apache HTTP Instance' Len='10' Rstd='NO' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='YES' Choice='Character value'/>
    <Parm Kwd='EXTPORT' PosNbr='3' KeyParm='NO' Type='DEC' Min='1' Max='1' Prompt='Apache Instance Port' Len='5.0' Rstd='NO' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='YES' Choice='Number'/>
    <Parm Kwd='INTPORT' PosNbr='4' KeyParm='NO' Type='DEC' Min='1' Max='1' Prompt='Ruby Web Server Port' Len='5.0' Rstd='NO' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='YES' Choice='Number'/>
    <Parm Kwd='CRT' PosNbr='5' KeyParm='NO' Type='CHAR' Min='0' Max='1' Prompt='Creation mode' Len='1' Rstd='YES' Dft='*NEW' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='YES' Choice='*NEW, *NONE, *GITHUB'>
      <SpcVal>
        <Value Val='*NEW' MapTo='Y'/>
        <Value Val='*NONE' MapTo='N'/>
        <Value Val='*GITHUB' MapTo='G'/>
      </SpcVal>
    </Parm>
    <Parm Kwd='ENV' PosNbr='6' KeyParm='NO' PmtCtl='PMTCTL' Type='CHAR' Min='0' Max='1' Prompt='Rails Execution Environment' Len='1' Rstd='YES' Dft='*DEVELOPMENT' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='YES' Choice='*DEVELOPMENT'>
      <SpcVal>
        <Value Val='*DEVELOPMENT' MapTo='D'/>
      </SpcVal>
      <PmtCtl CtlKwd='CRT' NbrTrueRel='EQ' NbrTrue='1'>
        <PmtCtlCond Rel='EQ' CmpVal='Y'/>
      </PmtCtl>
    </Parm>
    <Parm Kwd='VRM' PosNbr='7' KeyParm='NO' PmtCtl='PMTCTL' Type='CHAR' Min='0' Max='1' Prompt='Ruby Version' Len='7' Rstd='YES' Dft='*V24' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='YES' Choice='*V24, *V23, *V22, *V21'>
      <SpcVal>
        <Value Val='*V24' MapTo='V2R4   '/>
        <Value Val='*V23' MapTo='V2R3   '/>
        <Value Val='*V22' MapTo='V2R2   '/>
        <Value Val='*V21' MapTo='V2R1   '/>
      </SpcVal>
      <PmtCtl CtlKwd='CRT' NbrTrueRel='EQ' NbrTrue='1'>
        <PmtCtlCond Rel='EQ' CmpVal='Y'/>
      </PmtCtl>
    </Parm>
    <Parm Kwd='DRIVER' PosNbr='8' KeyParm='NO' PmtCtl='PMTCTL' Type='CHAR' Min='0' Max='1' Prompt='Rails Database Adapter' Len='1' Rstd='YES' Dft='*SQLITE3' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='YES' Choice='*IRUBYDB, *IBM_DB, *SQLITE3'>
      <SpcVal>
        <Value Val='*IRUBYDB' MapTo='R'/>
        <Value Val='&apos;*IBM_DB&apos;' MapTo='I'/>
        <Value Val='*SQLITE3' MapTo='L'/>
      </SpcVal>
      <PmtCtl CtlKwd='CRT' NbrTrueRel='EQ' NbrTrue='1'>
        <PmtCtlCond Rel='EQ' CmpVal='Y'/>
      </PmtCtl>
    </Parm>
    <Parm Kwd='GTUSR' PosNbr='9' KeyParm='NO' PmtCtl='PMTCTL' Type='CHAR' Min='0' Max='1' Prompt='GitHub: username' Len='20' Rstd='NO' Dft='X&apos;&apos;' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='YES' Choice='Character value'>
      <PmtCtl CtlKwd='CRT' NbrTrueRel='EQ' NbrTrue='1'>
        <PmtCtlCond Rel='EQ' CmpVal='G'/>
      </PmtCtl>
    </Parm>
    <Parm Kwd='GTPASS' PosNbr='10' KeyParm='NO' PmtCtl='PMTCTL' Type='CHAR' Min='0' Max='1' Prompt='GitHub: password' Len='20' Rstd='NO' Dft='X&apos;&apos;' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='NO' Choice='Character value'>
      <PmtCtl CtlKwd='CRT' NbrTrueRel='EQ' NbrTrue='1'>
        <PmtCtlCond Rel='EQ' CmpVal='G'/>
      </PmtCtl>
    </Parm>
    <Parm Kwd='GTSRC' PosNbr='11' KeyParm='NO' PmtCtl='PMTCTL' Type='CHAR' Min='0' Max='1' Prompt='GitHub: PowerRuby: project' Len='20' Rstd='NO' Dft='&apos;DE_train_01&apos;' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='YES' Choice='Character value'>
      <PmtCtl CtlKwd='CRT' NbrTrueRel='EQ' NbrTrue='1'>
        <PmtCtlCond Rel='EQ' CmpVal='G'/>
      </PmtCtl>
    </Parm>
    <Parm Kwd='DBUSR' PosNbr='12' KeyParm='NO' PmtCtl='PMTCTL' Type='CHAR' Min='0' Max='1' Prompt='ibm_db: username' Len='10' Rstd='NO' Dft='X&apos;&apos;' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='YES' Choice='Character value'>
      <PmtCtl CtlKwd='DRIVER' NbrTrueRel='EQ' NbrTrue='1'>
        <PmtCtlCond Rel='EQ' CmpVal='I'/>
      </PmtCtl>
    </Parm>
    <Parm Kwd='DBPASS' PosNbr='13' KeyParm='NO' PmtCtl='PMTCTL' Type='CHAR' Min='0' Max='1' Prompt='ibm_db: password' Len='10' Rstd='NO' Dft='X&apos;&apos;' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='NO' Choice='Character value'>
      <PmtCtl CtlKwd='DRIVER' NbrTrueRel='EQ' NbrTrue='1'>
        <PmtCtlCond Rel='EQ' CmpVal='I'/>
      </PmtCtl>
    </Parm>
    <Parm Kwd='DBROOT' PosNbr='14' KeyParm='NO' PmtCtl='PMTCTL' Type='CHAR' Min='0' Max='1' Prompt='ibm_db: schema root' Len='8' Rstd='NO' Dft='X&apos;&apos;' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='YES' Choice='Character value'>
      <PmtCtl CtlKwd='DRIVER' NbrTrueRel='EQ' NbrTrue='1'>
        <PmtCtlCond Rel='EQ' CmpVal='I'/>
      </PmtCtl>
    </Parm>
    <Parm Kwd='EXTPATH' PosNbr='15' KeyParm='NO' PmtCtl='PMTCTL' Type='CHAR' Min='0' Max='1' Prompt='HTTP Proxy External Path' Len='20' Rstd='NO' Dft='X&apos;&apos;' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='YES' Choice='Character value'>
      <PmtCtl CtlKwd='DRIVER' NbrTrueRel='EQ' NbrTrue='1'>
        <PmtCtlCond Rel='EQ' CmpVal='Z'/>
      </PmtCtl>
    </Parm>
    <Parm Kwd='INTPATH' PosNbr='16' KeyParm='NO' PmtCtl='PMTCTL' Type='CHAR' Min='0' Max='1' Prompt='HTTP Proxy Internal Path' Len='20' Rstd='NO' Dft='X&apos;&apos;' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='YES' Choice='Character value'>
      <PmtCtl CtlKwd='DRIVER' NbrTrueRel='EQ' NbrTrue='1'>
        <PmtCtlCond Rel='EQ' CmpVal='Z'/>
      </PmtCtl>
    </Parm>
    <Parm Kwd='PLACE' PosNbr='17' KeyParm='NO' PmtCtl='PMTCTL' Type='CHAR' Min='0' Max='1' Prompt='Application Folder Location' Len='1' Rstd='YES' Dft='*WWW' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='YES' Choice='*HOME, *WWW'>
      <SpcVal>
        <Value Val='*HOME' MapTo='H'/>
        <Value Val='*WWW' MapTo='W'/>
      </SpcVal>
      <PmtCtl CtlKwd='DRIVER' NbrTrueRel='EQ' NbrTrue='1'>
        <PmtCtlCond Rel='EQ' CmpVal='Z'/>
      </PmtCtl>
    </Parm>
    <Parm Kwd='WEBCON' PosNbr='18' KeyParm='NO' PmtCtl='PMTCTL' Type='CHAR' Min='0' Max='1' Prompt='With WebConsole' Len='1' Rstd='YES' Dft='*NO' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='YES' Choice='*YES, *NO'>
      <SpcVal>
        <Value Val='*YES' MapTo='Y'/>
        <Value Val='*NO' MapTo='N'/>
      </SpcVal>
      <PmtCtl CtlKwd='DRIVER' NbrTrueRel='EQ' NbrTrue='1'>
        <PmtCtlCond Rel='EQ' CmpVal='Z'/>
      </PmtCtl>
    </Parm>
    <Parm Kwd='PID' PosNbr='19' KeyParm='NO' PmtCtl='PMTCTL' Type='CHAR' Min='0' Max='1' Prompt='Named instance' Len='12' Rstd='NO' Dft='&apos;server&apos;' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='YES' Choice='Character value'>
      <PmtCtl CtlKwd='DRIVER' NbrTrueRel='EQ' NbrTrue='1'>
        <PmtCtlCond Rel='EQ' CmpVal='Z'/>
      </PmtCtl>
    </Parm>
    <Parm Kwd='LIB' PosNbr='20' KeyParm='NO' PmtCtl='PMTCTL' Type='CHAR' Min='0' Max='1' Prompt='Library' Len='10' Rstd='NO' Dft='&apos;POWER_RUBY&apos;' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='YES' Choice='Character value'>
      <PmtCtl CtlKwd='DRIVER' NbrTrueRel='EQ' NbrTrue='1'>
        <PmtCtlCond Rel='EQ' CmpVal='Z'/>
      </PmtCtl>
    </Parm>
    <Parm Kwd='MSGQ' PosNbr='21' KeyParm='NO' PmtCtl='PMTCTL' Type='CHAR' Min='0' Max='1' Prompt='Message Queue' Len='10' Rstd='NO' Dft='&apos;PRUBY_MSGQ&apos;' AlwUnprt='YES' AlwVar='YES' Expr='NO' Full='NO' DspInput='YES' Choice='Character value'>
      <PmtCtl CtlKwd='DRIVER' NbrTrueRel='EQ' NbrTrue='1'>
        <PmtCtlCond Rel='EQ' CmpVal='Z'/>
      </PmtCtl>
    </Parm>
  </Cmd>
```

[NEXT-19](#19-to-pretend-we-do-not-care)

----
### 17. to retrieve job attributes

Another example of API is **QUSRJOBI**: we can use it to retrieve information about the job running.
Obviously each time we call [a Ruby script](playing_with_job_attributes.rb) for execution from **bash** (or any other shell) we are actually creating a new process (job): that is why we will see the job number incremented repeating the execution.

```
bash-5.0$ playing_with_job_attributes.rb
Number of bytes returned  = 86
Number of bytes available = 86
Job name                  = JUPYTERLAB
User name                 = JUPYTER   
Job number                = 293334
Internal job identifier   = 0x02e4000100190f00a60f4f1b0d4d0001
Job status                = *ACTIVE   
Job type                  = B
Job subtype               = D
Reserved                  = 
Run priority (job)        = 50
Time slice                = 2000
Default wait              = 30
Purge                     = *YES      

bash-5.0$ playing_with_job_attributes.rb
Number of bytes returned  = 86
Number of bytes available = 86
Job name                  = JUPYTERLAB
User name                 = JUPYTER   
Job number                = 293335
Internal job identifier   = 0x02e4000100190f00a60f4f1c9186f001
Job status                = *ACTIVE   
Job type                  = B
Job subtype               = D
Reserved                  = 
Run priority (job)        = 50
Time slice                = 2000
Default wait              = 30
Purge                     = *YES   
```

From the following table we can deduce that our script executes as a **Batch Immediate**.

 **WRKACTJOB and QUSRJOBI API Comparison** 

| Job Type Field                                      | Job Type   | Job Subtype |
| --------------------------------------------------- | ---------- | ----------- |
| ASJ (Autostart)                                     | A          | blank       | 
| BCH (Batch)                                         | B          | blank       | 
| BCI (Batch immediate)                               | B          | D           | 
| EVK (Started by a program start request)            | B          | E           |
| M36 (System i™ Advanced 36® machine server)         | B          | F           |
| PJ (Prestart job)                                   | B          | J           |
| MRT (Multiple requester terminal)                   | B          | T           |
| blank (Alternative user subtype--not an active job) | B          | U           |
| INT (Interactive)                                   | I          | blank       |
| SBS (Subsystem monitor)                             | M          | blank       |
| RDR (Reader)                                        | R          | blank       |
| SYS (System)                                        | S or X     | blank       |
| WTR (Writer)                                        | W          | blank       |
| PDJ (Print driver job)                              | W          | P           |

[NEXT-18](#18-to-retrieve-command-definition)

----
### 16. to have fun with QTEMP


Today we will experiment a tricky situation. 

**Machine interface** (*MI*) is the interface between the Operating System (IBM i) and the Licensed Internal Code (LIC). 
As soon as we know: 

* how to compile a program from Ruby using the instructive **Machine Interface** language (by means of native **QPRCRTPG** API)
* how to resolve a system pointer to a native object (the program being generated) and
* how to invoke such a program (by means of PASE **\_PGMCALL** API applied to the system pointer)

we could imagine to create a Ruby script that iterates over these steps.

We would like to verify if the context (library) of such an exploratory object can be **QTEMP** (this aspect should speed up our cycles and will guarantee a safer execution).

Let us test our concept with a MI program that receives a fixed number of integers, adds them all and returns the sum.
Imagine to iterate this cycle incrementing by one the numbers of arguments.
The meta program should fail when we reach the maximum number of arguments a program can accept when compiled (or the maximum that \_PGMCALL API can handle passing them through).

```
 5770SS1 V7R3M0 160422T                               Emissione generata                               19/03/21 18:55:52  Pag.     
   IDMSG   SEQ   Diagnostici                                                                                                       
* CPD6360 000514 Sono stati specificati più di 255 elementi nell'elenco degli operandi. Non devono superare 225. Probabile errore de 
l compilatore.                                                                                                    
```

The first limit to occur is the number of operands MI supports (**CPD6360**: *More than 255 elements specified in operand list. Must be 255 or less. Probable compiler error.*) 

These apparently useless tests help us confirm that the handling of pointers via Ruby is sufficiently safe to support our growing requirements.

The [Ruby script](playing_with_qtemp.rb) required to rename those variables that were capitalized (in Ruby this tags a **constant**).

```
bash-4.4$ playing_with_qtemp.rb 12
somma = 0
somma = 1
somma = 3
somma = 6
somma = 10
somma = 15
somma = 21
somma = 28
somma = 36
somma = 45
somma = 55
somma = 66
```

So we are calling an always-changing native program created from MI assembly. 
This is an example of code generation from Ruby targeting a specific syntax in IBM i.
This same approach could be adopted for CL, C, RPG, and many other languages.

As soon as many compilers are still using native source file members as input (*QPRCRTPG* is the exception) let us investigate 
the opportunities we have to read and/or write source files by means of API we could access from Ruby in PASE.
There has been a gradual evolution to IFS as an alternative source, particularly suited for tools like **make** and **git**). 

[NEXT-17](#17-to-retrieve-job-attributes)

----
### 15. to have fun by reliving old glories

Today I will play with a fashinating tool hidden among the thousands of resources IBM i still provides and that have roots in its past. I am referring to the [Create Program **QPRCRTPG** API](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/apis/qprcrtpg.htm). Now that we know how to use user spaces and APIs from Ruby we can also figure out how to build our own utility for offering an easier interface to this old glory.

The heart of [the new Ruby script](reliving_old_glories.rb) is copied here:

``` ruby
pQPRCRTPG  = ILEpointer.malloc
rc = rslobj2.call(pQPRCRTPG, 513, "QPRCRTPG", "QSYS")

argv = ILEparms.malloc
argv[   0, 8] = [Fiddle::Pointer[Intermediate_representation_of_the_program].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[   8, 8] = [Fiddle::Pointer[Length_of_intermediate_representation_of_program].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  16, 8] = [Fiddle::Pointer[Qualified_program_name].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  24, 8] = [Fiddle::Pointer[Program_text].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  32, 8] = [Fiddle::Pointer[Qualified_source_file_name].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  40, 8] = [Fiddle::Pointer[Source_file_member_information].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  48, 8] = [Fiddle::Pointer[Source_file_last_changed_date_and_time_information].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  56, 8] = [Fiddle::Pointer[Qualified_printer_file_name].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  64, 8] = [Fiddle::Pointer[Starting_page_number].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  72, 8] = [Fiddle::Pointer[Public_authority].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  80, 8] = [Fiddle::Pointer[Option_template].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  88, 8] = [Fiddle::Pointer[Number_of_option_template_entries].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  96, 8] = [pError.to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[ 104, 8] = ['0'.rjust(16,'0')].pack("H*")
rc = pgmcall.call(pQPRCRTPG, argv, 0)
```

Once arguments are prepared (in EBCDIC) their addresses (64bits) are orderly copied in the array of pointers that will be the second parameter passed to **\_PGMCALL**.

```
                         Gestione degli oggetti con il PDM            Sxxxxxxx
                                                                              
Libreria. . . . .   RIBY             Inizio elenco da. . . . . .              
                                     Inizio elenco da tipo . . .              
                                                                              
Immettere le opzioni e premere Invio.                                         
  2=Modifica     3=Copia       4=Cancellaz.  5=Visualiz.     7=Ridenominaz.   
  8=Visual. descrizione      9=Salvatag.  10=Ripristino   11=Trasferimento... 
                                                                              
Opz  Oggetto     Tipo        Attributo    Testo                               
     MISTPTR1    *PGM                    My first MI program                  
     RIBY_SRV    *SRVPGM     RPGLE                                            
```
The spool file we requested is available in our output queue:

```
                                                    Visualizzazione file di spool                                                  
File  . . . . . :   QPRINT                                                                               Pagina/Riga 1/1           
Controllo . . . .                                                                                        Colonne     1 - 130       
Ricerca . . . . .                                                                                                                  
*...+....1....+....2....+....3....+....4....+....5....+....6....+....7....+....8....+....9....+....0....+....1....+....2....+....3 
 5770SS1 V7R4M0 190621N                               Emissione generata                               12/03/21 13:54:43  Pag.     
  SEQ   ISTR Scost.    Codice generato    *... ... 1 ... ... 2 ... ... 3 ... ... 4 ... ... 5 ... ... 6 ... ... 7 ... ... 8   Inter 
 00001                                             DCL DD POINTERS CHAR(32) BDRY(16)                                     ;         
 00002                                             DCL SYSPTR .SYSPTR DEF(POINTERS) POS(1)                               ;         
 00003                                             DCL SPCPTR .SPCPTR DEF(POINTERS) POS(17)                              ;         
 00004  0001 000004  0022 0003 0002                SETSPPFP .SPCPTR, .SYSPTR                                             ;         
 00005  0002 00000A  0260                          PEND                                                                  ;         
 5770SS1 V7R4M0 190621N                               Emissione generata                               12/03/21 13:54:43  Pag.     
  IDMSG    ODT   Nome ODT                                          Semantici e diagnostici di sintassi ODT                         
 5770SS1 V7R4M0 190621N                               Emissione generata                               12/03/21 13:54:43  Pag.     
   IDMSG   Diagnostici semantici flusso istruzioni MI                                                                              
                                                                                                                                                                                                                                                                      
```

[NEXT-16](#16-to-have-fun-with-qtemp)

----
### 14. to put previous lessons into practice

In previous chapter we handled user spaces. They are a fundamental building block in using IBM i native APIs.
We are using previous knowledge to build a script that is gathering the list of APIs a SERVICE PROGRAM is offering.
For the job there is a native API (actually a program) named `QBNLSPGM`. 

The final behavior is the following:

```
bash-4.4$ playing_with_api_and_spaces.rb 
./playing_with_api_and_spaces.rb:6:in `<main>': Usage: playing_with_api_and_spaces.rb <srvpgm> (RuntimeError)

bash-4.4$ playing_with_api_and_spaces.rb QLEAWI
QLEAWI    QSYS      *NO       Q LE leDefaultEh
QLEAWI    QSYS      *NO       CEEMRCR
QLEAWI    QSYS      *NO       CEEMGET
QLEAWI    QSYS      *NO       CEEMOUT
QLEAWI    QSYS      *NO       CEEMSG
QLEAWI    QSYS      *NO       CEENCOD
QLEAWI    QSYS      *NO       CEEDCOD
QLEAWI    QSYS      *NO       Q LE leBdyCh
QLEAWI    QSYS      *NO       Q LE leBdyEpilog
QLEAWI    QSYS      *NO       CEE4FCB

. . .

QLEAWI    QSYS      *NO       Q LE leBdyEpilog2
QLEAWI    QSYS      *NO       Q LE leBdyCh2
QLEAWI    QSYS      *NO       Q LE setActGrpUserRC
QLEAWI    QSYS      *NO       Q LE setActGrpProdRC
QLEAWI    QSYS      *NO       CEE4GETRC
QLEAWI    QSYS      *NO       CEE4SETRC
QLEAWI    QSYS      *NO       Q LE comp_mode
QLEAWI    QSYS      *NO       Q LE init_wcb_static_data
QLEAWI    QSYS      *NO       Q LE get_ag_static_entry
QLEAWI    QSYS      *NO       Q LE delete_ag_static_entry
QLEAWI    QSYS      *NO       CEE4RAGE
```

We could adapt it at will (for example filtering out `Q LE `\* entries).

Reading [this Ruby source code](playing_with_api_and_spaces.rb) could be inspiring but it is still too basic.
I am still collecting working examples that will allow the design of a more rich integration from PASE Ruby to IBM i ILE, possibly through a **gem**: for a platform concept (*S/38*) that survived more that 40 years there is no need to hurry up! 

[NEXT-15](#15-to-have-fun-by-reliving-old-glories)

----
### 13. to review the lesson on objects

 *The reason we put objects into the S/38 in the first place was to keep the system details contained so they could later be changed without affecting user application programs.* (FORTRESS ROCHESTER, page 114)
 
The core part of [the Ruby script](resolve.rb) we introduce today is the following:

``` ruby
ILEpointer  = struct [ 'char a[16]' ]
preload    = Fiddle.dlopen(nil)
rslobj2    = Fiddle::Function.new( preload['_RSLOBJ2'],
             [Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
             Fiddle::TYPE_INT )
ILEobject = ILEpointer.malloc
rc = rslobj2.call(ILEobject, type, obj, lib)
```

The [`_RSLOBJ2`](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/apis/pase__rslobj.htm) resolve to an IBM i object from PASE returing a *system pointer*:

```
bash-4.4$ resolve.rb QSYS QLEAWI 515
Object QSYS/QLEAWI of type 0x0203 resolved to ["000000000000000008cfb86754000200"]
bash-4.4$ resolve.rb QSYS QUSCRTUS 513
Object QSYS/QUSCRTUS of type 0x0201 resolved to ["000700000000000016ddf500bf000200"]
```

By resolving a system pointer for a PROGRAM OBJECT (type 0x0201) we gain the opportunity to execute it. 
As always, the ability to actually call the program is provided by an IBM i PASE **libc.a** function. 
Suited for the task is [`_PGMCALL`](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/apis/pase__pgmcall.htm).

In a previous chapter we executed native commands through ILE C `system` call but `_PGMCALL` offers us total control on arguments that are required to be ILE pointers.
We will use this new approach to create a USER SPACE object (where `system` would have been suited too) and then 
to receive a **space pointer** through a call to *Retrieve Pointer to User Space* [`QUSPTRUS`](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/apis/qusptrus.htm) API: this would have not been possible with the simpler `system` call approach. 
 
Frank Soltis on space pointers:
 
 *A space pointer looks very much like a system pointer. It's 16 bytes long and contain an address. The difference is that the address in a space pointer points to a byte somewhere **in the space portion** of a system object* 
   
The [Ruby script](playing_with_user_spaces.rb) will be the base for many future scripts.

Right now we simply: 

* extract the **space pointer** address (returned from `QUSPTRUS`),
* extract the **system pointer** address (retrieved with \_RSLOBJ2) and then
* extract the **first 256 bytes** of the user space content (returned from `QUSTRVUS`)

As soon as we set the initial value to `1` in EBCDIC

``` ruby
Initial_value = '1'.encode('IBM037')
```

we get the buffer filled with `0xF1` values:

```
bash-4.4$ playing_with_user_spaces.rb
8000000000000000160f9652ca001000
0000000000000000160f9652ca001900
f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
```

[NEXT-14](#14-to-put-previous-lessons-into-practice)

----
### 12. to investigate parameter passing again

We have our working service program. And we are ready to add an operational descriptor ILE pointer and test what happens if we pass it (allocating a zeroed 1024 buffer):

``` ruby
OperDesc    = struct [ 'char d[1024]' ] 
. . .
od = OperDesc.malloc                
. . .
setspp.call(ILEarguments.to_ptr, od)
```

```
bash-4.4$ study_parameter_passing.rb 'prova'
Prepared ILEarguments struct
800000000000000000008016b2688d90
00000000000000000000000000000000
800000000000000000008016b2688930
800000000000000000008016b2689790
Prepared inBuffer: ["979996a5814040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040"]
Returned ILEarguments struct
800000000000000000008016b2688d90
00000000000000000000000000000000
800000000000000000008016b2688930
800000000000000000008016b2689790
Returned outBuffer: ["979996a5814040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040"]
bash-4.4$ 
```

The RPG `DUMP(A)` does not show any difference confirming us the hidden nature of Operational Descriptors.

What if we create an RPG ILE that is Operational Descriptors aware by using [`OPDESC`](https://www.ibm.com/support/knowledgecenter/en/ssw_ibm_i_74/rzasd/dopdesc.htm) keyword?

```
     D WDUMP2_H        PR                    OPDESC
     D   InString                    64      CONST OPTIONS(*VARSIZE)
     D   OutString                   64      OPTIONS(*VARSIZE)
```

```
     H COPYRIGHT('(C) Copyright Andrea Ribuoli 2021')
     D/COPY QTEMP/QRPGLESRC,WDUMP2_H
     D WDUMP2          PI                    OPDESC
     D   InString                    64      CONST OPTIONS(*VARSIZE)
     D   OutString                   64      OPTIONS(*VARSIZE)
     D*
     C                   DUMP(A)
     C                   EVAL      OutString = InString
     C                   RETURN
```

Regardless of what we pass as Operational Descriptor nothing changes. 

But we are authorized to query operational descriptors. So let us change our useless logic.

Now our RPG ILE source will leverage: 

* `CEEDOD` API to gain extra info on the first argument and 
* `CEEMGET` API to report back the error (presumably) received.

```
     D CEEDOD          PR
     D ParmNum                       10I 0   CONST
     D                               10I 0
     D                               10I 0
     D                               10I 0
     D                               10I 0
     D                               10I 0
     D                               12A   OPTIONS(*OMIT)
     D*
     D CEEMGET         PR                    OPDESC
     D   CondToken                   12A     CONST
     D   MessageArea                 64A     VARYING
     D   MessagePtr                  10I 0
     D                               12A   OPTIONS(*OMIT)
     D*
     D DescT           S             10I 0
     D DataT           S             10I 0
     D DesI1           S             10I 0
     D DesI2           S             10I 0
     D ILn             S             10I 0
     D ErrCd           S             12A
     D m_ptr           S             10I 0
     D msg             S             64A     VARYING
     D*
     C*                  DUMP(A)
     C                   CALLP     CEEDOD(1:DescT:DataT:DesI1:DesI2:ILn:ErrCd)
     C                   CALLP     CEEMGET(ErrCd:msg:m_ptr:*OMIT)
     C                   EVAL      OutString = msg
     C                   RETURN
```

``` ruby
puts "Result: #{outBuffer[0,64].force_encoding('IBM037').encode('utf-8')}" 
```

We receive back the CEE0502 message: *'Result: Missing operational descriptor'*.

We are still groping in the dark! But we now have [a tool](study_parameter_passing2.rb) to test if we could ever pass information from Ruby (PASE) describing parameters the IBM i way. 

Curiously the topic of *operational descriptors* \-although appearing fundamental for the IBM i architecture\- has not been treated by Frank Soltis in his books. Why? I think I have found an answer.

It is possible that this **secret** is such because it is **shared**. Shared with the mainframe IBM platforms.
In the z/OS *Language Environment Runtime Messages* we can read about a message that sounds familiar:

**CEE0502S** The operational descriptor for the argument list was missing in routine *routine\-name*.

The document provides an astonishing explanation:

*The high order bit of register 1 was off or the constant **X'81C3C501'** was missing from the storage location immediately preceding the argument list.*

In 1822 egyptologist Jean François Champollion was able to decipher the ancient Egyptian hieroglyphs.
Next year will be **2022**: let us hope to understand how to make Operational Descriptors usable from PASE (and Ruby) before the end of next year!

[NEXT-13](#13-to-review-the-lesson-on-objects)

----
### 11. to investigate parameter passing

The documentation available for **\_ILECALLX** provides no details about the first 16 bytes of the *ILEarglist\_base*. The template mentions an ILE pointer field described as `/* Operational descriptor */`.

From ILE C/C++ documentation we can read a quite cryptic note:

 *To use operational descriptors, you specify a `#pragma descriptor` directive in your source to identify functions whose arguments have operational descriptors. Operational descriptors are then **built by the calling procedure and passed as hidden arguments** to the called procedure.*

The kind of processing involved in preparing operational descriptors is **undocumented**. This reminds me of many books that in the past were titled **"Undocumented \<something\>"**  where the object had been *DOS*, *Windows*, etcetera. Our objective with this chapter is to investigate the first ILE pointer of *ILEarglist\_base* struct. 
If we will discover something new we could rethink this chapter as *"Undocumented Operational Descriptors"*.

First of all we will start from the achievements of previous chapters verifiying if we could pass in an ILE pointer already in ILE format. In the previous chapter we learned how to copy an ILE pointer properly without destroying its **tagged** nature.

In the previous examples of \_ILECALLX, if an argument of type ILE pointer was required we always used **ARG_MEMPTR** (*-11* = *0xFFF5*). We can observe that after the call is performed the ILEarglist content is modified: in the same space the ILE pointer is calculated as a quad-word.
There are other type qualifiers that control the handling of pointers.
If we have an ILE pointer already resolved as a full quad-word we can use **ARG_SPCPTR** (*-12* = *0xFFF4*).

To transform a local PASE pointer into the equivalent tagged quad-word there is another API offered by **libc.a**:
[**\_SETSPP**](https://www.ibm.com/support/knowledgecenter/en/ssw_ibm_i_74/apis/pase__setspp.htm).

``` C
void _SETSPP(ILEpointer  *target,
             const void  *memory);
```

It is declared in Fiddle as:

``` ruby
setspp     = Fiddle::Function.new( preload['_SETSPP'],               
                           [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], 
                           Fiddle::TYPE_VOID )                       
```
 
Let us [revisit our script](invoke_system_FFF4.rb) to execute IBM i commands using the technique just introduced.

It works as expected:

```
bash-4.4$ invoke_system_FFF4.rb 'CRTLIB LIB(ATTEMPT)'
bash-4.4$ invoke_system_FFF4.rb 'DLTLIB LIB(ATTEMPT)'
```

We introduced a new usage technique of Fiddle:

``` ruby
cmd  = ARGV[0].encode('IBM037')
. . .
setspp.call(ILEarguments.to_ptr + 32, Fiddle::Pointer[cmd])
```

ILEarguments is created with a `ILEarglist.malloc`: inside the ILEarglist instance there is a `@entity` that is
an instance of `Fiddle::CStructEntity` with 3 attributes: `ptr`, `size`, `free`.

These are the inspections on `ILEarguments.to_ptr` and `(ILEarguments.to_ptr + 32`)` respectively:

```
#<Fiddle::CStructEntity:0x0000000182680bd0 ptr=0x0000000182680b90 size=48 free=0x0000000000000000>
#<Fiddle::Pointer:0x0000000182680a70       ptr=0x0000000182680bb0 size=16 free=0x0000000000000000>
``` 

The `+` method creates a new Fiddle::Pointer by advancing of 32 bytes over the CStructEntity (and properly setting the legitimate remaining size: 64 - 48 = 16).

The second argument of our `setspp.call` is still a Fiddle::Pointer. This time it is obtained from a generic Ruby string (the `cmd` variable). 

If we emit the following `inspect` methods: 


``` ruby
puts cmd.inspect                   
puts Fiddle::Pointer[cmd].inspect  
```

we get:

```
bash-4.4$ invoke_system_FFF4.rb 'DLTLIB LIB(ATTEMPT)'
"\xC4\xD3\xE3\xD3\xC9\xC2\x40\xD3\xC9\xC2\x4D\xC1\xE3\xE3\xC5\xD4\xD7\xE3\x5D"
#<Fiddle::Pointer:0x0000000182683390 ptr=0x00000001826147f0 size=19 free=0x0000000000000000>
```

Note that the size is determined from the attributes of the `cmd` String object: the actual string is not moved around.

We are now back to the original focus (the opening *operational descriptor* ILE pointer): as soon as there is apparently no qualifier for this ILE pointer field, which of the alternative handling is to be expected? Similar to ARG\_MEMPTR? Similar to ARG\_SPCPTR? We will first approach the ARG\_SPCPTR hypothesis.

Sometimes generating errors is a good strategy for learning. 
 
We mentioned the `#pragma descriptor` directive as a method to have the ILE C/C++ compiler take care of generating operational descriptors, but what about reading descriptors when passed by the caller? 

IBM i provides an API (**CEEDOD**) that is implemented as a builtin (so cannot have its address taken or be called through a procedure pointer). 
The objective of *CEEDOD* is to **Retrieve Operational Descriptor Information**.
Let us experiment with a simple service program that will be developed *ad-hoc* for this need.
The CEEDOD API retrieves operational descriptor information about a parameter (referenced by means of its ordinal position). 
Let us build a service program with a function receiving a two arguments (strings). 
The function will copy the first onto the second.
We will use such a tester making it evolve in order to gather information on how operational descriptors are to be provided from PASE (if such an option is actually viable).

| Source file        | Source member                        |
| ------------------ |:------------------------------------:|
| QRPGLESRC	     |   [WDUMP](QRPGLESRC/WDUMP.RPGLE)     |
| QRPGLESRC	     |   [WDUMP_H](QRPGLESRC/WDUMP_H.RPGLE) |
| QSRVSRC	     |   [RIBY_SRV](QSRVSRC/RIBY_SRV.BND)   |

These files can be installed automatically if you have **PASERIE** utility installed (by means of
`PASERIE/INSTALL GIT_USER(AndreaRibuoli) PACKAGEN(RIBY)`). 
Transferring and compiling manually is not complex at all (have a look at [build CL](QCLSRC/BUILD.CLLE) just in case).

```
bash-4.4$ study_parameter_passing.rb 'Test WDUMP performing a simple copy'
Prepared ILEarguments struct
00000000000000000000000000000000
00000000000000000000000000000000
800000000000000000008016b2687670
800000000000000000008016b2687cb0
Prepared inBuffer: ["e385a2a340e6c4e4d4d74097859986969994899587408140a2899497938540839697a84040404040404040404040404040404040404040404040404040404040"]
Returned ILEarguments struct
00000000000000000000000000000000
00000000000000000000000000000000
800000000000000000008016b2687670
800000000000000000008016b2687cb0
Returned outBuffer: ["e385a2a340e6c4e4d4d74097859986969994899587408140a2899497938540839697a84040404040404040404040404040404040404040404040404040404040"]
```

We performed a `DUMP(A)` statement inside the `WDUMP` function so we will find a spool file ending with:

```
NOME                  ATTRIBUTI            VALORE                                                                              
_QRNL_PRMCPY_INSTRING POINTER              SPP:00008016B2687670                                                                
_QRNL_PRMCPY_OUTSTRING...                                                                                                      
                      POINTER              SPP:00008016B2687CB0                                                                
_QRNL_PSTR_INSTRING   POINTER              SPP:00008016B2687670                                                                
_QRNL_PSTR_OUTSTRING  POINTER              SPP:00008016B2687CB0                                                                
INSTRING              CHAR(64)             'Test WDUMP performing a simple copy                             '                  
                      VALUE IN HEX         'E385A2A340E6C4E4D4D74097859986969994899587408140A2899497938540839697A84040404040'X 
                        41                 '404040404040404040404040404040404040404040404040'X                                 
OUTSTRING             CHAR(64)             '                                                                '                  
                      VALUE IN HEX         '00000000000000000000000000000000000000000000000000000000000000000000000000000000'X 
                        41                 '000000000000000000000000000000000000000000000000'X                                 
           * * * * *   F I N E   D E L   D U M P   R P G  * * * * *                                                            
```

This is a good start to experiment seaching for *Operator Descriptors* role. A new chapter is needed.

[NEXT-12](#12-to-investigate-parameter-passing-again)

----
### 10. to move around tagged pointers

To prepare for future investigation we introduce today another topic that can help understand some otherwise obscure situations we may face when handling PASE-ILE interaction.

Right now the **\_CVTSPP** was successful only in one of our scripts.
Let us copy here the crucial lines of code:

``` ruby
  ILEreturn    = ILEpointer.malloc
  . . .
  ILEarguments[16, 16] = [ILEreturn.to_i.to_s(16).rjust(32,'0')].pack("H*")
  . . .
  rc = ilecallx.call(ILEfunction, ILEarguments, ['FFF8FFF50000'].pack("H*"), 16, 0)
  . . .
  puts "PASE pointer from _CVTSPP    [\"#{cvtspp.call(ILEreturn).to_s(16).rjust(16,'0')}\"]"
```

When ILEreturn was passed to \_CVTSPP we had not moved the content we received from the \_ILECALLX API. We can imagine that a copy of the ILE pointer retains all properties of the original pointer, so that applying \_CVTSPP to the copy would behave in the same way.

Let us introduce the following extra steps:

``` ruby
  ILEreturn2   = ILEpointer.malloc                                                            
  ILEreturn2[0, 16] = ILEreturn[0, 16]                                                        
  puts "ILE SPP copy #{ILEreturn2[0, 16].unpack("H*")}"                                        
  puts "PASE pointer from _CVTSPP    [\"#{cvtspp.call(ILEreturn2).to_s(16).rjust(16,'0')}\"]"   
```

We get something like:

```
bash-4.4$ playing_space_pointers.rb 20
PASE pointer                 ["0000000182687eb0"]
ILE SPP      ["800000000000000000008016b2687eb0"]
PASE pointer from _CVTSPP    ["0000000182687eb0"]
ILE SPP copy ["800000000000000000008016b2687eb0"]
PASE pointer from _CVTSPP    ["0000000000000000"]
```

Despite the memory content is the same, the second execution of *\_CVTSPP* does not consider valid the ILE pointer we are providing. This is a **fundamental charateristic of IBM i**, let us listen to *Frank Soltis*:

  *"... any store to memory that's generated for an MI program uses the standard instructions and **always turns off the tag bits**. When a pointer is created as part of a resolve operation, SLIC builds the pointer in two 64-bit registers and uses the `stq` instruction to turn on the tag bits in memory."* (FORTRESS ROCHESTER, page 160)  

In order to copy memory without destroying 16-byte tagged pointers we need to require the services of PASE **libc.a** again. It is offering two extra functions: [**\_MEMCPY\_WT** and **\_MEMCPY\_WT2**](https://www.ibm.com/support/knowledgecenter/en/ssw_ibm_i_74/apis/pase__memcpy_wt.htm).

The new changes are:

``` ruby
memcpy_wt  = Fiddle::Function.new( preload['_MEMCPY_WT'],                              
                           [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], 
                           Fiddle::TYPE_VOIDP )  
. . .                           
ILEreturn2   = ILEpointer.malloc                                                            
memcpy_wt.call(ILEreturn2, ILEreturn, 16)                                                   
puts "ILE SPP copy #{ILEreturn2[0, 16].unpack("H*")}"                                       
puts "PASE pointer from _CVTSPP    [\"#{cvtspp.call(ILEreturn2).to_s(16).rjust(16,'0')}\"]"                                                                  
```

That solve our issue:

```
PASE pointer                 ["0000000182687490"]
ILE SPP      ["800000000000000000008016b2687490"]
PASE pointer from _CVTSPP    ["0000000182687490"]
ILE SPP copy ["800000000000000000008016b2687490"]
PASE pointer from _CVTSPP    ["0000000182687490"]
```

[NEXT-11](#11-to-investigate-parameter-passing)

----
### 9. to gather information on space pointers from PASE

We introduced the idea that ILE mode has full access to memory allocated by PASE. The opposite is not granted: not all storage allocated by ILE can be visible in PASE. We will verify this aspect.

We will compare different ILE APIs that can be used to reserve storage blocks:

1. `malloc`
2. `_C_TS_malloc`
3. `_C_TS_malloc64`     
4. `Qp2malloc`

When ILE **malloc** is used in a compiled program it can be implicitly re-mapped to **\_C\_TS\_malloc**
as soon as `TERASPACE(*YES *TSIFC)` parameter is specified. If we invoke ILE malloc from Ruby this will *always* use **single-level store** storage. And will also have 16711568 bytes (0xFEFF90) as maximum size.
The maximum amount of **teraspace storage** that can be allocated by each call to \_C\_TS\_malloc() is instead 2147483424 bytes (0x80000000 - 0xE0 = 0x7FFFFF20). When more bytes are needed on a single request the **\_C\_TS\_malloc64** is available (it accepts an *unsigned long long int* to specify the size required).

The template for **Qp2malloc** is: 

``` C
void* Qp2malloc(QP2_dword_t size, QP2_ptr64_t *mem_pase); 
```

QP2_dword_t is an *unsigned long long int* so Qp2malloc is not limited in the size value and offers an extra service: sets the 8 bytes buffer (we are addressing with the second argument) as the PASE address to the newly allocated teraspace storage. 

Let us start with the last API of the list. We soon notice that while we were able to specify an *ARG\_MEMPTR* in the argument list there is no such thing as a **RESULT\_MEMPTR**. If we invoke \_ILECALLX specifying **-11** as the result\_type we receive an error **ILECALL\_INVALID\_RESULT (2)** (*The result\_type value is invalid*). 

On the other hand the specifications for the result\_type in \_ILECALLX offer an extra option: any **positive value** for the result\_type can be used when the function result is an aggregate (structure or union). An aggregate function result is returned in a buffer allocated by the caller and passed to the target ILE procedure using a special field in the argument list (bytes 17-32 of the *base*). We will use this technique to receive the ILE pointer treating it as a generic aggregate of size 16.   
We will prepare an ILEpointer variable and pass its address in the aggregate field.

This is what we are doing in the [Ruby script that plays with Space Pointers](playing_space_pointers.rb).

We use this same approach also with `malloc`, `_C_TS_malloc` and `_C_TS_malloc64` respectively. In these three extra APIs there is no opportunity to directly read back a PASE pointer. The question that arises is how we can convert a buffer containing a generic ILE pointer (in its original format) while in PASE. 

As I previously mentioned, there are various extensions to the *AIX libc.a*. Some of these take care of converting pointers.  
The **[_CVTSPP](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/apis/pase__cvtspp.htm)** function converts *a teraspace address in a tagged space pointer* to an equivalent IBM PASE for i memory address. Only teraspace addresses have an equivalent in the private address space of the process. 

Assuming ILE malloc returns a teraspace address (as with *Qp2malloc*) we will be able to handle the conversion in PASE by -dynamically- using the *_CVTSPP* () function.

Despite Qp2malloc'ed memory ILE address can be successfully converted back to PASE pointer with *\_CVTSPP* all the other APIs (`malloc`, `_C_TS_malloc` and `_C_TS_malloc64`) are using memory regions that do not have a PASE pointer equivalent: 

```
bash-4.4$ playing_space_pointers_malloc.rb 10
ILE SPP      ["8000000000000000fd48a7a0ec0021e0"]
PASE pointer from _CVTSPP    -1

bash-4.4$ playing_space_pointers_C_TS_malloc.rb 10
ILE SPP      ["800000000000000000008000440040a0"]
PASE pointer from _CVTSPP    -1

bash-4.4$ playing_space_pointers_C_TS_malloc64.rb 10       
ILE SPP      ["800000000000000000008000440040a0"]
PASE pointer from _CVTSPP    -1
```

It could be useful to refine maximum sizes. 
We can actually appreciate the difference between *\_CVTSPP* returning 0 .vs. returning -1.

* **0** means the pointer is NULL
* **-1** means the pointer is not NULL but memory allocated can not be accessible from PASE

When using `malloc` the actual limit (when invoked from PASE) seems to be **0xFFF000** (16773120 bytes) rather than the documented 16711568 bytes (0xFEFF90)

```
bash-4.4$ playing_space_pointers_malloc.rb 16773120
ILE SPP      ["8000000000000000d9e67a6bfe001000"]
PASE pointer from _CVTSPP    -1
bash-4.4$ playing_space_pointers_malloc.rb 16773121
ILE SPP      ["80000000000000000000000000000000"]
PASE pointer from _CVTSPP    0
```

When using `_C_TS_malloc` the actual limit (when invoked from PASE) seems to be **0x7FFFFF30** (2147483440 bytes) rather than the documented 2147483424 bytes (0x7FFFFF20)

```
bash-4.4$ playing_space_pointers_C_TS_malloc.rb 2147483440
ILE SPP      ["800000000000000000008036d00000a0"]
PASE pointer from _CVTSPP    -1
bash-4.4$ playing_space_pointers_C_TS_malloc.rb 2147483441
ILE SPP      ["80000000000000000000000000000000"]
PASE pointer from _CVTSPP    0
```

[NEXT-10](#10-to-move-around-tagged-pointers)

----
### 8. to execute a service program entry call from PASE 

By means of **fiddle** we managed to dinamically call **_ILELOADX** and **_ILESYMX** from a Ruby script.
Fiddle offered us the support to -relatively easily- declare the argument list and return code types involved.
It also offered us the ability to prepare memory consistently when calls are to be performed.

The object oriented nature of the Ruby language enabled the designers of **fiddle** to simplify the final usage of 
shared library entries. With `Fiddle::Function.new` we simply pass the function templates: the object instance we are returned with is then capable of handling the parameters provided in a subsequent elegant `call` method.

As we approach the **[_ILECALLX](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/apis/pase__ilecall.htm)** documentation we understand the difference! The burden of invoking a service program entry with a prepared set of arguments is all on our shoulders!

We will start with simple working examples: we will be collecting ideas on how to design and implement an abstraction that will offer the ability to use ILE Service Programs (**\*SRVPGM**) from Ruby with the same ease *fiddle* is offering for shared libraries.

Let us first investigate our ILE C `system` example.    

ILE C `system` returns an integer but receives an ILE native pointer (that is a quad-word).  
We need to allocate a 16-byte aligned 16-byte chunk of memory prepared with the PASE address in the last 8 bytes.
During the *\_ILECALLX* processing the PASE address in converted into a proper IBM i space pointer and finally the system call gets executed.

All storage in the `private address space` of the running PASE/AIX process is shared with the current IBM i job: ILE APIs have access to it. Passing parameters to **_ILECALLX** is far from simple in a PASE C program but it is definitely complex in a dynamic style. Let us shed some light on the details.

First of all we have to prepare the template for *_ILECALLX* that **fiddle** will use. The C notation is:

``` C
 int _ILECALLX(const ILEpointer  *target,
               ILEarglist_base   *ILEarglist,
               const arg_type_t  *signature,
               result_type_t     result_type,
               int               flags);
```

In */usr/include/as400_types.h* we find the definition of *result\_type\_t*:

``` C
typedef int16        result_type_t;
```

In */usr/include/as400_types.h* we find the definition of *int16*:

``` C
typedef signed short         int16;
```

So far we know that we can prepare a Fiddle Function for **\_ILECALLX** this way:

``` ruby
ilecallx = Fiddle::Function.new( preload['_ILECALLX'],                                                                        
            [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_INT],
            Fiddle::TYPE_INT )                                                                                 
```

In a previous Ruby script (enhanced by *fiddle*) we already defined an `ILEpointer` type as `ILEpointer = struct [ 'char b[16]' ]`. It was valued by a call to **\_ILESYMX**. 

The secret of using fiddle's `struct` in PASE is that **the actual memory reserved will be acquired with a PASE `malloc`**. This is a fundamental detour from how memory is usually handled by the Ruby interpreter (engineered to natively integrate with the garbage collector). 

PASE `malloc` variant differs from AIX one: it is **always returning a 16-byte aligned address**, this implies that by using fiddle's `struct` we are guaranteed that those 16 bytes are suitable to hold a teraspace address when handled in ILE job mode.   

  [*The PASE for i version of malloc always provides 16-byte aligned storage, and you can arrange 16-byte alignment of stack storage*](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/rzalf/rzalfcompileaix.htm)

The ILEarglist is (again) required to be 16-byte aligned.
Apart from the global alignment of this struct we have an opening standard **base** struct followed by a variable sequence of arguments that need to be padded with extra bytes consistently with the data type length of the actual argument. 
The logic to be consistent with is summurized by the following table:

| Argument Length | Alignment       |
| --------------- |:---------------:|
| 1 byte	        |      any        |
| 2 bytes	        |    2 bytes      |
| 3-4 bytes       |    4 bytes      |
| 5-8 bytes       |    8 bytes      |
| 9 or more bytes |   16 bytes      |

Let us keep these details in mind and try to apply them in invoking ILE `system` from Ruby PASE: we just have one argument.
As soon as the *ILEarglist\_base* is 32 bytes long, the first argument will be implictly 16-byte aligned too. Being the only argument we do not have to care too much this time.

We will try with: 

``` ruby
ILEarglist = struct [ 'char b1[16]', 'char b2[16]', 'char b3[16]' ]
```

The **signature** is a pointer to a list of `arg_type_t` values.
The typedef introducing `arg_type_t` declares it as a signed short. So we have to prepare an array of shorts ready to be interpreted.
The actual number of arguments processed by the *\_ILECALLX* function is determined by the number of entries in the signature list, which is determined by the location of the first 0 value in the list that ends the processing.
We need 2 short integers to invoke ILE `system`: 

1. the first qualifies the ILE pointer argument and will be set to ARG\_MEMPTR (i.e. **-11**)
2. the second closes the list and will be set to ARG\_END (**0**)

This is a struct that does not need to be passed to ILE so that its own alignment is not relevant (we can allocate it as a regular Ruby string).


We will ignore the return code of `system` by setting **result_type** to 0.

We need to provide enough contiguos storage following *ILEarglist\_base* for a 16 bytes (quad-word), i.e. the ILE pointer.

The [Ruby script I am presenting](invoke_system.rb) summarizes the steps described. Ruby can encode an **EBCDIC** content (through the support of **IBM037** encoding). That content is passed on as command argument in the `int system(const char *command)` ILE C standard library function.

[NEXT-9](#9-to-gather-information-on-space-pointers-from-pase)

----
### 7. to get acquainted with QSYS/QC2xx service programs 

In IBM i ILE the role of **libc.a** is played by a group of service programs. 
If we search for `system`, a C standard library function, we will find it inside a service program named **QSYS/QC2SYS**. 
The QSYS/QC2SYS service program can be loaded from PASE so we can imagine to extend our Ruby script dinamically introducing support for ILE native `system` function.

The C template for `system` is inside include file member `QSYSINC/H(STDLIB)`:

``` C
int      system   ( const char *command ); 
``` 

After obtaining accessability to a service program with *[_ILELOADX](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/apis/pase__ileload.htm)* we can look for a specific entry with **[_ILESYMX](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/apis/pase__ilesym.htm)**

 ``` C
 int _ILESYMX(ILEpointer          *export,
              unsigned long long  actmark,
              const char          *symbol);  
 ```

In order for *fiddle* to be able to handle \_ILESYMX we need to prepare memory for an **ILEpointer**.

``` ruby
 . . . 
ILEpointer = struct [ 'char b[16]' ]
 . . .
ilesymx = Fiddle::Function.new( preload['_ILESYMX'],
            [Fiddle::TYPE_VOIDP, Fiddle::TYPE_LONG_LONG, Fiddle::TYPE_VOIDP],
            Fiddle::TYPE_INT )
 . . .
ILEfunction = ILEpointer.malloc
rc = ilesymx.call(ILEfunction, srvpgm, ARGV[1])
raise "Searching for function entry '#{ARGV[1]}' in service program #{ARGV[0]} failed" if rc != 1
```

I prepared **[check_srvpgm_entry.rb](check_srvpgm_entry.rb)** accepting 2 arguments: 

1. qualified service program name 
2. function entry name

If successful nothing occurs; in case of error we get:

```
bash-4.4$ ./check_srvpgm_entry.rb QSYS/QC2UTIL1 mallocz
./check_srvpgm_entry.rb:22:in `<main>': Searching for function entry 'mallocz' in service program QSYS/QC2UTIL1 failed (RuntimeError)
```

[NEXT-8](#8-to-execute-a-service-program-entry-call-from-pase)

----
### 6. to gain confidence on Ruby language

Assuming you are now confident in using a specific Ruby for powerpc-os400 release let us install it (out of a chroot). If you prefer not to officially add an extra repository (*andrearibuoli.repo*) you can download required RPMs **inside the chroot** and install them locally **out of the chroot**.

We cannot install Ruby directly:
```
$ /QOpenSys/pkgs/bin/bash
bash-4.4$ export PATH=/QOpenSys/pkgs/bin:$PATH
bash-4.4$ yum list | grep ruby
bash-4.4$
``` 

We first perform:

```
bash-4.4$ chroot /QOpenSys/chRootRiby/ yum install yum-utils

```

So we fetch the RPMs (no installation) via chroot using one of the utilities **yum-utils** provide:

```
bash-4.4$ chroot /QOpenSys/chRootRiby yumdownloader ruby
ruby-3.0.0-2.ibmi7.3.ppc64.rpm                              |  24 MB  00:07     
bash-4.4$ chroot /QOpenSys/chRootRiby yumdownloader ruby-devel
ruby-devel-3.0.0-2.ibmi7.3.ppc64.rpm                        | 335 kB  00:00
bash-4.4$ 
```

We are authorized to access the chroot from the outside so we perform our installation (the order matters):

```
yum localinstall /QOpenSys/chRootRiby/ruby-3.0.0-2.ibmi7.3.ppc64.rpm 
yum localinstall /QOpenSys/chRootRiby/ruby-devel-3.0.0-2.ibmi7.3.ppc64.rpm 
```

Note that some prerequite packages may be missing and will be installed directly from *ibm.repo*.
Now Ruby interpreter is available for all users.

Ruby is an excellent tool for system administration. 
Let us use it combining previous study of **fiddle** and **_ILELOADX**.  

Ruby supports **Regular Expressions**. 

If we perform `ls -1 \QSYS.LIB\*.SRVPGM` we get the list of service programs provided by IBM in QSYS.
Building on this idea we decide to print out a list of those that cannot be loaded from PASE.

This is done with [the script named nonLoadables](nonLoadables).

```
bash-4.4$ RIBY/nonLoadables 
'QSYS/QGLDCLNT64' is not loadable from PASE
'QSYS/QLGICUNORM' is not loadable from PASE
'QSYS/QLGICUSORT' is not loadable from PASE
'QSYS/QP0LCNVMSG' is not loadable from PASE
'QSYS/QP0WSTTS64' is not loadable from PASE
'QSYS/QQQSVREG' is not loadable from PASE
'QSYS/QQQSVXML' is not loadable from PASE
   . . .
'QSYS/QYUSVPDCOL' is not loadable from PASE
'QSYS/QZLSSRV5' is not loadable from PASE
'QSYS/QZRUDBG' is not loadable from PASE
```

It is not clear -to me- why some SRVPGM are loadable from PASE while others are not (as a general rule).

[NEXT-7](#7-to-get-acquainted-with-qsysqc2xx-service-programs)

### 5. to study IBM i through PASE with Ruby

In my personal experience Ruby in PASE has always been a tool to better understand IBM i job dual nature. When IBM decided for PASE the way it is (this was more that twenty years ago), they thought it had been better to just implement an AIX runtime environment and so avoid AS/400 users' base the burden of managing another operating system.

But how can a PASE Ruby script investigate this? 

The first consideration is that **IBM i PASE libc.a** differs from **AIX libc.a**: it offers extra resources vital to sense the dual nature of an IBM i job. 

Ruby interpreter comes with the Ruby Standard Library (**RSL**). Among many other goodies, RSL provides a **libffi** wrapper for Ruby named **fiddle**. 

If you perform a dump of the ruby interpreter you can list the shared libraries it uses at load time. As soon as we installed Ruby interpreter only inside the chroot we will execute:

```
$ chroot /QOpenSys/chRootRiby which ruby
  /QOpenSys/pkgs/bin/ruby
```

and:

```
$ chroot /QOpenSys/chRootRiby dump -X64 -Hv /QOpenSys/pkgs/bin/ruby
  . . .
                        ***Import File Strings***
INDEX  PATH                          BASE                MEMBER              
0      /QOpenSys/pkgs/lib:/usr/lib:/lib                                         
1                                    libbsd.a            shr_64.o            
2                                    libutil.so.2        shr_64.o            
3                                    libpthread.a        shr_xpg5_64.o       
4                                    libgmp.so.10        shr_64.o            
5                                    libdl.a             shr_64.o            
6                                    libcrypt.a          shr_64.o            
7                                    libc.a              shr_64.o              
```

So there is no *libffi.so* involved in default Ruby execution. The actual shared library depending on *libffi* is `/QOpenSys/pkgs/lib/ruby/3.0.0/powerpc-os400/fiddle.so`. 

```
$ chroot /QOpenSys/chRootRiby dump -X64 -Hv /QOpenSys/pkgs/lib/ruby/3.0.0/powerpc-os400/fiddle.so

/QOpenSys/pkgs/lib/ruby/3.0.0/powerpc-os400/fiddle.so:

. . .

                        ***Import File Strings***
INDEX  PATH                          BASE                MEMBER              
0      /QOpenSys/pkgs/lib:/usr/lib:/lib                                         
1                                    libdl.a             shr_64.o            
2                                    libffi.so.6         shr_64.o            
3                                    libc.a              shr_64.o            
4                                    libgcc_s.so.1       shr_64.o            
5                                    ..                                      

```

In order to benefit from the services of libffi wrapped by fiddle we need to **require** it (`require 'fiddle'`). What fiddle offers us is the possibility 

* to load shared libraries, 
* to find exported functions and 
* to call them.

When a shared library is already loaded there is no need to explicitly reload it.
So we can access **libc.a** entries invoking a `dlopen()` with *nil* argument. 

One of the functions that IBM i PASE adds to original AIX libc.a is **[_ILELOADX](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/apis/pase__ileload.htm)**

We can run the Interactive RuBy (**irb**) from the chroot:

```
$ chroot /QOpenSys/chRootRiby /QOpenSys/pkgs/bin/irb
irb(main):001:0> require 'fiddle'
=> true
irb(main):002:0> quit
$ 
```

We can also copy a script distributed with RIBY called **[check_srvpgm.rb](check_srvpgm.rb)** in our
home folder in the chroot:

```
cp ${HOME}/RIBY/check_srvpgm.rb /QOpenSys/chRootRiby${HOME}
```

and execute it passing as an argument the service program we want to load from PASE:

```
$ chroot /QOpenSys/chRootRiby ${HOME}/check_srvpgm.rb QSYS/QC2UTIL1
  'QSYS/QC2UTIL1' is loadable from PASE
```

if the service program cannot be loaded (e.g. does not exist) we receive the following message:

```
$ chroot /QOpenSys/chRootRiby ${HOME}/check_srvpgm.rb QSYS/QC2UTIL8
  'QSYS/QC2UTIL8' is not loadable from PASE
```

Note that accessing native (ILE) service programs is not limited by chroot: only the authorities of current user profile matter!

[NEXT-6](#6-to-gain-confidence-on-ruby-language)

### 4. to do everything once again

**Repeatability** is a measure of the likelihood that, having produced one result from an experiment, you can try the same experiment, with the same setup, and produce that exact same result.

It is fundamental for us to be able to automate what has been performed in steps 1 through 3 in a unique sequence of steps. We could also leverage *shell scripting* introducing a variable for assigning a name to the *chroot* and another for refining the choice of the *package* to be installed.
In this repository the script named [onceAgain](onceAgain) is doing that.
It accepts 0, 1 or 2 arguments. 

* The first argument (when provided) will be the name of the chroot under */QOpenSys* (default: **chRootRiby**).
* The second argument will be the name of the package to be installed in the chroot (default: **ruby** ).

Let us test the script passing no arguments (having removed previous installation):

```
$ rm -r /QOpenSys/chRootRiby
$ cd $HOME
$ git clone https://github.com/AndreaRibuoli/RIBY.git
$ RIBY/onceAgain
```

The script will allow us to create chroots at different level of *version-release* of Ruby. Let us test the script adopting the following arguments:

```
$ cd $HOME
$ RIBY/onceAgain chRootRibyPrv ruby-devel
```

[NEXT-5](#5-to-study-ibm-i-through-pase-with-ruby)

----
### 3. to install Ruby 3.0

In the previous steps we organized a confortable home for our Ruby installation. 
I organized a yum repository to host current and future builds of Ruby interpreter.

To configure access to the mentioned repository we will use **git**:

```
yum -y install git
```

```
cd $HOME
```

```
git clone https://github.com/AndreaRibuoli/RIBY.git
```

```
cp ./RIBY/andrearibuoli.repo /QOpenSys/etc/yum/repos.d
```

```
yum -y install ruby
```

```
ruby -v
```

```
gem list
```

Here we are: you have **Ruby 3.0 interpreter installed in an IBM i PASE chroot!**

[NEXT-4](#4-to-do-everything-once-again)

----
### 2. to refurbish the flat

At the end of the first step we entered our newly created chroot for the first time.

We had previously installed *yum* so it is available to list installed packages:

```
yum list installed
```

but not to install extra packages (`yum repolist all` returns *repolist: 0*)


We can notice there are some refinements required:

* if we execute `cd $HOME` we will notice that current user's home needs to be created in the chroot (`mkdir $HOME`; `chmod 0755 $HOME`)
* the */tmp* directory is missing the *sticky bit* (execute `chmod +t /tmp`)
* the */QOpenSys/etc/yum* is incomplete: */QOpenSys/etc/yum/repos.d* directory is missing so that no yum repository is identified (`mkdir /QOpenSys/etc/yum/repos.d`)

**Note**: in order to configure yum repository enter 5250 and 

CPY OBJ('*/QOpenSys/etc/yum/repos.d/ibm.repo*') TODIR('*/QOpenSys/chRootRiby/QOpenSys/etc/yum/repos.d*')

Now, if we repeat the `yum repolist all` we get:

```
bash-4.4$ yum repolist all
repo id                              repo name                         status
ibm                                  ibm                               enabled: 661
repolist: 661
```

[NEXT-3](#3-to-install-ruby-30)

----
### 1. to pave the way

If you do not have experience with **IBM i chroot** I would suggest you to practice a bit.
I assume you already have installed **yum** in your PASE environment so that installing IBM i chroot will be straightforward:

```
yum install ibmichroot
``` 

Creating a chroot is as simple as (the `-y` options means *Auto respond yes to the prompts*):

```
chroot_setup -y /QOpenSys/chRootRiby
``` 

Now, yum supports an option (`--installroot`) that allows us to specify a chroot (already created) as the target for our installation:
we will use it to prepare the safe environment to experiment with Ruby 3. 
First of all we install in the chroot the **yum** package itself (with its dependencies) so that we will be able to issue the next installations from the chroot:

```
yum -y --installroot=/QOpenSys/chRootRiby install yum ca-certificates-mozilla
```

We also add the package *ca-certificates-mozilla* because it will be useful later on.

Yum handles all dependencies and we will end up installing almost fifty packages! One of these is *bash* so that entering the chroot we can actually use the newly installed **bash** shell:

```
chroot /QOpenSys/chRootRiby /QOpenSys/pkgs/bin/bash
```

[NEXT-2](#2-to-refurbish-the-flat)
