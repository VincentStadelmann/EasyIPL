$!*************************************************            
$! BOUNDBOX_FILLZOFFSET.COM
$!
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$! 
$! VERSION HISTORY:
$!  2012.06.06 V. Stadelmann
$! 
$! DESCRIPTION:
$!  Cuts out empty regions
$!
$! USAGE:
$!  @ue:boundbox_fillzoffset.com	'in_filename' 'out_filename' 'ipl_border_z'
$!
$! PARAMETERS:
$!  P1 : input aim file
$!  P2 : output aim file
$!  P3 : border
$!
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! BOUNDBOX_FILLZOFFSET.COM:	
$ say "!! Cuts out empty regions, adds offset, "
$ say "!! fills offset with border slices duplicates    "
$ say "=========================================================="
$!*
$!
$ show symbol p1 
$ show symbol p2 
$ show symbol p3 
$!
$ IPL_BATCH

/read
  -name                      in
  -filename                  "p1

!! Cuts out empty regions
/bounding_box_cut
  -input                     in
  -output                    bn
  -z_only                    true
  -border                    0 0 "p3  

!! add back full z volume
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

!! border in z put into offset then, will be mirrored later
/offset_add
  -input                     out
  -add_offset                0 0 "p3

!! mirror out slices that will be lost with gauss
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
