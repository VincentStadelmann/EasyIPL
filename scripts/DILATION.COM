$!************************* EZ_IPL *****************************************           
$!
$! DILATION.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2011.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Dilate object by n voxels and optionally adds n+1 offset
$! 
$! USAGE:
$!  @ez:dilation.com	'input_file' 'out_file'  'dilation_dist' 'add_offset?'
$!
$! PARAMETERS:
$!  P1  : Input binary AIM file
$!  P2* : Output binary AIM file (*_DIL.AIM)
$!  P3* : Dilation distance      (*0)
$!  P4* : Add offset?            (*true/false)
$! 
$! EXAMPLE:
$!  Dilate seg.aim by 10 voxels with no offset 
$!  @ez:dilation seg.aim seg.aim 10 false
$!
$! VERSION HISTORY:
$!  2011.08.03 Created
$!  2017.07.20 Offset as an option (add offset by default )
$!  2018.10.20 EZ Format
$!
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say "  "
$ say "=========================================================="
$ say "!! DILATION.COM:  "
$ say "=========================================================="
$!*
$!
$    if (p1 .eqs. "") then goto terminate
$    if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_DIL.AIM"
$    if (p3 .eqs. "") then p3 = 0
$    if (p4 .nes. "FALSE") then p4 := TRUE
$
$   show symbol p1
$   show symbol p2
$   show symbol p3
$   show symbol p4
$!
$ 	offset_add = p3 + 1
$   if (p4 .eqs. "FALSE") then offset_add = 0
$   show symbol offset_add
$!
$ IPL_BATCH

/read
  -name                      tmp
  -filename                  "P1

/dilation
  -input                     tmp
  -output                    dil
  -dilate_distance           "P3
  -continuous_at_boundary    0 0 0
  -use_previous_margin       false

/offset_add
  -input                     dil
  -add_offset                "offset_add "offset_add "offset_add 

/write_v020
  -name                      dil
  -filename                  "P2
  -compress_type             bin
  -version_020               true
  
..
$!#
$ say "!! DILATION.COM: Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper DILATION.com
$ exit
