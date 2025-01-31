$!==========================================================================
$! RUN UCT-LIST AND WRITE RESULTS TO A SUMMARY FILE
$! BASED ON UU:UCT_EVALUATION_3DRESULT_APPEND.COM
$!
$! BY HELEN BUIE
$! LAST UPDATED:  OCT 21, 2010
$!==========================================================================
$ SAY = "WRITE SYS$OUTPUT"
$ SAY "=========================================================="
$ SAY "!! EXTRACT_RESULTS.COM: "
$ SAY "!! - BY HELEN BUIE - "
$ SAY "=========================================================="
$ SH SYM P1
$ SH SYM P2
$
$ IF P2 .EQS. ""
$  THEN
$    SAY ""
$    SAY "USAGE:" 
$    SAY "$@COM:EXTRACT_RESULTS.COM P1 P2"
$    SAY "P1 = AIM FILENAME, INCLUDE FULL PATH"
$    SAY "P2 = TEXT FILENAME FOR PROJECT RESULTS, INCLUDE FULL PATH"
$    SAY ""
$    GOTO QUIT
$ ENDIF
$ 
$ P1 = P1 - F$PARSE(P1,,,"VERSION")
$ CHECKAIM = F$EXTRACT(F$LENGTH(P1)-3,3,P1)       
$ SHOW SYM CHECKAIM
$ IF CHECKAIM .NES. "AIM"
$  THEN
$    SAY ""
$    SAY "ERROR:  PLEASE CHECK AIM INPUT."
$    SAY ""
$    SAY "USAGE:" 
$    SAY "$@COM:EXTRACT_RESULTS.COM P1 P2"
$    SAY "P1 = AIM FILENAME, INCLUDE FULL PATH"
$    SAY "P2 = TEXT FILENAME FOR PROJECT RESULTS, INCLUDE FULL PATH"
$    SAY ""
$    GOTO QUIT
$ ENDIF
$
$ IF F$SEARCH("''P1'") .EQS. ""
$  THEN
$    SAY ""
$    SAY "ERROR:  AIM FILE DOES NOT EXIST."
$    SAY ""
$    GOTO QUIT
$ ENDIF
$
$
$!---------------------------------------------------------------
$! DEFINE REQUIRED PARAMETERS
$!---------------------------------------------------------------
$!  
$ IPL_AIM        = P1
$ D3RESULT_ALL   = P2
$
$ SH SYM IPL_AIM
$ SH SYM D3RESULT_ALL
$
$ FILENAME       = F$PARSE(IPL_AIM,,,"NAME")
$ SH SYM FILENAME
$
$ D3RESULT	 = D3RESULT_ALL - ".TXT" + "_TMP.TXT"
$ SH SYM D3RESULT
$
$ COMMAND_FILE   = IPL_AIM - ".AIM" + "_RES.COM"
$ SH SYM COMMAND_FILE
$
$
$!---------------------------------------------------------------
$! SEARCH AIM HEADER FOR MEASUREMENT NUMBER, STORE IN MEAS_NO
$!---------------------------------------------------------------
$  AIX == "$UT:D3_IO_EXAMINE.EXE -L"
$  PIPE AIX 'IPL_AIM' | SEARCH SYS$PIPE "INDEX MEASUREMENT"| -
        (READ SYS$INPUT LINE ; DEFINE/JOB LINE_LOG &LINE)
$  LINE_SYM = F$TRNLNM("LINE_LOG")
$  MEAS_NO = F$EXTRACT(45,8,LINE_SYM)
$  MEAS_NO = F$EDIT(MEAS_NO,"TRIM,COMPRESS")
$  SH SYM MEAS_NO
$
$!---------------------------------------------------------------
$! WRITE A COMMAND FILE TO RUN UCT_LIST AND APPEND RESULTS
$!---------------------------------------------------------------
$
$  IF MEAS_NO .EQS. "" 
$    THEN 
$      SAY ""
$      SAY "ERROR:  COULD NOT GET MEASUREMENT NUMBER."
$      SAY ""
$      GOTO QUIT 
$  ENDIF
$
$
$!COPY HEADER FILE IF RESULT FILE NOT FOUND
$!---------------------------------------------------------------
$  OPEN/WRITE OUTFILE 'COMMAND_FILE'
$  WRITE OUTFILE "$! READING OUT 3D RESULT DATABASE AND PUTTING IT INTO APPENDED .TXT FILES"
$  WRITE OUTFILE "$!"
$  WRITE OUTFILE "$ IF F$SEARCH(""''D3RESULT_ALL'"") .EQS. """" "
$  WRITE OUTFILE "$ THEN"
$  WRITE OUTFILE "$   OPEN/READ INPUT_FILE UU:UCT_3D_LIST_HEADER_W_CTH.TXT"
$  WRITE OUTFILE "$   READ INPUT_FILE DATA_LINE"
$  WRITE OUTFILE "$   CLOSE INPUT_FILE
$  WRITE OUTFILE "$   DATA_LINE = ""AIM FILENAME	"" + DATA_LINE"
$  WRITE OUTFILE "$   OPEN/WRITE OUTPUT_FILE ''D3RESULT_ALL'"
$  WRITE OUTFILE "$   WRITE/SYMBOL OUTPUT_FILE DATA_LINE"
$  WRITE OUTFILE "$   CLOSE OUTPUT_FILE"
$  WRITE OUTFILE "$ ENDIF"    
$
$
$!EXTRACT NEW RESULT
$!---------------------------------------------------------------
$  WRITE OUTFILE "$ UCT_LIST"
$  WRITE OUTFILE "UU:UCT_3D_LIST_NOHEAD_W_CTH.TXT"
$  WRITE OUTFILE "''D3RESULT'"
$  WRITE OUTFILE "0" ! DEFAULT UNIT
$  WRITE OUTFILE "''MEAS_NO'"
$  WRITE OUTFILE "''MEAS_NO'"
$
$
$!ADD NEW RESULT TO SUMMARY RESULT FILE
$!---------------------------------------------------------------
$  WRITE OUTFILE "$ OPEN/READ INPUT_FILE ''D3RESULT'"
$  WRITE OUTFILE "$ READ INPUT_FILE DATA_LINE"
$  WRITE OUTFILE "$ CLOSE INPUT_FILE
$  WRITE OUTFILE "$ DATA_LINE = ""''FILENAME'	"" + DATA_LINE"
$  WRITE OUTFILE "$ OPEN/APPEND OUTPUT_FILE ''D3RESULT_ALL'"
$  WRITE OUTFILE "$ WRITE/SYMBOL OUTPUT_FILE DATA_LINE"
$  WRITE OUTFILE "$ CLOSE OUTPUT_FILE"
$  WRITE OUTFILE "$ DELETE ''D3RESULT';"
$  WRITE OUTFILE "$ EXIT"
$  CLOSE OUTFILE
$
$
$
$!------------------------------
$! RUN COMMAND FILE THEN DELETE IT
$!------------------------------
$
$  @'COMMAND_FILE'
$
$  SAY "!! EXTRACT_RESULTS.COM: completed"
$  SAY "=========================================================="
$
$  QUIT:
$  EXIT                         
