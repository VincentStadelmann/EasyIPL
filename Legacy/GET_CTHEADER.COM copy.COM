$!*************************************************            
$! GET__CTHEADER.COM
$! 2017.06.15 VS
$! 2017.10.31 VS __ notations
$! 2017.11.16 Added samp_namet
$! 2017.11.22 Remove skips since it is based on pipe
$! 
$! USAGE:
$!  @ue:get__ctheader.com	'isq_filename' 'log_filename' 'symbol'
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! GET__CTHEADER.COM: "
$ say "!!  Get SampleNo, MeasNo, SampleName, Dimensions, "
$ say "!!  Voxel size, ...	from ISQ file"
$ say "=========================================================="
$!*
$!
$ TRIM_TEXT: SUBROUTINE
$ SPEC = "_"
$ I = 0
$ TEMP = P2
$ START:
$ LEN = F$LENGTH(P2)
$ VAR = F$EXTRACT(I,1,TEMP)
$ IF (VAR .EQS. "." ) THEN TEMP[I,1] := 'SPEC'
$ IF (VAR .LTS. " ") THEN TEMP[I,1] := 'SPEC'
$ IF (VAR .LTS. "0") THEN TEMP[I,1] := 'SPEC'
$ IF (VAR .GTS. "9") .AND. (VAR .LTS. "A") THEN TEMP[I,1] := 'SPEC'
$ IF (VAR .GTS. "Z") .AND. (VAR .LTS. "_") THEN TEMP[I,1] := 'SPEC'
$ IF (VAR .EQS. "`") THEN TEMP[I,1] := 'SPEC'
$ IF (VAR .GTS. "z") THEN TEMP[I,1] := 'SPEC'
$ I = I + 1
$ IF (I .LT. LEN) THEN GOTO START
$ 'P1' :== 'TEMP'
$!
$ ENDSUBROUTINE
$
$ if p1 .eqs. "" then goto terminate
$ if p2 .eqs. "" then goto terminate
$
$   show symbol p1
$   show symbol p2
$   show symbol p3
$!
$! Prepare variable name
$ if (f$edit(p3, "upcase") .eqs. "NONE") then p3 = ""
$ if (p3 .eqs. "")
$   then 
$     variable_name = ""
$   else
$     variable_name := 'p3'__
$ endif
$ show symbol variable_name
$!
$! Search CT header
$!
$
$   pipe ctheader 'p1' | search sys$pipe "Patient Name :" | (read sys$input line ; define/job/nolog line_log &line)
$   samp_name == f$edit(f$trnlnm("line_log") - "Patient Name :", "trim,compress")
$   call trim_text samp_namet "''samp_name'"
$!
$   pipe ctheader 'p1' | search sys$pipe "Patient Index :" | (read sys$input line ; define/job/nolog line_log &line)
$   samp_no == f$edit(f$trnlnm("line_log") - "Patient Index :", "trim,compress")
$!
$   pipe ctheader 'p1' | search sys$pipe "Measurement Index :" | (read sys$input line ; define/job/nolog line_log &line)
$   meas_no == f$edit(f$trnlnm("line_log") - "Measurement Index :", "trim,compress")
$!
$   pipe ctheader 'p1' | search sys$pipe "Dim X :" | (read sys$input line ; define/job/nolog line_log &line)
$   isq_dim_x == f$element(0, " ", f$edit(f$trnlnm("line_log") - "Dim X :", "trim,compress"))
$   pipe ctheader 'p1' | search sys$pipe "Dim Y :" | (read sys$input line ; define/job/nolog line_log &line)
$   isq_dim_y == f$element(0, " ", f$edit(f$trnlnm("line_log") - "Dim Y :", "trim,compress"))
$   pipe ctheader 'p1' | search sys$pipe "Dim Z :" | (read sys$input line ; define/job/nolog line_log &line)
$   isq_dim_z == f$element(0, " ", f$edit(f$trnlnm("line_log") - "Dim Z :", "trim,compress"))
$!
$   pipe ctheader 'p1' | search sys$pipe "Voxel Size :" | (read sys$input line ; define/job/nolog line_log &line)
$   voxel_size_um == f$element(0, " ", f$edit(f$trnlnm("line_log") - "Voxel Size :", "trim,compress"))
$   icalc 'voxel_size_um' / 1000
$   voxel_size == icalc_out
$!
$ say "!!  Assigning values to variable"
$!
$   'variable_name'samp_name == samp_name
$   'variable_name'samp_namet == samp_namet
$   'variable_name'samp_no == samp_no
$   'variable_name'meas_no == meas_no
$   'variable_name'dim_x == isq_dim_x
$   'variable_name'dim_y == isq_dim_y
$   'variable_name'dim_z == isq_dim_z
$   'variable_name'vec_dim :== 'isq_dim_x','isq_dim_y','isq_dim_z'
$   'variable_name'voxel_size == voxel_size
$!
$   sh sym 'variable_name'*
$
$!
$ say "!!  "
$ say "!! GET_CTHEADER.COM: completed"
$ say "=========================================================="
$ exit
$
$ terminate:
$   say "!! P1: AIM input"
$   say "!! P2: LOG input"
$   say "!! P3: variable name output"
$   exit
