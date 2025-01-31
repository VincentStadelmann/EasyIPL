$!************************* EZ_IPL *****************************************           
$!
$! GET_AIM_HEADER.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2019.03.08
$!  Copyright (c) 2011-2019 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Get SampleNo, MeasNo, SampleName 
$!  Voxel size, mu scaling, ...	from AIM file
$! 
$! USAGE:
$!  @ez:get_aim_header 'aim_name' variable_name
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2* : Variable out         (*aim) 
$!
$! EXAMPLE:
$!
$!
$! VERSION HISTORY:
$!  2016.11.29 VS
$!  2017.11.16 Added samp_namet
$!  2017.11.22 Remove skips since it is based on "pipe aix" not "pipe search"
$!  2018.12.18 EZ format + rename
$!  2019.03.08 Combine get_info and get_mu_scaling
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! GET_AIM_HEADER.COM: "
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
$!
$! Search AIM header
$  call pipe_aix 'p1' "Patient Name" __gah_samp_name
$
$  call trim_text "''__gah_samp_name'"  __gah_samp_namet
$  'p2'__samp_name == __gah_samp_name
$  'p2'__samp_namet == __gah_samp_namet
$
$  call pipe_aix 'p1' "Index Patient" 'p2'__samp_no
$  call pipe_aix 'p1' "Index Measurement" 'p2'__meas_no
$  call pipe_aix 'p1' "Scanner ID" 'p2'__scanner_id
$  call pipe_aix 'p1' "Mu_Scaling" 'p2'__Mu_Scaling
$
$  call pipe_aix 'p1' "Calibration Data" __gah_Calibration_Data
$  'p2'__Calibration_Data == __gah_Calibration_Data
$
$  ! parse Calibration
$  if (f$locate(",", __gah_Calibration_Data) .nes. f$length(__gah_Calibration_Data)) 
$    then 
$      'p2'__tube_tension == f$element(0,",",__gah_Calibration_Data)
$      'p2'__filter ==  f$edit(f$element(1,",",__gah_Calibration_Data), "trim,compress")
$      'p2'__BH == f$edit(f$element(2,",",__gah_Calibration_Data) - "BH:", "trim,compress")
$  endif
$
$  call pipe_aix 'p1' "Calib. default unit type" 'p2'__calibration_unit
$
$  call pipe_aix 'p1' "Density: unit" __gah_density_unit
$  if ("''__gah_density_unit'" .eqs. "mg HA/ccm") then __gah_density_unit == "mg HA per ccm"
$ 'p2'__density_unit == __gah_density_unit
$
$  call pipe_aix 'p1' "Density: slope" 'p2'__Density_slope
$  call pipe_aix 'p1' "Density: intercept" 'p2'__Density_intercept
$
$  sh sym 'p2'__*
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
$ say "!! GET_AIM_HEADER.COM: completed"
$ say "=========================================================="
$ exit
$
$ terminate:
$    @ez:helper GET_AIM_HEADER.com
$   exit