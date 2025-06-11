$!************************* EZ_IPL *****************************************           
$!
$! GET_MU_SCALING.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.06.20
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Get AIM calibration into a symbol 
$! 
$! USAGE:
$!  @ez:get__mu_scaling 'aim_file' 'variable' 'log_file'
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2  : Variable out         
$!  P3* : Log filename         (*eval_logfile2)         
$!
$! EXAMPLE:
$!  
$!
$! 
$! VERSION HISTORY:
$!  2018.06.20 VS
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ set output_rate=00:00:01
$ say " "
$ say "=========================================================="
$ say "!! GET_MU_SCALING.COM:	"
$ say "=========================================================="
$!*
$
$ if p1 .eqs. "" then goto terminate
$ if p2 .eqs. "" then goto terminate
$ if (p3 .eqs. "") then p3 = eval_logfile2
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$
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
$  'p3'__samp_name == samp_name
$  'p3'__samp_namet == samp_namet
$  'p3'__samp_no   == samp_no
$  'p3'__meas_no   == meas_no
$  'p3'__scanner_id == scanner_id
$  'p3'__Mu_Scaling == Mu_Scaling
$  'p3'__Calibration_Data   == Calibration_Data
$  'p3'__calibration_unit   == calibration_unit
$  'p3'__density_unit == density_unit
$  'p3'__Density_slope   == Density_slope
$  'p3'__Density_intercept   == Density_intercept
$
$  sh sym 'p3'__samp*
$  sh sym 'p3'__meas*
$  sh sym 'p3'__scanner_id*
$  sh sym 'p3'__Mu_Scaling*
$  sh sym 'p3'__Calibration*
$  sh sym 'p3'__Density*
$  
$!
$ say "!! GET_MU_SCALING.COM: completed"
$ say "=========================================================="
$ exit
$
$ terminate:
$    @ez:helper GET_MU_SCALING
$ exit
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