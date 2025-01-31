$!************************* EZ_IPL *****************************************           
$!
$! MAKE_TMAT.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2017.08.24
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Creates a transformation matrix from translation/rotation vectors
$! 
$! USAGE:
$!   @ez:create__tmat.com  'dat_filename' 'vec_T1' 'vec_R1' 'vec_T2*' 'units'
$!
$! PARAMETERS:
$!   P1: Filename 
$!   P2*: Dimensions r,h,elsize  (*1,2,1)                      
$!   P3*: Reference type         (*center/base/corner)
$!   P4*: Reference coordinates  (*r,r,h/2)
$!   P5*: Units (mm/vx)          (*mm)
$!   P6*: Value                  (*127) 
$!
$! EXAMPLE:
$!   Create a cylinder of radius=2mm height=10mm 
$!   with its base centered at 5mm,5mm,0mm
$!   and with a voxel size of 0.1mm 
$!   @ez:make_cylinder.com	cylinder.aim 2,10,0.1 base 5,5,0
$!
$! VERSION HISTORY:
$!  2018.04.24 vec format + input testing
$!  2018.11.20 EZ format, new params order
$!  2018.11.20 New name
$! 
$!***************************************************************************            
$!
$
$ say = "write sys$output"
$ say "  "
$ say "=========================================================="
$ say "!! CREATE__TMAT.COM:  "
$ say "=========================================================="
$!
$  if ("''coms'" .eqs. "") then coms = "ue:"
$  if (f$search("ez:vector__parse.com") .eqs. "") then goto terminate0
$  if (f$search("ez:vector__make.com") .eqs. "") then goto terminate0
$!
$! Test inputs
$   j = 0
$   pj_loop1:
$    j = j + 1
$    show symbol p'j'
$    if (p'j' .eqs. "") then goto terminate1
$    if (j .lt. 3) then goto pj_loop1
$   pj_loop2:
$    j = j + 1
$    show symbol p'j'
$    if (j .lt. 7) then goto pj_loop2
$!
$! Parse vector inputs
$   @ez:vector__parse.com  'p2' vec_t1
$   @ez:vector__parse.com  'p3' vec_r1
$
$   if (p4 .nes. "") 
$     then 
$       @ez:vector__parse.com  'p4' vec_t2
$     else
$       ! if no T2 given, T2 = -T1
$       @ez:vector__multiply.com  'vec_t1' -1 vec_t2
$   endif
$
$   if (p5 .eqs. "") then p5 := RAD
$   if (p5 .nes. "DEG" .and. p5 .nes. "RAD") then goto terminate3
$   if (p5 .eqs. "RAD") then angle_suffix = "R"
$   if (p5 .eqs. "DEG") then angle_suffix = ""
$!
$! Write transformation matrix:
$  Say "!! Writing transformation matrix "
$   tab == f$fao("!_")
$   open/write output_file 'p1'
$   write output_file "SCANCO TRANSFORMATION DATA VERSION: 10"
$   T1_str = "TRANSLATE:''tab'''vec_t1__ipl'" 
$   write/symbol output_file T1_str    
$   RX_str = "ROT_X''angle_suffix':''tab'''vec_r1_1'"
$   RY_str = "ROT_Y''angle_suffix':''tab'''vec_r1_2'"
$   RZ_str = "ROT_Z''angle_suffix':''tab'''vec_r1_3'"
$   write/symbol output_file RX_str   
$   write/symbol output_file RY_str   
$   write/symbol output_file RZ_str   
$   T2_str = "TRANSLATE:''tab'''vec_t2__ipl'" 
$   write/symbol output_file T2_str 
$   close output_file
$   Say " "
$   type 'p1'
$   Say " "
$!
$ say "!! CREATE__TMAT.COM:	Completed "
$ say "==========================================================" 
$ exit 
$!
$ terminate0:
$   say "  "
$   say "!! Error: requires vector__parse.com and vector__make.com in ''coms' "
$   exit
$ terminate1:
$   say "!! P1 : transform.dat filename "
$   say "!! P2 : translation 1 "
$   say "!! P3 : rotation  "
$   say "!! P4 : translation 2*             (default -P2)"
$   say "!! P5 : angles units* (deg/rad)    (default rad)"
$   exit
$ terminate3:
$	say "!! Units must be ""RAD"" or ""DEG"" "
$   exit
