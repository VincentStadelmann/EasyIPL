$!****************************************************************************************            
$! TOGOBJ.COM
$! 
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! VERSION HISTORY:
$!  2012.10.26 Created
$!  2017.10.12 Formating
$! 
$! DESCRIPTION:
$!  Makes a GOBJ from a mask AIM
$! 
$! USAGE:
$!  @ue:togobj.com	'ipl_input' 'gobj_output' 'min_elements' 'max_elements' 'curv_smooth'
$!
$! PARAMETERS:
$!  P1 : input aim file
$!  P2 : output gobj file
$!  P3 : min element
$!  P4 : max element
$!  P5 : curvature smooth
$!
$!****************************************************************************************            
$
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! TOGOBJ.COM:  "
$ say "=========================================================="
$!*
$
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then goto terminate
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
$ say "!! TOGOBJ.COM: Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$   say "!! P1 : input file"
$   say "!! P2 : output gobj"
$   say "!! P3* : min elements (0*)"
$   say "!! P4* : max elements (0*)"
$   say "!! P5* : curvature smooth (1*)"
$ exit
