$!************************* EZ_IPL *****************************************           
$!
$! GET_ISQ_HEADER.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2011.09.20
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Get SampleNo, MeasNo, SampleName, Dimensions, "
$!  Voxel size, ...	from ISQ file"
$! 
$! USAGE:
$!  @ez:get_isq_header.com	'isq_filename'  variable_out 
$!
$! PARAMETERS:
$!  P1  : Input iSQ file
$!  P2* : variable out          (*isq)
$!
$! EXAMPLE:
$!  Get the sample name of image.isq into the variable export_filename 
$!  (format usable for a filename), using default logfile
$!   @ez:get_isq_header.com	 'isq_filename'  isq
$!   export_filename = isq__samp_namet
$!
$! VERSION HISTORY:
$!  2017.10.31 __ notations
$!  2017.11.16 Added __gih_samp_namet
$!  2017.11.22 Remove skips since it is based on pipe
$!  2018.10.25 NONE not an option for variable name
$!  2018.10.25 Removed logfile from params
$!  2018.10.26 EZ format
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! GET_ISQ_HEADER.COM: "
$ say "=========================================================="
$!*
$
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 = "isq"
$ show symbol p1
$ show symbol p2
$ if (f$search(p1) .eqs. "") then goto file_not_found
$
$! Prepare output variable name
$ if (f$edit(p2, "upcase") .eqs. "NONE") then p2 = ""
$ if (p2 .eqs. "")
$   then 
$     __gih_var_name = ""
$   else
$     __gih_var_name := 'p2'__
$ endif
$ !show symbol __gih_var_name
$
$! Search CT header
$  call pipe_ctheader 'p1' "Patient Name :"        __gih_samp_name
$  '__gih_var_name'samp_name == __gih_samp_name
$  call trim_text  "''__gih_samp_name'"            '__gih_var_name'samp_namet
$  call pipe_ctheader 'p1' "Patient Index :"       '__gih_var_name'samp_no
$  call pipe_ctheader 'p1' "Measurement Index :"   '__gih_var_name'meas_no
$  call pipe_ctheader 'p1' "Creation Date :"       '__gih_var_name'creation_date
$  call pipe_ctheader 'p1' "Dim X :"               __gih_dim_x
$  call pipe_ctheader 'p1' "Dim Y :"               __gih_dim_y
$  call pipe_ctheader 'p1' "Dim Z :"               __gih_dim_z
$  call pipe_ctheader 'p1' "Voxel Size :"          __gih_vx_size
$
$! Parse elements
$  __gih_dim_x = f$element(0, " ", __gih_dim_x)
$  __gih_dim_y = f$element(0, " ", __gih_dim_y)
$  __gih_dim_z = f$element(0, " ", __gih_dim_z)
$  __gih_vx_size = f$element(0, " ", __gih_vx_size) ! voxel size in um
$   icalc '__gih_vx_size' / 1000                    
$   __gih_voxel_size = icalc_out                    ! voxel size in mm
$
$!
$!  Assign values to output variable __gih_var_name
$   '__gih_var_name'dim_x      == __gih_dim_x
$   '__gih_var_name'dim_y      == __gih_dim_y
$   '__gih_var_name'dim_z      == __gih_dim_z
$   '__gih_var_name'vec_dim    == "''__gih_dim_x',''__gih_dim_y',''__gih_dim_z'" ! Legacy
$   '__gih_var_name'dim        == "''__gih_dim_x',''__gih_dim_y',''__gih_dim_z'"
$   '__gih_var_name'voxel_size == __gih_voxel_size
$   '__gih_var_name'vx_size    == __gih_vx_size
$!
$   sh sym '__gih_var_name'*
$
$ subroutines:
$!==========================================================            
$! Subroutine trim_text adapted from Tomi Koller 
$ TRIM_TEXT: SUBROUTINE
$   __TT_SPEC = "_"
$   __TT_TEMP = f$edit(P1, "trim,compress")
$   !sh sym __TT_TEMP
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
$ PIPE_CTHEADER: SUBROUTINE
$   __pch_isq  = p1
$   __pch_text = p2
$   __pch_sym  = p3
$   pipe ctheader '__pch_isq' | search sys$pipe "''__pch_text'" | (read sys$input line ; define/job/nolog line_log &line)
$   '__pch_sym' == f$edit(f$trnlnm("line_log") - "''__pch_text'", "trim,compress")
$ ENDSUBROUTINE
$!==========================================================            
$ goto complete
$  
$ file_not_found:
$ say "  "
$ say "!! "
$ say "!! ERROR:  ISQ file not found"
$ say "!! "
$ 
$ complete:
$ say "  "
$! #
$ say "!! GET_ISQ_HEADER.COM: completed"
$ say "=========================================================="
$ exit
$
$ terminate:
$    @ez:helper GET_ISQ_HEADER.com
$   exit