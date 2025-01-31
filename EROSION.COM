$!************************* EZ_IPL *****************************************           
$!
$! EROSION.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2011.08.03
$!  Copyright (c) 2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author.
$!
$! DESCRIPTION:
$!  Erosion by n pixels,
$!  Optional: use previous margin if a dilation was used before
$! 
$! USAGE:
$!   @ue:erosion.com	'input_file' 'out_file' 'erosion_dist' 'use_previous_margin?'
$!
$! PARAMETERS:
$!  P1  : Input binary AIM file
$!  P2* : Output binary AIM file (*_ER.AIM)
$!  P3* : Erosion distance       (*0)
$!  P4* : Use previous margins?  (true/*false)
$! 
$! EXAMPLE:
$!  Erode seg.aim by 10 voxels  
$!  @ez:erosion seg.aim seg.aim 10 
$! 
$! VERSION HISTORY:
$!  2012.02.09 Bug fix
$!  2014.12.12 Add usage
$!  2014.12.18 Typo in offset
$!  2018.01.12 Formatting
$!  2018.09.13 Bug fix
$!  2018.10.20 EZ Format
$!
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say "  "
$ say "=========================================================="
$ say "!! EROSION.COM:  "
$ say "=========================================================="
$!*
$
$!
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_ER.AIM"
$  if (p3 .eqs. "") then p3 = 0
$  if (p4 .nes. "TRUE") then p4 = "FALSE"
$!
$  offset_add =	p3 + 1
$  show symbol offset_add
$!
$ IPL_BATCH

/read
  -name                      tmp
  -filename                  "P1

/erosion
  -input                     tmp
  -output                    out
  -erode_distance            "P3
  -use_previous_margin       "P4
  -metric                    101  

/offset_add
  -input                     out
  -add_offset                "offset_add "offset_add "offset_add 

/write_v020
  -name                      out
  -filename                  "P2
  -compress_type             bin
  -version_020               true
  
..
$!#
$ say "!! EROSION.COM: Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper erosion.com
$ exit
