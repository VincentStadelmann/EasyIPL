$!************************* EZ_IPL *****************************************           
$!
$! AIM_TO_ISQ.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2012.02.07
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Transform AIM file to ISQ file
$! 
$! USAGE:
$!   @ez:aim_to_isq.com	'input_filename' 'isq_filename' 'org_pos' 'square'
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2* : Output ISQ file (*filename+.ISQ)
$!  P3* : Keep original position? (true/*false)
$!  P4* : Make square image ? (true/*false)
$!
$! EXAMPLE:
$!   Transform image.aim into a square ISQ at (0,0) position
$!   @ez:aim_to_isq.com image.aim image.isq false true
$!
$! VERSION HISTORY:
$!  2016.11.03 Checking inputs
$!  2018.10.18 EZ format
$!
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! AIM_TO_ISQ.COM: 	"
$ say "=========================================================="
$!*
$!
$! Testing inputs
$  	if (p1 .eqs. "") then goto terminate
$  	if (p2 .eqs. "") then p2  = p1 - ".AIM" + ".ISQ"
$  	if (p3 .nes. "TRUE") then p3 := false
$  	if (p4 .nes. "TRUE") then p4 := false
$
$   sh sym p1
$   sh sym p2
$   sh sym p3
$   sh sym p4
$!
$ ipl_batch

/read
  -name                      tmp
  -filename                  "p1

/toisq_from_aim
  -aim_name                  tmp
  -isq_filename              "p2
  -square_flag               "p4
  -original_position         "p3
  
..
$!#
$
$ say "!! AIM_TO_ISQ.COM: Completed	"
$ say "=========================================================="
$ exit
$!
$ terminate:
$  @ez:helper AIM_TO_ISQ.com
$ exit