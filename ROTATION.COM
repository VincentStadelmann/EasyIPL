$!************************* EZ_IPL *****************************************           
$!
$! ROTATION.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2015.06.30
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Rotation of angle alpha around axis defined by angles to xyz axes.
$!  Note that after the transformation, the image may extend to negative values on
$!  some axes and therefore it cannot be opened in UCT_EVALUATION. 
$!  To view it in UCT_EVALUATION use @ez:crop or @ez:set_header
$! 
$! USAGE:
$!   @ez:rotation.com	'in_file' 'out_file' 'rot_angle' 'axis_angles'  'interpolate'
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2  : Output AIM file   
$!  P3* : Rotation angle                     (*0)
$!  P4* : Rotation axis angles to x,y,z      (*90,90,0)
$!  P5* : Interpolate ?                      (*true/false)
$!
$! EXAMPLE:
$!   Turn image 45° around axis OY
$!   @ez:rotation.com	image.aim image__45.aim  45  90,0,90  
$!
$! VERSION HISTORY:
$!  2018.03.15 vec format + input testing
$!  2018.11.20 EZ format, new params order
$!  2023.01.05 Fixed p5 = FALSE -> 0
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! ROTATION.COM:  "
$ say "=========================================================="
$!*
$    if (p1 .eqs. "") then goto terminate
$    if (p2 .eqs. "") then goto terminate
$    if (p3 .eqs. "") then p3 := 0
$    if (p4 .eqs. "") then p4 := 90,90,0
$    if (p5 .nes. "FALSE") then p5 = 1
$    if (p5 .eqs. "FALSE") then p5 = 0
$
$! Show inputs
$   i = 1
$   loop_i:
$     show sym p'i'
$     i = i+1
$     if (i .lt. 5) then goto loop_i
$
$   @ez:vector__parse 'p4' __turnaxis_angles
$   if (__turnaxis_angles__h .nes. "V") then goto terminate 
$
$ ipl_batch

/read
  -name                      tmp
  -filename                  "p1

/turn3d
  -input                     tmp
  -output                    out
  -turnaxis_angles           "__turnaxis_angles__ipl
  -turnangle                 "p3
  -img_interpol_option       "p5

  
/write
  -name                      out
  -filename                  "p2
  -compress_type             bin
  -version_020               true
  
..
$ say "!! ROTATION.com completed "
$ say "=========================================================="
$ exit
$
$ TERMINATE:
$  @ez:helper rotation.com
$ exit