$!*************************************** Easy_IPL *****************************************           
$!
$! AIM_TO_GOBJ.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Converts a binary AIM into a GOBJ mask
$!  The level of details is controlled by min/max_elements 
$!  and the smoothness of the contour by curv_smooth.
$!  Note: this is a very useful function to visualize a mask AIM over a grayscale AIM. 
$! 
$! USAGE:
$!  @ez:aim_to_gobj.com	'aim_file' 'gobj_file' 'min_elements' 'max_elements' 'curv_smooth'
$!
$! PARAMETERS:
$!  P1  : Input binary AIM file 
$!  P2* : Output GOBJ mask file  (_ATG*.GOBJ)
$!  P3* : Minimum element vol    (*0)
$!  P4* : Maximum element vol    (*0)
$!  P5* : Curvature smooth       (*1=max smooth ... 5=max details)
$! 
$! VERSION HISTORY:
$!  2012.10.26 Created
$!  2017.10.12 Formating
$!  2018.10.20 EZ Format
$!
$!****************************************************************************************            
$
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! AIM_TO_GOBJ.COM:  "
$ say "=========================================================="
$!*
$
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then p2 = p1 -".AIM" + "_ATG.GOBJ"
$  if (p3 .eqs. "") then p3 = 0
$  if (p4 .eqs. "") then p4 = 0
$  if (p5 .eqs. "") then p5 = 1
$
$  show symbol p1
$  show symbol p2
$  show symbol p3
$  show symbol p4
$  show symbol p5
$
$ ipl_batch

/read
  -name                      tmp
  -filename                  "p1
  
/togobj_from_aim
  -input                     tmp
  -gobj_filename             "p2
  -min_elements              "p3
  -max_elements              "p4
  -curvature_smooth          "p5 

..
$!#
$ say "!! AIM_TO_GOBJ.COM: Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper AIM_TO_GOBJ.com
$ exit
