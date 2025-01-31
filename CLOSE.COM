$!************************* EZ_IPL *****************************************           
$!
$! CLOSE.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Close an object by a sequence of dilation, component labeling and erosion
$! 
$! USAGE:
$!  @ez:close	'in_file' 'out_file' 'dilation' 'erode_less' 'crop_to_org_size' 
$!
$! PARAMETERS:
$!  P1  : Input SEG file
$!  P2* : Output SEG file       (*_CLOSE.AIM)
$!  P3* : dilation              (*0)
$!  P4* : delta erosion         (*0vx)
$!  P5* : crop to original size (*true)
$!  P6* : only XY               (*false)
$! 
$! EXAMPLE:
$!  Close seg.aim using a 10vx dilation, but only 7voxels erosion  
$!  @ez:close seg.aim seg.aim 10 3
$! 
$! VERSION HISTORY:
$!  2018.05.11 New option do not crop size
$!  2018.10.19 EZ Format
$!  2018.10.20 No debug, crop & erode_less inverted
$!  2023.11.26 Only XY
$!
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! CLOSE.COM:  "
$ say "=========================================================="
$!*
$!
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_CLOSE.AIM"
$ if (p3 .eqs. "") then p3  = 0
$ if (p4 .eqs. "") then p4  = 0
$ if (p5 .nes. "FALSE") then p5 := TRUE
$ if (p6 .eqs. "T" .or. p6 .eqs. "1") then p6 := TRUE
$ if (p6 .nes. "TRUE") then p6 := FALSE
$
$  show symbol p1
$  show symbol p2
$  show symbol p3
$  show symbol p4
$  show symbol p5
$  show symbol p6
$!
$  tmp_bg_file = p1 - ".AIM" + "_TMP_BG.AIM"
$  show symbol tmp_bg_file
$   
$  icalc 2 * 'p3'
$  __cls_border = icalc_out
$  if (p6 .eqs. "TRUE") then __cls_border := 'icalc_out' 'icalc_out' 0
$  sh sym __cls_border
$
$  icalc 'p3' - ('p4')       ! brackets in case p6 is negative
$  __erd_dist = icalc_out
$  sh sym __erd_dist
$
$  crop_init_size = "/gobj_maskaimpeel_ow er ''tmp_bg_file' 0"
$  if (p5 .nes. "TRUE") then crop_init_size = "!! "
$  show symbol crop_init_size*
$
$ IPL_BATCH

/read
  -name                      in
  -filename                  "p1

!! Create a plain background image 
/copy
  -in                        in
  -out                       bg

/set_value
  -input                     bg
  -value_object              127
  -value_background          127

/write_v020
  -name                      bg
  -filename                  "tmp_bg_file
  -compress_type             bin
  -version_020               true
  
!! add space around object for closing  
/bounding_box_cut
  -input                     in
  -output                    out
  -z_only                    false
  -border                    "__cls_border  

!! dilate object to close off holes
/dilation
  -input                     out
  -output                    di
  -dilate_distance           "p3
  -continuous_at_boundary    0 0 1
  -use_previous_margin       false
  -metric                    101

!! invert image so object is black, background is white
/set_value
  -input                     di
  -value_object              0
  -value_background          127

!! extract region around object 
/cl_ow_rank_extract
  -input_output              di
  -first_rank                1
  -last_rank                 1
  -connect_boundary          false
  -value_in_range            127 

!! invert image back to normal
/set_value
  -input                     di
  -value_object              0
  -value_background          127

!! erode back dilated object volume 
/erosion
  -input                     di
  -output                    er
  -erode_distance            "__erd_dist
  -use_previous_margin       true
  -metric                    101

!! mask to original z range (optional)
"crop_init_size

!! write out
/write_v020
  -name                      er
  -filename                  "p2
  -compress_type             bin
  -version_020               true

!/bounding_box_cut
!  -input                     er
!  -output                    out
!  -z_only                    false
! -border                    0 0 0
!
!! write out
!/write_v020
!  -name                      out
!  -filename                  "p2
!  -compress_type             bin
!  -version_020               true
  
..
$
$ delete/log 'tmp_bg_file';*
$
$!#
$ say "!! CLOSE.COM: Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper CLOSE.com
$ exit