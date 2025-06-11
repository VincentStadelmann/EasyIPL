$!************************* EZ_IPL *****************************************           
$!
$! FILL_OFFSET.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2017.12.18
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Fill offset slices with replicates (duplicate or mirror)
$! 
$! USAGE:
$!  @ez:fill_offset	'in_file' 'out_file' 'border' 'method?' 
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2  : Output AIM file    
$!  P3* : Border around image to fill  (*0)   
$!  P4* : Method?                      (*duplicate/mirror)
$!
$! EXAMPLE:
$!  Fills offset of image.aim with mirror of last slices
$!  @ez:fill_offset   image.aim image.aim mirror
$!
$! VERSION HISTORY:
$!  2018.10.19 EZ format, vector forms
$!  2018.10.20 Add border
$!
$!***************************************************************************            
$
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! FILL_OFFSET.COM: "
$ say "=========================================================="
$
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then goto terminate
$ if (p3 .eqs. "") then p3 = 0
$ if (p4 .nes. "MIRROR") then p4 = "DUPLICATE"
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$
$! Choose method for fill_offset
$  __fill_offset_fct = "/fill_offset_duplicate"
$  if (p4 .eqs. "MIRROR") then __fill_offset_fct = "/fill_offset_mirror"
$  show symbol __fill_offset_fct
$
$!
$ IPL_BATCH

/read
  -name                      in
  -filename                  "P1
   
!! add border then convert into offset
/bounding_box_cut
  -input                     in
  -output                    out 
  -z_only                    false
  -border                    "p3 "p3 "p3  

/offset_add
  -input                     out
  -add_offset                "p3 "p3 "p3

!! mirror out boundary slices into offset/border    
"__fill_offset_fct
  -input                     out

/write
  -name                      out
  -filename                  "P2
  -compress_type             bin
  -version_020               true    

..
$ say "!! FILL_OFFSET.COM: Completed "
$ say "=========================================================="
$ exit
$ terminate:
$  @ez:helper FILL_OFFSET.com
$ exit