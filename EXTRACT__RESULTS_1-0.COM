$!******************************************************************************************            
$! EXTRACT__RESULTS.COM:
$! run uct-list and write results to a summary file
$! Based on HELEN BUIE's extract_result.com (Oct. 2010)
$! 2012.01.10 V Stadelmann 
$! 2017.07.20 VS: P3 FOR TEMPLATE
$!
$! Run uct-list and write results to a summary file
$!  P1 : AIM NAME
$!  P2 : ISQ NAME
$!  P3 : TEMPLATE
$!  P4 : DCL VARIABLES
$!
$! USAGE:
$!   @'scripts_dir'extract__results.com	'input_filename' 'results_filename' 'template' 'dcl_variables_list'
$!******************************************************************************************        
$!    
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! EXTRACT__RESULTS.COM: "
$ say "=========================================================="
$!
$ if p1 .eqs. "" then goto quit
$ if p2 .eqs. "" then goto quit
$ 
$ GSRTPU_TEMPLATE	:= UU:GSR.TPU 	                               ! global search replace tpu commands template
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
$
$! DEFINE REQUIRED PARAMETERS
$  ipl_aim        = p1
$  d3result_all   = p2
$!
$  sh sym ipl_aim
$  sh sym d3result_all
$  filename       = f$parse(ipl_aim,,,"name")
$  d3result	      = ipl_aim - ".AIM" + "_RES.TXT"
$  command_file    = ipl_aim - ".AIM" + "_RES.COM"
$  gsrtpu_tmp_file = ipl_aim - ".AIM" + "_GSR_JSW.TPU"	 
$!
$  sh sym filename
$  sh sym d3result
$  sh sym command_file
$  sh sym gsrtpu_tmp_file
$
$! SEARCH AIM HEADER FOR MEASUREMENT NUMBER
$  aix == "$ut:d3_io_examine.exe -l"
$  pipe aix 'ipl_aim' | search sys$pipe "index measurement"| (read sys$input line ; define/job line_log &line)
$  line_sym = f$trnlnm("line_log")
$  meas_no = f$extract(45,8,line_sym)
$  meas_no = f$edit(meas_no,"trim,compress")
$  sh sym meas_no
$  if meas_no .eqs. "" 
$   then 
$     say "!! Error:  could not get measurement number."
$     goto quit 
$  endif
$
$! COPY HEADER FILE IF RESULT FILE NOT FOUND
$   OPEN/WRITE OUTFILE 'COMMAND_FILE'
$   WRITE OUTFILE "$ say = ""write sys$output"" "
$   WRITE OUTFILE "$ say ""!! Reading out 3d result database "" "
$   WRITE OUTFILE "$!"
$   WRITE OUTFILE "$ if f$search(""''d3result_all'"") .eqs. """" "
$   WRITE OUTFILE "$ then"
$   WRITE OUTFILE "$   open/read input_file ''p3'"
$   WRITE OUTFILE "$   read input_file data_line"
$   WRITE OUTFILE "$   close input_file
$   WRITE OUTFILE "$   open/write output_file ''d3result_all'"
$   WRITE OUTFILE "$   write/symbol output_file data_line"
$   WRITE OUTFILE "$   close output_file"
$   WRITE OUTFILE "$ endif"    
$
$! EXTRACT NEW RESULT
$   WRITE OUTFILE "$ uct_list"
$   WRITE OUTFILE "''p3'"
$   WRITE OUTFILE "''d3result'"
$   WRITE OUTFILE "0" ! default unit
$   WRITE OUTFILE "''meas_no'"
$   WRITE OUTFILE "''meas_no'"
$
$! REPLACE VARIABLES IN d3result
$   call get_list_length n_vars 'p4'
$   SH SYM N_VARS
$   if (n_vars .gt. 0) 
$    then
$     WRITE OUTFILE "$ Say ""!! Replacing DCL Variables in d3result""  "
$	  I = 0
$ 	  LOOP_GSR:
$   	VAR_I = f$element(I,",",P4)
$       IF F$TYPE('VAR_I') .EQS. "" THEN 'VAR_I' == "-" 
$       SH SYM 'VAR_I'
$   	VAR_I_STR = "'"+"''VAR_I'"+"'"
$   	WRITE OUTFILE "$  SAY ""VAR_''I': ''VAR_I'""  "
$!   	WRITE OUTFILE "$  IF F$TYPE(''VAR_I_STR') .EQS. """" THEN ''VAR_I_STR' == ""-"" "
$   	WRITE OUTFILE "$  TPU_''I' := global_search_replace (""""""""||''VAR_I'||"""""""", """"""""''VAR_I_STR'""""""""); "
$   	WRITE OUTFILE "$  SHOW SYM TPU_''I' "
$   	WRITE OUTFILE "$  COPY ''GSRTPU_TEMPLATE' ''gsrtpu_tmp_file' "
$   	WRITE OUTFILE "$  OPEN/APPEND GSRTPUFILE ''gsrtpu_tmp_file' "
$   	WRITE OUTFILE "$  WRITE/SYMBOL GSRTPUFILE TPU_''I' "
$   	WRITE OUTFILE "$  WRITE GSRTPUFILE ""EXIT;"" "
$   	WRITE OUTFILE "$  CLOSE GSRTPUFILE "
$   	WRITE OUTFILE "$  EDIT/TPU/NOSECTION/COMMAND=''gsrtpu_tmp_file'/NODISPLAY ''D3RESULT' " 
$   	WRITE OUTFILE "$!  DELETE ''gsrtpu_tmp_file';* "
$   	WRITE OUTFILE "$  SAY "" "" "
$ 	  I = I + 1
$ 	  IF (I .LT. N_VARS) THEN GOTO LOOP_GSR
$    endif
$
$
$! READ RESULT FILE
$   WRITE OUTFILE "$ open/read input_file ''d3result'"
$   WRITE OUTFILE "$ read input_file header_line"
$   WRITE OUTFILE "$ sh sym header_line"
$   WRITE OUTFILE "$ read input_file data_line" ! Second line
$   WRITE OUTFILE "$ sh sym data_line"
$   WRITE OUTFILE "$ close input_file"
$
$! ADD NEW RESULT TO SUMMARY RESULT FILE
$   WRITE OUTFILE "$ open/append output_file ''d3result_all'"
$   WRITE OUTFILE "$ write/symbol output_file data_line"
$   WRITE OUTFILE "$ close output_file"
$   WRITE OUTFILE "$ delete ''d3result';"
$   WRITE OUTFILE "$ exit"
$   close outfile
$
$
$
$! RUN COMMAND FILE THEN DELETE IT$
$  @'COMMAND_FILE'
$
$  say "!! "
$  say "!! extract__results.com: completed"
$  say "=========================================================="
$  exit
$
$  quit:
$    say ""
$    say "!! Usage:" 
$    say "!! p1 = aim filename, include full path"
$    say "!! p2 = text filename for project results, include full path"
$    say "!! p3 = template file for output"
$    say "!! p4 = DCL variable names list (v1,v2,v3...)"
$    say ""
$  exit   
$
$!===========================
$ GET_LIST_LENGTH: SUBROUTINE
$! usage:
$! 	call get_list_length list_length_symbol "e1,e2,e3,..."
$! or
$! 	call get_list_length list_length_symbol 'list_symbol'
$!
$ j = 0
$ len = f$length(p2)
$! sh sym len
$ if (len .eq. 0) then 'p1' == 0
$ start:
$   el_j = f$element(j,",","''p2'")
$!   sh sym el_j
$   if ("''el_j'" .eqs. ",") 
$     then
$     'p1' == j
$     exit
$   endif
$   j = j + 1
$   if (j .le. len) then goto start
$ endsubroutine
$!===========================
$
