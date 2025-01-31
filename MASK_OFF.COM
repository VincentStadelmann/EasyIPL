$!************************* EZ_IPL *****************************************           
$!
$! MASK_OFF.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2016.03.04
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Masks off an image with a mask. 
$! 
$! USAGE:
$!  @ez:mask_off.com 'aim_file' 'mask_file' 'out_file' 'eval_logfile2'
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2  : Input mask file  
$!  P3  : Output file  
$!  P4* : Log file             (*eval_logfile2)
$!
$! EXAMPLE:
$!  Mask screw.aim from seg.aim into bone.aim
$!  @ez:mask_off seg.aim screw.aim bone.aim
$!
$! VERSION HISTORY:
$!  2016.03.04 V. Stadelmann
$!  2017.05.19 input can be grayscale
$!  2017.11.13 Use get__geo and create_canvas to speed up
$!  2018.12.06 EZ format, vector forms
$!  2018.12.06 Re-order p3 & p4
$!  2022.06.21 No loss of details: -curvature_smooth 5
$!  2025.01.31 Include gobj masks. Delete tmp file.  
$!
$!***************************************************************************            
$
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! MASK_OFF.COM:  "
$ say "=========================================================="
$!*
$!
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then goto terminate
$ if (p3 .eqs. "") then goto terminate
$ if (p4 .eqs. "") then p4 = eval_logfile2
$
$ sh sym p1
$ sh sym p2
$ sh sym p3
$ sh sym p4
$
$! If MASK is GOBJ convert to AIM
$  if (f$locate(".GOBJ", f$edit(p2, "upcase")) .lt. f$length(p2))
$  then
$    say "!! Mask is a GOBJ -> convert to AIM"
$    __mff_gobj_converted_mask = p2 - ".GOBJ" + "__MFF_CONV.AIM"
$    sh sym mask_name
$
$    IPL_BATCH

     /gobj_to_aim
      -gobj_filename             "p2
      -output                    mask
      -peel_iter                 0
  
     /write_v020
      -name                      mask
      -filename                  "__mff_gobj_converted_mask
      -compress_type             bin
      -version_020               true
  
    ..
$    p2 = __mff_gobj_converted_mask
$    sh sym p2
$ endif
$
$ __mff_tmp_mask = P1 - ".AIM" + "__MFF_TMP_MASK.GOBJ"
$ sh sym __mff_tmp_mask
$
$ @ez:get_geometry.com  'p1' __mff 'p4' 
$!
$
$ ipl_batch

/read
  -name                      in
  -filename                  "p1
  
/create_canvas
  -output                    bg
  -dim                       "__mff__dim__ipl
  -off                       "__mff__off__ipl
  -pos                       "__mff__pos__ipl
  -el_size_mm                "__mff__els__ipl
  -type                      char
  
/set_value
  -input                     bg
  -value_object              127
  -value_background          127 
  
/read
  -name                      seg
  -filename                  "p2
 
/set_value
  -input                     seg
  -value_object              -127
  -value_background          0
    
/add_aims
  	-input1                  seg
  	-input2                  bg
  	-output                  mask 

!! transform mask to gobj -> output will stay same size as input
!! even is maskoff aim is larger... 
	
/togobj_from_aim
  -input                     mask
  -gobj_filename             "__mff_tmp_mask
  -min_elements              0
  -max_elements              0
  -curvature_smooth          5

/gobj_maskaimpeel_ow
  -input_output              in
  -gobj_filename             "__mff_tmp_mask
  -peel_iter                 0
   
/write
  -name                      in
  -filename                  "p3
  -compress_type             bin
  -version_020               true    

..
$
$ ! cleanup
$ del/log '__mff_tmp_mask';*
$ if ('__mff_gobj_converted_mask' .nes. "") then del/log '__mff_gobj_converted_mask';*
$
$!#
$ say "!! MASK_OFF.COM: completed	 "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper MASK_OFF.com
$ exit