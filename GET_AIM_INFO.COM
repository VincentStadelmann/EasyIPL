$!************************* EZ_IPL *****************************************           
$!
$! GET_AIM_INFO.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2011.09.20
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Get SampleNo, MeasNo, SampleName into a variable
$!
$! OUTPUTS:
$!  (aim)__samp_name:  Sample Name
$!  (aim)__samp_namet: Sample Name (trimmed, no spaces) 
$!  (aim)__samp_no:    Sample Number
$!  (aim)__meas_no:    Measurement Number
$! 
$! USAGE:
$!  @ez:get_aim_info 'aim_name' variable_name
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2* : Variable out         (*AIM) 
$!
$! EXAMPLE:
$!  @ez:get_aim_info 'file.aim' a
$!  will generate the variables a__samp_name, a__samp_no and a__meas_no
$!
$! VERSION HISTORY:
$!  2016.11.29 VS
$!  2017.11.16 Added samp_namet
$!  2017.11.22 Remove skips since it is based on "pipe aix" not "pipe search"
$!  2018.12.18 EZ format + rename
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! GET_AIM_INFO.COM: "
$ say "=========================================================="
$!*
$
$ if p1 .eqs. "" then goto terminate
$ if (p2 .eqs. "") then p2 = "aim"
$ show symbol p1
$ show symbol p2
$
$ if (f$search(p1) .eqs. "") then goto file_not_found
$
$! Prepare output variable name
$ if (f$edit(p2, "upcase") .eqs. "NONE") then p2 = ""
$ if (p2 .eqs. "")
$   then 
$     __gai_var_name = ""
$   else
$     __gai_var_name := 'p2'__
$ endif
$ !show symbol __gai_var_name
$
$!
$! Search CT header
$  call pipe_aix 'p1' "Patient Name" '__gai_var_name'samp_name
$  call pipe_aix 'p1' "Index Patient" '__gai_var_name'samp_no
$  call pipe_aix 'p1' "Index Measurement" '__gai_var_name'meas_no
$!
$  __gai_samp_name = '__gai_var_name'samp_name
$  call trim_text "''__gai_samp_name'"  '__gai_var_name'samp_namet
$
$  sh sym '__gai_var_name'samp*
$  sh sym '__gai_var_name'meas*
$  
$ subroutines:
$!==========================================================            
$! Subroutine trim_text adapted from Tomi Koller 
$ TRIM_TEXT: SUBROUTINE
$   __TT_SPEC = "_"
$   __TT_TEMP = f$edit(P1, "trim,compress")
$   I = 0
$   START:
$    LEN = F$LENGTH(__TT_TEMP)
$    VAR = F$EXTRACT(I,1,__TT_TEMP)
$    IF (VAR .EQS. "." ) THEN __TT_TEMP[I,1] := '__TT_SPEC'
$    IF (VAR .LTS. " ") THEN __TT_TEMP[I,1] := '__TT_SPEC'
$    IF (VAR .LTS. "0") THEN __TT_TEMP[I,1] := '__TT_SPEC'
$    IF (VAR .GTS. "9") .AND. (VAR .LTS. "A") THEN __TT_TEMP[I,1] := '__TT_SPEC'
$    IF (VAR .GTS. "Z") .AND. (VAR .LTS. "_") THEN __TT_TEMP[I,1] := '__TT_SPEC'
$    IF (VAR .EQS. "`") THEN __TT_TEMP[I,1] := '__TT_SPEC'
$    IF (VAR .GTS. "z") THEN __TT_TEMP[I,1] := '__TT_SPEC'
$    I = I + 1
$    IF (I .LT. LEN) THEN GOTO START
$   'P2' :== '__TT_TEMP'
$ ENDSUBROUTINE
$!==========================================================  
$! Subroutine pipe ct_header 
$ PIPE_AIX: SUBROUTINE
$! Search AIM header
$   aix = "$ut:d3_io_examine.exe -l"
$
$   __pch_aim  = p1
$   __pch_text = p2
$   __pch_sym  = p3
$
$   pipe aix '__pch_aim' | search sys$pipe "''__pch_text'" | (read sys$input line ; define/job/nolog line_log &line)
$   '__pch_sym' == f$edit(f$trnlnm("line_log") - "''__pch_text'", "trim,compress")
$
$ ENDSUBROUTINE
$!==========================================================            
$ goto complete
$  
$ file_not_found:
$ say "  "
$ say "!! "
$ say "!! ERROR:  AIM file not found"
$ say "!! "
$ 
$ complete:
$ say "  "
$! #
$ say "!! GET_AIM_INFO.COM: completed"
$ say "=========================================================="
$ exit
$
$ terminate:
$    @ez:helper GET_AIM_INFO.com
$   exit