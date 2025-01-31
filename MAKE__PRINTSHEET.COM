$!******************************************************************************************            
$! EXTRACT__RESULTS.COM:
$! run uct-list and write results to a summary file
$! Based on HELEN BUIE's extract_result.com (Oct. 2010)
$! 2012.01.10 V Stadelmann 
$! 2017.07.20 VS: P3 FOR TEMPLATE
$! 2017.11.07 VS: EDIT/TPU -> EDIT/EDT no need for GSR template
$! 2018.01.17 VS: P5: MeasNo -> force MeasNo when working with re-imported data
$!
$! Run uct-list and write results to a summary file
$!  P1 : AIM NAME
$!  P2 : RESULTS_FILENAME
$!  P3 : TEMPLATE
$!  P4 : DCL VARIABLES
$!
$! USAGE:
$!   @'scripts_dir'extract__results.com	'input_filename' 'results_filename' 'template*' 'dcl_variables_list*' 'measno*'
$!******************************************************************************************        
$
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! EXTRACT__RESULTS.COM: V2"
$ say "=========================================================="
$!*
$!
$ if p1 .eqs. "" then goto quit
$ if p2 .eqs. "" then goto quit
$
$ if f$search("''p1'") .eqs. ""
$  then
$    say "!! Error:  aim file does not exist."
$    goto quit
$ endif
$!
$ p1 = p1 - f$parse(p1,,,"version")
$ checkaim = f$extract(f$length(p1)-3,3,p1)       
$ if (checkaim .nes. "AIM" )
$  then
$    say "!! Error:  input file not an AIM"
$    goto quit
$ endif
$
$ if (p3 .eqs. "") then p3 := uu:uct_3d_list.txt
$ if f$search("''p3'") .eqs. ""
$  then
$    say "!! Error:  template file does not exist."
$    goto quit
$ endif
$
$ sh sym p1
$ sh sym p2
$ sh sym p3
$ sh sym p4
$ sh sym p5
$
$! DEFINE REQUIRED PARAMETERS
$  ipl_aim        = p1
$  d3result_all   = p2
$  var_list       = p4
$!
$  sh sym ipl_aim
$  sh sym d3result_all
$  filename       = f$parse(ipl_aim,,,"name")
$  d3result	      = ipl_aim - ".AIM" + "_RES.TXT"
$  command_file    = ipl_aim - ".AIM" + "__RES.COM"
$  edt_tmp_file    = ipl_aim - ".AIM" + "__RES.EDT"
$!
$  sh sym filename
$  sh sym d3result
$  sh sym command_file
$
$  if (p5 .nes. "" )
$   then
$    meas_no = p5
$   else
$    ! SEARCH AIM HEADER FOR MEASUREMENT NUMBER
$    aix == "$ut:d3_io_examine.exe -l"
$    pipe aix 'ipl_aim' | search sys$pipe "index measurement"| (read sys$input line ; define/job line_log &line)
$    line_sym = f$trnlnm("line_log")
$    meas_no = f$extract(45,8,line_sym)
$    meas_no = f$edit(meas_no,"trim,compress")
$  endif
$  sh sym meas_no
$  if (meas_no .eqs. "")
$   then 
$     say "!! Error:  could not get measurement number."
$     goto quit 
$  endif
$
$! COPY HEADER FILE IF RESULT FILE NOT FOUND
$   OPEN/WRITE OUTFILE 'COMMAND_FILE'
$   WRITE OUTFILE "$ SAY = ""WRITE SYS$OUTPUT"" "
$   WRITE OUTFILE "$ SAY ""!! READING OUT 3D RESULT DATABASE "" "
$   WRITE OUTFILE "$!"
$   WRITE OUTFILE "$ IF F$SEARCH(""''D3RESULT_ALL'"") .EQS. """" "
$   WRITE OUTFILE "$ THEN"
$   WRITE OUTFILE "$   OPEN/READ INPUT_FILE ''P3'"
$   WRITE OUTFILE "$   READ INPUT_FILE DATA_LINE"
$   WRITE OUTFILE "$   CLOSE INPUT_FILE
$   WRITE OUTFILE "$   OPEN/WRITE OUTPUT_FILE ''D3RESULT_ALL'"
$   WRITE OUTFILE "$   WRITE/SYMBOL OUTPUT_FILE DATA_LINE"
$   WRITE OUTFILE "$   CLOSE OUTPUT_FILE"
$   WRITE OUTFILE "$ ENDIF"    
$
$! EXTRACT NEW RESULT
$   WRITE OUTFILE "$ UCT_LIST"
$   WRITE OUTFILE "''P3'"
$   WRITE OUTFILE "''D3RESULT'"
$   WRITE OUTFILE "0" ! DEFAULT UNIT
$   WRITE OUTFILE "''MEAS_NO'"
$   WRITE OUTFILE "''MEAS_NO'"
$   WRITE OUTFILE " "
$
$! REPLACE VARIABLES IN D3RESULT
$   IF (P4 .EQS. "") THEN GOTO EXPORTRESULTS
$   CALL GET_LIST_LENGTH N_VARS 'VAR_LIST'
$   SH SYM N_VARS
$   IF (N_VARS .GT. 0) 
$    THEN
$     WRITE OUTFILE "$ Say ""!! Replacing DCL Variables in d3result""  "
$   ! Loop through VAR_I to create the replacements list
$       I = 0
$       WRITE OUTFILE "$ OPEN/WRITE EDTFILE ''EDT_TMP_FILE' "
$       LOOP_EDT:
$         VAR_I = f$element(I,",",VAR_LIST)
$         VAR_I_STR = "'"+"''VAR_I'"+"'"
$         WRITE OUTFILE "$ WRITE SYS$OUTPUT ""  ''I' VAR_''I': ''VAR_I'  ""  "
$         WRITE OUTFILE "$ IF F$TYPE(''VAR_I') .EQS. """" THEN ''VAR_I' == ""-"" "
$         WRITE OUTFILE "$ EDT_''I' := SUBSTITUTE/||''VAR_I'||/''VAR_I_STR'/WHOLE "
$         WRITE OUTFILE "$ WRITE/SYMBOL EDTFILE EDT_''I' "
$ 	      I = I + 1
$ 	      IF (I .LT. N_VARS) THEN GOTO LOOP_EDT
$!
$       WRITE OUTFILE "$ WRITE EDTFILE ""EXIT/SAVE"" " 
$       WRITE OUTFILE "$ CLOSE EDTFILE " 
$       WRITE OUTFILE "$ WRITE SYS$OUTPUT ""> Replacing values in one-liner results""  "
$       WRITE OUTFILE "$ EDIT/EDT/NOJOURNAL/COMMAND=''EDT_TMP_FILE' ''D3RESULT' " ! replace values in spreadsheet one-liner
$   ENDIF
$
$! Read result file
$   EXPORTRESULTS:
$   WRITE OUTFILE "$ OPEN/READ INPUT_FILE ''D3RESULT'"
$   WRITE OUTFILE "$ READ INPUT_FILE HEADER_LINE"
$   WRITE OUTFILE "$ SH SYM HEADER_LINE"
$   WRITE OUTFILE "$ READ INPUT_FILE DATA_LINE" ! second line
$   WRITE OUTFILE "$ SH SYM DATA_LINE"
$   WRITE OUTFILE "$ CLOSE INPUT_FILE"
$
$! Add new result to summary result file
$   WRITE OUTFILE "$ OPEN/APPEND OUTPUT_FILE ''D3RESULT_ALL'"
$   WRITE OUTFILE "$ WRITE/SYMBOL OUTPUT_FILE DATA_LINE"
$   WRITE OUTFILE "$ CLOSE OUTPUT_FILE"
$   WRITE OUTFILE "$ DELETE ''D3RESULT';"
$   WRITE OUTFILE "$ EXIT"
$   close outfile
$
$! Run command file
$  @'COMMAND_FILE'
$
$  say "!! "
$  say "!! EXTRACT__RESULTS.COM: completed"
$  say "=========================================================="
$
$  exit
$
$  quit:
$    say ""
$    say "!! Usage:" 
$    say "!! P1 = aim filename, include full path"
$    say "!! P2 = text filename for project results, include full path"
$    say "!! P3 = template file for output"
$    say "!! P4 = DCL variable names list (v1,v2,v3...)"
$    say "!! P5 = MeasNo (for reimported data)"
$    say ""
$  exit   
$
$!    
$!===========================
$ get_list_length: subroutine
$! usage:
$! 	call get_list_length list_length_symbol "e1,e2,e3,..."
$! or
$! 	call get_list_length list_length_symbol 'list_symbol'
$!
$ if (p2 .eqs. "")  then len = 0
$ if (p2 .nes. "")  then len = f$length(p2)
$ if (p2 .eqs. ",") then len = 0
$
$ j = 0
$ if (len .gt. 0) 
$   then 
$     j_loop_start:
$       el_j = f$element(j,",","''p2'")
$       if ("''el_j'" .eqs. ",") then goto j_loop_exit 
$       j = j + 1
$       if (j .le. len) then goto j_loop_start
$ endif
$
$ j_loop_exit:
$  'p1' == j
$ endsubroutine
$!===========================
$
