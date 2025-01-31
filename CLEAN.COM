$!************************* EZ_IPL *****************************************           
$!
$! CLEAN.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Clean off debris with a sequence of erosion, labelling, dilation
$!  Similar to ez:open
$! 
$! USAGE:
$!  @ez:clean.com	'in_file' 'out_file' 'erosion_dist' 'min_vol' 
$!
$! PARAMETERS:
$!  P1  : Input SEG file
$!  P2* : Output SEG file              (*_CLEAN.AIM)
$!  P3* : Erosion/dilation dist        (*0)
$!  P4* : Min volume (in voxels or %)  (*0)
$! 
$! EXAMPLE:
$!  Clean image.seg with erosion by 10 voxels and remove speckles below 
$!  2% of total volume, then dilation of 10 voxels
$!  @ez:clean.com	image.seg image.seg 10 2%
$! 
$! VERSION HISTORY:
$!  2017.09.07 New
$!  2018.10.20 EZ Format
$!  2018.12.03 Simply call open function
$!
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say "  "
$ say "=========================================================="
$ say "!! CLEAN.COM:	"
$ say "=========================================================="
$
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_CLEAN.AIM"
$ if (p3 .eqs. "") then p3 = 0
$ if (p4 .eqs. "") then p4 = 0
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$
$! Call open function:
$ @ez:open 'p1' 'p2' 'p3' 'p4'
$
$!#
$ say "!! CLEAN.COM: Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper clean.com
$ exit