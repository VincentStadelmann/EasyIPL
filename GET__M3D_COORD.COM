$!************************* EZ_IPL *****************************************           
$!
$! GET__M3D_COORD.COM
$!
$!  Written by: Vincent Stadelmann 2011.09.20 
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$! 
$! USAGE:
$!  @'scripts_dir'get__m3d_coord.com	'aim_filename' 'coord_symbol' 'gobj_filename' 
$!
$! DESCRIPTION:
$!  Calculates coordinates to align ROI of input aim in Z
$!  P1  : AIM file
$!  P2* : Coordinates symbol (*none)
$!  P3* : GOBJ of interest (*none)
$!
$! 
$!***************************************************************************                     
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! CREATE__TMAT_M3D.COM:	 "
$ say "=========================================================="
$!*
$
$ if (p1 .eqs. "") then goto terminate
$!
$ show symbol p1 
$ show symbol p2 
$ show symbol p3 
$
$! Setup variable name
$ if (f$edit(p2, "upcase") .eqs. "NONE") then p3 = ""
$ if (p3 .eqs. "")
$   then 
$     variable_name = ""
$   else
$     variable_name := 'p3'__
$ endif
$ show symbol variable_name
$!
$! Setup skips 
$  if ("''get__m3d_skip'" .eqs. "") then get__m3d_skip == 0
$  if (get__m3d_skip .nes. "") then skip := "/skip=''get__m3d_skip'"
$  if (get__m3d_skip .eq. 0) then skip := ""
$  get__m3d_skip == get__m3d_skip + 1
$  sh sym skip
$  sh sym get__m3d_skip
$
$! Optional GOBJ 
$  if (p3 .nes. "") then apply_gobj_str = "/gobj_maskaimpeel_ow in ''p3' 0 "
$  if (p3 .eqs. "") then apply_gobj_str = "!! "
$ 
$ say "!! Compute Moment3D: "
$ IPL_BATCH

/read
  -name                     in
  -filename                 "P1
  
"apply_gobj_str

/moment3d_of_inertia
  -input                     in
  -fileout_or_screentab      screen

..
$
$ say "!! Parse log for coordinates: "
$ PIPE SEARCH'skip' 'log_filename' "!>   -origin_point " | (READ SYS$PIPE LINE ; DEFINE/JOB/NOLOG LINE_LOG &LINE)
$ LINE_SYM = F$TRNLNM("LINE_LOG")
$ align_input1 = LINE_SYM - "!>   -origin_point "
$ align_input1 = F$EDIT(align_input1,"TRIM,COMPRESS") 
$!
$ PIPE SEARCH'skip' 'log_filename' "!>   -z-axis_point " | (READ SYS$PIPE LINE ; DEFINE/JOB/NOLOG LINE_LOG &LINE)
$ LINE_SYM = F$TRNLNM("LINE_LOG")
$ align_input2 = LINE_SYM - "!>   -z-axis_point "
$ align_input2 = F$EDIT(align_input2,"TRIM,COMPRESS")   
$!
$ PIPE SEARCH'skip' 'log_filename' "!>   -xz-plane_point " | (READ SYS$PIPE LINE ; DEFINE/JOB/NOLOG LINE_LOG &LINE)
$ LINE_SYM = F$TRNLNM("LINE_LOG")
$ align_input3 = LINE_SYM - "!>   -xz-plane_point "
$ align_input3 = F$EDIT(align_input3,"TRIM,COMPRESS")   
$! 
$ @ez:vector__make.com  'variable_name'origin_point   'align_input1'  
$ @ez:vector__make.com  'variable_name'z_axis_point   'align_input2'  
$ @ez:vector__make.com  'variable_name'xz_plane_point 'align_input3'  
$ sh sym 'variable_name'*point
$
$!#
$ say " "
$ say "!! GET__M3D_COORD.COM: completed"
$ say "=========================================================="
$ exit
$!
$ terminate:
$   say "!! P1:  AIM input"
$   say "!! P2*: Output symbol for coordinates"
$   say "!! P3*: GOBJ"
$   exit