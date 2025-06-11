$!************************* EZ_IPL *****************************************           
$!
$! BOUNDBOX_Z_FILL_OFFSET.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2016.06.07
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$! 
$! DESCRIPTION:
$!  Crops image in Z, add a border and fills the border 
$!  with copies of limit slices
$!
$! USAGE:
$!  @ez:boundbox_z_fill_offset.com	'in_file' 'out_file' 'border_z'
$!
$! PARAMETERS:
$!  P1 : Input AIM file
$!  P2 : Output AIM file
$!  P3 : Z border (*0)
$! 
$! VERSION HISTORY:
$!  2016.06.06 Modified from BOUNDBOX.COM
$!  2018.10.19 EZ Format
$!
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! BOUNDBOX_Z_FILL_OFFSET.COM:	
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
$ IPL_BATCH

/read
  -name                      in
  -filename                  "p1

/bounding_box_cut
  -input                     in
  -output                    bn
  -z_only                    true
  -border                    0 0 "p3  

!! concat with original volume
/concat
  -input1                    in
  -input2                    bn
  -output                    out
  -common_region_only        false
  -add_not_overlay           true
  -make_edge                 false
  -shift_ofin2               0 0 0
  -turnangle                 0.000000
  -turnpoint_global          -1 -1

!! Add offset and fill
/offset_add
  -input                     out
  -add_offset                0 0 "p3

/fill_offset_duplicate
  -input                     out  
  
/write_v020
  -name                      out
  -filename                  "p2
  -compress_type             bin
  -version_020               true

..
$!#
$ say "!! BOUNDBOX_FILLZOFFSET.COM:	Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper BOUNDBOX_Z_FILL_OFFSET.com
$ exit