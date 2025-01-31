$!************************* EZ_IPL *****************************************           
$!
$! APPLY_GOBJ.COM
$!
$!  Written by: Vincent Stadelmann 2011.08.03
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$! 
$! DESCRIPTION:
$!  Applies a GOBJ mask to an AIM file
$!
$! USAGE:
$!  @ez:apply_gobj.com	'in_file' 'gobj_file' 'out_file' 'peel_dist' 'apply_box' 
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2  : GOBJ mask file
$!  P3* : Output AIM file (*if none, P3 = P1)
$!  P4* : Peel distance (0*)
$!  P5* : Crop image after masking? (true*/border_size/false)
$!
$! EXAMPLE:
$!  Apply the mask gobj_file to aim_file without peeling and 
$!  with a bounding box border of 0
$!  @ez:apply_gobj	'aim_file' 'gobj_file' 'aim_file' 0 true
$!
$! VERSION HISTORY:
$!  2012.02.07 Minor bugs fix
$!  2018.04.18 Check inputs
$!  2018.10.18 EZ Format, !! 
$!
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! APPLY_GOBJ.COM:	"
$ say "=========================================================="
$!*
$ 
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then goto terminate
$  if (p3 .eqs. "") then p3 = p1 
$  if (p4 .eqs. "") then p4 = 0
$  if (p5 .eqs. "0") then p5 = "FALSE"  ! legacy
$  if (p5 .nes. "FALSE") then p5 = "TRUE" 
$ 
$  show symbol p1 
$  show symbol p2 
$  show symbol p3 
$  show symbol p4
$  show symbol p5
$
$  if (p5 .eqs. "FALSE") then goto apply_gobj_nobox 
$
$!
$ IPL_BATCH

/read
  -name                      tmp
  -filename                  "p1

/gobj_maskaimpeel_ow
  -input_output              tmp
  -gobj_filename             "p2
  -peel_iter                 "p4
  
/bounding_box_cut
  -input                     tmp
  -output                    out
  -z_only                    false
  -border                    "p5

/write_v020
  -name                      out
  -filename                  "p3
  -compress_type             bin
  -version_020               true
  
..
$ goto apply_gobj_complete
$
$ apply_gobj_nobox:
$ IPL_BATCH

/read
  -name                      tmp
  -filename                  "p1

/gobj_maskaimpeel_ow
  -input_output              tmp
  -gobj_filename             "p2
  -peel_iter                 "p4

/write_v020
  -name                      tmp
  -filename                  "p3
  -compress_type             bin
  -version_020               true
  
..
$ apply_gobj_complete:
$!#
$ say "!! APPLY_GOBJ.COM:	Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper APPLY_GOBJ.com
$ exit
