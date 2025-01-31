$!*************************************************            
$! GET__NAME_NO.COM
$! 2016.11.29 VS
$! 2017.11.16 Added samp_namet
$! 2017.11.22 Remove skips since it is based on "pipe aix" not "pipe search"
$! 
$! USAGE:
$!  @'scripts_dir'get__name_no.com	'aim_filename' 'log_filename' 'variable_name'
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! GET__NAME_NO.COM: Get SampleNo, MeasNo, SampleName	"
$ say "=========================================================="
$!*
$
$ if p1 .eqs. "" then goto terminate
$ if p2 .eqs. "" then goto terminate
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$
$! Prepare variable name
$ if (f$edit(p3, "upcase") .eqs. "NONE") then p3 = ""
$ if (p3 .eqs. "")
$   then 
$     variable_name = ""
$   else
$     variable_name := 'p3'__
$ endif
$ show symbol variable_name
$
$! Search AIM header
$   aix == "$ut:d3_io_examine.exe -l"
$!
$   pipe aix 'p1' | search sys$pipe "Patient Name" | (read sys$input line ; define/job/nolog line_log &line)
$   samp_name = f$edit(f$trnlnm("line_log") - "Patient Name", "trim,compress")
$   call trim_text samp_namet "''samp_name'"
$!   sh sym samp_name
$!
$   pipe aix 'p1' | search sys$pipe "Index Patient" | (read sys$input line ; define/job/nolog line_log &line)
$   samp_no = f$edit(f$trnlnm("line_log") - "Index Patient", "trim,compress")
$!   sh sym samp_no
$!
$   pipe aix 'p1' | search sys$pipe "Index Measurement" | (read sys$input line ; define/job/nolog line_log &line)
$   meas_no = f$edit(f$trnlnm("line_log") - "Index Measurement", "trim,compress")
$!   sh sym meas_no
$!
$  'variable_name'samp_name == samp_name
$  'variable_name'samp_namet == samp_namet
$  'variable_name'samp_no   == samp_no
$  'variable_name'meas_no   == meas_no
$  sh sym 'variable_name'samp*
$  sh sym 'variable_name'meas*
$  
$!
$ say "!! GET__NAME_NO.COM: completed"
$ say "=========================================================="
$ exit
$ terminate:
$   say "!! P1: AIM input"
$   say "!! P2: LOG input"
$   say "!! P3: variable name output"
$   exit
$
$
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
