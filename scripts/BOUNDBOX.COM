$!************************* EZ_IPL *****************************************           
$!
$! BOUNDBOX.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Crops an image to non-zero regions, with an optional border
$! 
$! USAGE:
$!  @ez:boundbox.com	'in_file' 'out_file' 'vec_border'
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2  : Output AIM file
$!  P3* : Border vector b or bx,by,bz (*0,0,0)
$!
$! EXAMPLE:
$!  Crop seg.aim and leave 5 voxels margin in all directions 
$!  @ez:boundbox   seg.aim seg.aim 5
$!
$! VERSION HISTORY:
$!  2016.12.16 p3 can have "." to give variable borders
$!  2018.08.06 p3 can have "," to give variable borders
$!  2018.10.19 EZ format, vector forms
$!
$!***************************************************************************            
$
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! BOUNDBOX.COM 	 "
$ say "=========================================================="
$!*
$
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then goto terminate
$ if (p3 .eqs. "") then p3 = 0
$
$ show symbol p1 
$ show symbol p2 
$ show symbol p3 
$!
$ if (f$locate(",", "''p3'") .lt. f$length("''p3'"))
$ 	then 
$		! Parse border vector
$       @ez:vector__parse 'p3' border
$ 	else	
$		border__ipl = p3
$  endif
$
$ IPL_BATCH

/read
  	-name				tmp
  	-filename			"p1


/bounding_box_cut
	-input				tmp
    -output 			out
    -z_only				false
    -border 			"border__ipl

/write_v020
  	-name				out
  	-filename			"p2
  	-compress_type		bin
  	-version_020		true
  
..
$!#
$ say "!! BOUNDBOX.COM:	Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper BOUNDBOX.com
$ exit
