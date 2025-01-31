$!************************* EZ_IPL *****************************************           
$!
$! CLOSE_SLW.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Close an object by inverting it and component labeling in XY slicewise
$! 
$! USAGE:
$!  @ez:close_slw.com 'in_file' 'out_file' 'border' 'invert?' 'min_vol,max_vol' 'value'
$!
$! PARAMETERS:
$!  P1  : Input SEG file
$!  P2  : Output SEG file              
$!  P3* : Border in x & y              (*0)
$!  P4* : Invert image before cl ?     (*TRUE/FALSE)
$!  P5* : Minvol,Maxvol                (*0)
$!  P6* : Value object                 (*127)
$! 
$! EXAMPLE:
$!  ...
$! 
$! VERSION HISTORY:
$!  2012.10.26 Created
$!  2018.12.3 EZ Format
$!
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say "  "
$ say "=========================================================="
$ say "!! CLOSE_SLW.COM:  "
$ say "=========================================================="
$!*
$!
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then goto terminate
$ if (p3 .eqs. "") then p3 = 30
$ if (p4 .eqs. "") then p4 = "TRUE"
$ if (p5 .eqs. "") then p5 = "50,100"
$ if (p6 .eqs. "") then p6 = 127
$
$  show symbol p1
$  show symbol p2
$  show symbol p3
$  show symbol p4
$  show symbol p5
$  show symbol p6
$
$  if (p4 .eqs. "TRUE")
$ 	 then 
$   	__tmp_val_obj   = 0
$   	__tmp_val_bg    = 127 
$    else
$   	__tmp_val_obj   = 127
$   	__tmp_val_bg    = 0 
$  endif
$
$  if (f$locate(",", p5) .lt. f$length(p5))
$ 	 then 
$   	__lo_vol_fract   = f$element(0,",",p5)
$   	__up_vol_fract   = f$element(1,",",p5)
$    else
$       goto terminate
$  endif
$
$
$ IPL_BATCH

/read
  -name                      in
  -filename                  "p1

! Create a background image 
/copy
  -in                        in
  -out                       bg

  
/set_value
  -input                     bg
  -value_object              1
  -value_background          1

  
/bounding_box_cut
  -input                     in
  -output                    tmp
  -z_only                    false
  -border                    "p3 "p3 0


/set_value
  -input                     tmp
  -value_object              "__tmp_val_obj
  -value_background          "__tmp_val_bg

  
/cl_slicewise_extractow
  -input_output              tmp
  -lo_vol_fract_in_perc      "__lo_vol_fract
  -up_vol_fract_in_perc      "__up_vol_fract
  -value_in_range            "p5
  -topology                  6


/set_value
  -input                     tmp
  -value_object              "__tmp_val_obj
  -value_background          "__tmp_val_bg
  
  
! Crop to original dimensions
/multiply_volumes
  -input1                    tmp
  -input2                    bg
  -output                    out
  -common_region_only        true
  -multiply_zero_pixels      true
  

/write_v020
  -name                      out
  -filename                  "p2
  -compress_type             bin
  -version_020               true
  
..
$
$!#
$ say "!! CLOSE_SLW.COM: Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper CLOSE_SLW.com
$ exit