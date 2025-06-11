$!  DUPLICATE_IMPORT_ISQ.COM
$!  Description: This scripts duplicates an ISQ and imports it into another sample
$!  Author:      Vincent Stadelmann
$!  Date:        24-NOV-2017
$!------------------------------------------------------------------------------
$!  P1  = ISQ-filename
$!  P2  = New sample no
$!
$   CTHEADER    == "$UT:CTHEADER.EXE"
$   MAKESAMPLE  == "$UT:UCT_DEFINE_SAMPLES.EXE"
$   IMPORT      == "$UM:UCT_IMPORT.EXE"
$   SAY         == "WRITE SYS$OUTPUT "
$!------------------------------------------------------------------------------
$   SET OUTPUT_RATE=00:00:01
$!
$   ISQFILE = P1
$!
$   IF P1 .EQS. "" THEN GOTO TERMINATE
$   IF P2 .EQS. "" THEN GOTO TERMINATE
$!
$   ISQFILE = F$SEARCH(ISQFILE)
$   IF ISQFILE .EQS. ""
$   THEN
$       WRITE SYS$OUTPUT " Could not find file: ''ISQFILE'"
$       GOTO TERMINATE
$   ENDIF
$!
$   FNAME    =  F$PARSE(ISQFILE,,,"NAME")
$   LOCATION =  F$PARSE(ISQFILE,,,"DEVICE") + F$PARSE(ISQFILE,,,"DIRECTORY")
$   ISQNAME  =  FNAME+".ISQ"
$   ISQROOT  =  LOCATION+FNAME
$   COMFILE := 'LOCATION''FNAME'_DUPLICATE_IMPORT_MEAS.COM
$   LOGFILE := 'LOCATION''FNAME'_DUPLICATE_IMPORT_MEAS.LOG
$!
$   SHOW SYMBOL ISQFILE
$   SHOW SYMBOL ISQNAME
$   SHOW SYMBOL ISQROOT
$   SHOW SYMBOL COMFILE
$   SHOW SYMBOL LOGFILE
$!------------------------------------------------------------------------------
$! DUPLICATE FILE
$   FNAME_TRAIL  = F$STRING(F$EXTRACT(1,7,FNAME))
$   NEW_ISQFILE := 'LOCATION'X'FNAME_TRAIL'.ISQ
$   SHOW SYMBOL FNAME_TRAIL
$   SHOW SYMBOL NEW_ISQFILE
$ 
$!------------------------------------------------------------------------------
$   SAY "Importing ISQ in DB"
$   OPEN/WRITE OUTFILE 'COMFILE'
$   WRITE OUTFILE "$ SET OUTPUT_RATE=00:00:01 "
$   WRITE OUTFILE "$ COPY ''ISQFILE' ''NEW_ISQFILE'"
$   WRITE OUTFILE "$ WAIT 00:00:01 "
$   WRITE OUTFILE "$ IMPORT"
$   WRITE OUTFILE "''NEW_ISQFILE'"
$   WRITE OUTFILE "''P2'"
$   WRITE OUTFILE "Y"
$   WRITE OUTFILE "0"
$   WRITE OUTFILE "0"
$   WRITE OUTFILE "Y"
$   WRITE OUTFILE "$"
$   WRITE OUTFILE "$ WAIT 00:00:02 "
$   WRITE OUTFILE "$ EXIT"
$   CLOSE OUTFILE
$   @'COMFILE'
$   EXIT
$!------------------------------------------------------------------------------
$ TERMINATE:
$   SAY "!  P1  = ISQ-filename"
$   SAY "!  P2  = New sample no"
$   EXIT 
