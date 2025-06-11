$!************************* EZ_IPL *****************************************           
$!
$! COMPUTE_MOMENT2D.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2015.04.05
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Compute moment of inertia of a segmented object slice by slice into 
$!  a text file. 
$! 
$! USAGE:
$!  @ez:compute_moment2d 'aim_file' 'output_file*' 'gobj_file*' 'peel*' 'rot*'
$!
$! PARAMETERS:
$!  P1  : Input seg AIM
$!  P2* : Output text file (*_MOMENT2D.TXT)
$!  P3* : ROI GOBJ file    (*none)
$!  P4* : Peel distance    (*0)
$!  P5* : Rotation angle   (*0)
$!
$! EXAMPLE:
$!   
$!
$! VERSION HISTORY:
$!  2015.04.05 V Stadelmann
$!  2017.07.03 VS fixed mean2 with seg_gobj_filename mask
$!  2017.07.20 VS voxgobj instead of vox
$!  2019.09.03 VS EZ format
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! COMPUTE_MOMENT2D.COM: "
$ say "=========================================================="
$!*
$
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_MOMENT2D.TXT"
$  if (p3 .eqs. "") then p3 = "none"
$  if (p4 .eqs. "") then p4 = 0
$  if (p5 .eqs. "") then p5 = 0
$  show symbol p1
$  show symbol p2
$  show symbol p3
$  show symbol p4
$  show symbol p5
$
$ 	ipl_batch

/read
  -name                      in
  -filename                  "p1

/moment2d_of_inertia
  -input                     in
  -fileout_or_screentab      "p2
  -turnangle_cw              "p5
  -gobj_filename             "p3
  -peel_iter                 "p4

..
$
$!#
$  say "!! COMPUTE_MOMENT2D.COM: Completed "
$  say "=========================================================="
$  exit
$
$
$  terminate:
$   @ez:helper COMPUTE_MOMENT2D.COM
$  exit