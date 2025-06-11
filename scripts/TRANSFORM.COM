$!************************* EZ_IPL *****************************************           
$!
$! TRANSFORM.COM 
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2012.09.03
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Apply a transformation data file from a .dat file to an image
$! 
$! USAGE:
$!   @ez:transform.com  'in_file' 'tmat' 'out_file' 'interpolate' 'inverse'
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2  : Transformation data file   
$!  P3  : Output AIM file   
$!  P4* : Interpolate ?                      (*true/false)
$!  P5* : Inverse transformation ?           (true/*false)
$!
$! EXAMPLE:
$!   Apply tmat.dat to image.aim without interpolation
$!   @ez:transform.com	image.aim tmat.dat image.aim  false  
$!
$! VERSION HISTORY:
$!  2016.06.28 IPLREG_BATCH -> IPL_BATCH
$!  2016.12.02 Processing inputs
$!  2018.11.20 EZ format
$!  2019.03.11 EZ legacy issues, __t_interpol_opt bug
$!  2022.10.30 Transform GOBJs
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! TRANSFORM.COM:  "
$ say "=========================================================="
$!*
$   if (p1 .eqs. "") then goto terminate
$   if (p2 .eqs. "") then goto terminate
$   if (p3 .eqs. "") then goto terminate
$
$   ! Processing inputs:
$   if (p4 .eqs. "1") then p4 = "TRUE" ! legacy compatibility
$   if (p5 .eqs. "1") then p5 = "TRUE" ! legacy compatibility
$   if (p4 .nes. "FALSE") then p4 = "TRUE"
$   if (p5 .nes. "TRUE") then p5 = "FALSE"
$
$   show symbol p1
$   show symbol p2
$   show symbol p3
$   show symbol p4
$   show symbol p5
$
$   ! Interpolate is 0, 1 or 2, here we use only 0 and 1. 
$   if (p4 .eqs. "TRUE") then __t_interpol_opt := 1
$   if (p4 .nes. "TRUE") then __t_interpol_opt := 0
$
$   __transform_in_aim   = p1
$   __transform_out_aim  = p3
$
$! If input/output are GOBJs
$! first transform GOBJ into tmp AIM
$  if (f$locate(".GOBJ", p1) .lt. f$length(p1)) 
$   then 
$     say "!! Transform input GOBJ to mask AIM"
$     __transform_in_aim = p1 - ".GOBJ" + "__T__TMP.AIM"
$     @ez:gobj_to_aim   'p1' '__transform_in_aim'
$  endif
$
$! If output is GOBJ, create tmp name for AIM output
$  if (f$locate(".GOBJ", p3) .lt. f$length(p3)) 
$   then 
$     __transform_out_aim = p3 - ".GOBJ" + "__T__TMP.AIM"
$     __t_interpol_opt := 0 ! (aim_to_gobj only ok with binary masks)
$  endif
$
$
$ IPL_BATCH

/read
  -name                      org
  -filename                  "__transform_in_aim
  
/transform
  -in                        org
  -out                       reg
  -Tmat_file_name            "p2
  -img_interpol_option       "__t_interpol_opt
  -el_size_mm_out            -1.000 -1.000 -1.000
  -Tmat_invert               "p5

/write
  -name                    	reg
  -filename                	"__transform_out_aim
  -compress_type           	bin
  -version_020             	true

..
$
$
$! If output was GOBJ, transform output aim into gobj and delete tmp output aim
$  if (f$locate(".GOBJ", p3) .lt. f$length(p3)) 
$   then 
$     say "!! Transform registered mask AIM into GOBJ"
$     say "!! Will only work if mask is binary"
$     @ez:aim_to_gobj   '__transform_out_aim' 'p3' 0 0 5
$     delete '__transform_out_aim';*
$  endif
$
$! If input was gobj delete tmp input aim
$  if (f$locate(".GOBJ", p1) .lt. f$length(p1)) then delete '__transform_in_aim';*
$
$!#
$ say "!! TRANSFORM.COM: Completed	"
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper transform.com
$ exit
