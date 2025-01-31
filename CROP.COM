$!************************* EZ_IPL *****************************************           
$!
$! CROP.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Crops an image to specified dimensions 
$!  (in local or global coordinates)
$! 
$! USAGE:
$!  @ez:crop	'in_file' 'out_file' 'position' 'dimensions' 'global_or_local?'
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2  : Output AIM file                (*_CROP.AIM)
$!  P3* : Position vector for cropping   (*0,0,0)
$!  P4* : Dimensions vector for cropping (*-1,-1,-1)
$!  P5* : Global coordinates?            (*true/false or *global/local)
$!        (if false then local coordinates)
$!
$! EXAMPLE:
$!  Crop image.aim to dimensions of (100,100,100)
$!  (since we don't know the position of image.aim, we use local coordinates)
$!  @ez:crop   image.aim image.aim 0,0,0 100,100,100 local
$!
$! VERSION HISTORY:
$!  2016.01.05 coordinates in vector format
$!  2018.03.07 minor fixes
$!  2018.10.19 EZ format, vector forms
$!
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! CROP.COM:  	"
$ say "=========================================================="
$!*
$    ! Check inputs
$    if (p1 .eqs. "") then goto terminate
$    if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_CROP.AIM"
$    if (p3 .eqs. "0") then p3 := 0,0,0
$    if (p3 .eqs. "") then p3 := 0,0,0
$    if (p4 .eqs. "-1") then p4 := -1,-1,-1
$    if (p4 .eqs. "") then p4 := -1,-1,-1
$    if (p5 .eqs. "LOCAL") then p5 := FALSE
$    if (p5 .nes. "FALSE") then p5 := TRUE
$
$    show symbol p1
$    show symbol p2
$    show symbol p3
$    show symbol p4
$    show symbol p5
$
$    ! Verify that p3 and p4 have coordinates
$    if (f$locate(",", p3) .eq. f$length(p3)) then goto terminate
$    if (f$locate(",", p4) .eq. f$length(p4)) then goto terminate
$
$    ! Parse coordinates
$     @ez:vector__parse 'p3' crop_pos
$     @ez:vector__parse 'p4' crop_dim
$
$
$ IPL_BATCH

/read
  -name                      in
  -filename                  "p1

/sub_get
  -input                     in
  -output                    sub
  -pos                       "crop_pos__ipl
  -dim                       "crop_dim__ipl
  -global_pos_flag           "p5

/write_v020
  -name                      sub
  -filename                  "p2
  -compress_type             bin
  -version_020               true

..
$ say "!! CROP.COM: Completed	"
$ say "=========================================================="
$ exit
$ terminate:
$  @ez:helper crop.com
$ exit