$!************************* EZ_IPL *****************************************           
$!
$! EXPORT_RESULTS.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2012.01.10
$!  Copyright (c) 2011-2019 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Fills in result sheet with data from database and active dcl variables
$! 
$! USAGE:
$!  @ez:export_results 'aim_file' 'res_file' 'template' 'dcl_vars' 'measno'
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2  : Output results file
$!  P3* : Template file                       (*UU:UCT_3D_LIST.TXT)
$!  P4* : Additional DCL variables to export  (*none)
$!  P5* : Force measurement number in export  (*none)
$!
$! EXAMPLE:
$!  
$!
$! VERSION HISTORY:
$!  2012.01.10 Adapted from on HELEN BUIE's extract_result.com (Oct. 2010)
$!  2017.07.20 P3 FOR TEMPLATE
$!  2017.11.07 EDIT/TPU -> EDIT/EDT no need for GSR template
$!  2018.01.17 P5: MeasNo -> force MeasNo when working with re-imported data
$!  2019.03.20 EZ format
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ set output_rate=00:00:01
$ say " "
$ say "=========================================================="
$ say "!! EXPORT_RESULTS.COM:   "
$ say "=========================================================="
$!*
$!
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then goto terminate
$
$ if f$search("''p1'") .eqs. ""
$  then
$    say "!! ERROR:  aim file does not exist."
$    goto terminate
$ endif
$!
$ p1 = p1 - f$parse(p1,,,"version")
$ checkaim = f$extract(f$length(p1)-3,3,p1)       
$ if (checkaim .nes. "AIM" )
$  then
$    say "!! ERROR:  input file not an AIM"
$    goto terminate
$ endif
$
$ if (p3 .eqs. "") then p3 := uu:uct_3d_list.txt
$ if f$search("''p3'") .eqs. ""
$  then
$    say "!! ERROR:  template file does not exist."
$    goto terminate
$ endif
$
$ sh sym p1
$ sh sym p2
$ sh sym p3
$ sh sym p4
$ sh sym p5
$
$! DEFINE REQUIRED PARAMETERS
$  __aim_file       = p1
$  __d3result_all   = p2
$  __var_list       = p4
$  __var_list       = f$edit(__var_list, "collapse")
$ sh sym __var_list*
$!
$  sh sym __aim_file
$  sh sym __d3result_all
$  __filename     = f$parse(__aim_file,,,"name")
$  __d3result	      = __aim_file - ".AIM" + "_RES.TXT"
$  __command_file   = __aim_file - ".AIM" + "__RES.COM"
$  __edt_tmp_file   = __aim_file - ".AIM" + "__RES.EDT"
$!
$  sh sym __filename
$  sh sym __d3result
$  sh sym __command_file
$
$  if (p5 .nes. "" )
$   then
$    meas_no = p5
$   else
$    ! SEARCH AIM HEADER FOR MEASUREMENT NUMBER
$    aix == "$ut:d3_io_examine.exe -l"
$    pipe aix '__aim_file' | search sys$pipe "index measurement"| (read sys$input line ; define/job/nolog line_log &line)
$    line_sym = f$trnlnm("line_log")
$    meas_no = f$extract(45,8,line_sym)
$    meas_no = f$edit(meas_no,"trim,compress")
$  endif
$  sh sym meas_no
$  if (meas_no .eqs. "")
$   then 
$     say "!! Error:  could not get measurement number."
$     goto terminate 
$  endif
$
$! Copy header file if result file not found
$   open/write outfile '__command_file'
$   write outfile "$ say = ""write sys$output"" "
$
$   ! Reading out 3d result database 
$   write outfile "$ if f$search(""''__d3result_all'"") .eqs. """" "
$   write outfile "$ then"
$   write outfile "$   open/read input_file ''p3'"
$   write outfile "$   read input_file data_line"
$   write outfile "$   close input_file
$   write outfile "$   open/write output_file ''__d3result_all'"
$   write outfile "$   write/symbol output_file data_line"
$   write outfile "$   close output_file"
$   write outfile "$ endif"    
$
$! Extract new result
$   write outfile "$ uct_list"
$   write outfile "''p3'"
$   write outfile "''__d3result'"
$   write outfile "0" ! default unit
$   write outfile "''meas_no'"
$   write outfile "''meas_no'"
$
$! Replace variables in __d3result
$   if (p4 .eqs. "") then goto __export_results
$   call get_list_length n_vars '__var_list'
$   sh sym n_vars
$   if (n_vars .gt. 0) 
$    then
$   ! Loop through var_i to create the replacements list
$       i = 0
$       write outfile "$ open/write edtfile ''__edt_tmp_file' "
$       loop_edt:
$         var_i = f$element(i,",",__var_list)
$         var_i_str = "'"+"''var_i'"+"'"
$         write outfile "$ write sys$output ""  ''i' var_''i': ''var_i'  ""  "
$         write outfile "$ if f$type(''var_i') .eqs. """" then ''var_i' == ""-"" "
$         write outfile "$ edt_''i' := substitute/||''var_i'||/''var_i_str'/whole "
$         write outfile "$ write/symbol edtfile edt_''i' "
$ 	      i = i + 1
$ 	      if (i .lt. n_vars) then goto loop_edt
$!
$       write outfile "$ write edtfile ""exit/save"" " 
$       write outfile "$ close edtfile " 
$      ! Replace values in spreadsheet one-liner
$       write outfile "$ edit/edt/nojournal/command=''__edt_tmp_file' ''__d3result' " 
$   endif
$
$! read result file
$   __export_results:
$   write outfile "$ open/read input_file ''__d3result'"
$   write outfile "$ read input_file header_line"
$   write outfile "$ sh sym header_line"
$   write outfile "$ read input_file data_line" ! second line
$   write outfile "$ sh sym data_line"
$   write outfile "$ close input_file"
$
$! add new result to summary result file
$   write outfile "$ open/append output_file ''__d3result_all'"
$   write outfile "$ write/symbol output_file data_line"
$   write outfile "$ close output_file"
$   write outfile "$ exit"
$   close outfile
$
$! Run command file
$  @'__command_file'
$  delete '__command_file';*
$  delete '__d3result';*
$
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
$
$  say "!! Results file: ''__d3result_all'"
$  say "!! EXPORT_RESULTS.COM: completed"
$  say "=========================================================="
$  exit
$
$
$ terminate:
$    @ez:helper EXPORT_RESULTS.com
$ exit 
$
