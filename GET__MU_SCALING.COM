$!*************************************************            
$! GET__MU_SCALING.COM
$! 2018.06.20
$! 
$! USAGE:
$!  @'scripts_dir'get__mu_scaling.com	'aim_filename' 'log_filename' 'variable_name'
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! GET__MU_SCALING.COM: 	"
$ say "=========================================================="
$!*
$
$ if p1 .eqs. "" then goto terminate
$ if p2 .eqs. "" then goto terminate
$!
$ show symbol p1
$ show symbol p2
$ show symbol p3
$!
$ if (f$edit(p3, "upcase") .eqs. "NONE") then p3 = ""
$ if (p3 .eqs. "")
$   then 
$     variable_name = ""
$   else
$     variable_name := 'p3'__
$ endif
$! show symbol variable_name
$!
$! Search AIM header
$   aix == "$ut:d3_io_examine.exe -l"
$!
$   pipe aix 'p1' | search sys$pipe "Patient Name" | (read sys$input line ; define/job line_log &line)
$   samp_name = f$edit(f$trnlnm("line_log") - "Patient Name", "trim,compress")
$   call trim_text samp_namet "''samp_name'"
$!
$   pipe aix 'p1' | search sys$pipe "Index Patient" | (read sys$input line ; define/job line_log &line)
$   samp_no = f$edit(f$trnlnm("line_log") - "Index Patient", "trim,compress")
$!
$   pipe aix 'p1' | search sys$pipe "Index Measurement" | (read sys$input line ; define/job line_log &line)
$   meas_no = f$edit(f$trnlnm("line_log") - "Index Measurement", "trim,compress")
$!
$   pipe aix 'p1' | search sys$pipe "Scanner ID" | (read sys$input line ; define/job line_log &line)
$   scanner_id = f$edit(f$trnlnm("line_log") - "Scanner ID", "trim,compress")
$!
$   pipe aix 'p1' | search sys$pipe "Mu_Scaling" | (read sys$input line ; define/job line_log &line)
$   Mu_Scaling = f$edit(f$trnlnm("line_log") - "Mu_Scaling", "trim,compress")
$!
$   pipe aix 'p1' | search sys$pipe "Calibration Data" | (read sys$input line ; define/job line_log &line)
$   Calibration_Data = f$edit(f$trnlnm("line_log") - "Calibration Data", "trim,compress")
$!
$   pipe aix 'p1' | search sys$pipe "Calib. default unit type" | (read sys$input line ; define/job line_log &line)
$   calibration_unit = f$edit(f$trnlnm("line_log") - "Calib. default unit type", "trim,compress")
$!
$   pipe aix 'p1' | search sys$pipe "Density: unit" | (read sys$input line ; define/job line_log &line)
$   density_unit = f$edit(f$trnlnm("line_log") - "Density: unit", "trim,compress")
$   if (density_unit .eqs. "mg HA/ccm") then density_unit = "mg HA per ccm"
$!
$   pipe aix 'p1' | search sys$pipe "Density: slope" | (read sys$input line ; define/job line_log &line)
$   Density_slope = f$edit(f$trnlnm("line_log") - "Density: slope", "trim,compress")
$!
$   pipe aix 'p1' | search sys$pipe "Density: intercept" | (read sys$input line ; define/job line_log &line)
$   Density_intercept = f$edit(f$trnlnm("line_log") - "Density: intercept", "trim,compress")
$!
$  'variable_name'samp_name == samp_name
$  'variable_name'samp_namet == samp_namet
$  'variable_name'samp_no   == samp_no
$  'variable_name'meas_no   == meas_no
$  'variable_name'scanner_id == scanner_id
$  'variable_name'Mu_Scaling == Mu_Scaling
$  'variable_name'Calibration_Data   == Calibration_Data
$  'variable_name'calibration_unit   == calibration_unit
$  'variable_name'density_unit == density_unit
$  'variable_name'Density_slope   == Density_slope
$  'variable_name'Density_intercept   == Density_intercept
$
$  sh sym 'variable_name'samp*
$  sh sym 'variable_name'meas*
$  sh sym 'variable_name'scanner_id*
$  sh sym 'variable_name'Mu_Scaling*
$  sh sym 'variable_name'Calibration*
$  sh sym 'variable_name'Density*
$  
$!
$ say "!! GET__MU_SCALING.COM: completed"
$ say "=========================================================="
$ exit
$
$ terminate:
$   say "!! P1: AIM input"
$   say "!! P2: LOG input"
$   say "!! P3: variable name output"
$   exit
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