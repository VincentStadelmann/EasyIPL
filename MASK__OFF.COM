$!****************************************************************************************            
$! MASK__OFF.COM
$!  Written by: Vincent Stadelmann
$!  Copyright (c) 2018 SCANCO Medical AG
$!  Do not duplicate or distribute without written permission 
$! 
$! Version history:
$!  2016.03.04 V. Stadelmann
$!  2017.05.19 input can be grayscale
$!  2017.11.13 Use get__geo and create_canvas to speed up
$! 
$! Usage:
$!  @ue:mask__off.com	'ipl_aim1' 'ipl_aim2' 'eval_logfile2' 'ipl_maskedaim'
$!  P1 : name of original aim
$!  P2 : name of seg aim to use as mask
$!  P3 : name of output aim
$!
$!****************************************************************************************            
$!
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! MASK__OFF.COM: masks off part of an aim with a seg aim  "
$ say "=========================================================="
$!*
$!
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then goto terminate
$ if (p3 .eqs. "") then goto terminate
$ if (p4 .eqs. "") then goto terminate
$
$ sh sym p1
$ sh sym p2
$ sh sym p3
$ sh sym p4
$
$ tmp_mask = P1 - ".AIM" + "_TMPMASK.GOBJ"
$ sh sym tmp_mask
$
$!
$! Prepare skips 
$ if ("''get__geometry_skip'" .eqs. "") then get__geometry_skip == 0
$ if (get__geometry_skip .nes. "") then skip := "/skip=''get__geometry_skip'"
$ if (get__geometry_skip .eq. 0) then skip := ""
$ get__geometry_skip == get__geometry_skip + 1
$ sh sym skip
$ sh sym get__geometry_skip
$ 
$!
$ IPL_BATCH

/read
  -name                      in
  -filename                  "p1

/examine
  	-input                   in
  	-item                    geometry    
	
..	
$! Extract dimensions from logfile
$ set output_rate=00:00:01
$ wait 00:00:02 
$!
$! Search for dim
$ pipe search 'p3' "!> dim  " 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimdim = line_sym - "!> dim   "
$ aimdim = f$edit(aimdim,"trim,compress")
$!
$! Search for offset
$ pipe search 'p3' "!> off  " 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimoffset = line_sym - "!> off  "
$ aimoffset = f$edit(aimoffset,"trim,compress")  
$!
$! Search for pos
$ pipe search 'p3' "!> pos  " 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimpos = line_sym - "!> pos   "
$ aimpos = f$edit(aimpos,"trim,compress")  
$!
$! Search for el size
$ pipe search 'p3' "!> element size in mm" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimelsize = line_sym - "!> element size in mm "
$ aimelsize = f$edit(aimelsize,"trim,compress")  
$!
$
$ ipl_batch

/read
  -name                      in
  -filename                  "P1

!/absolute_threshold
!  -input                     in
!  -output                    bg
!  -lower_in_abs              0
!  -upper_in_abs              32767.000000
!  -grayscale_or_scaledvalues true
!  -value_in_range            127
  
/create_canvas
  -output                    bg
  -dim                       "aimdim
  -off                       "aimoffset
  -pos                       "aimpos
  -el_size_mm                "aimelsize
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
  -gobj_filename             "tmp_mask
  -min_elements              0
  -max_elements              0
  -curvature_smooth          1

/gobj_maskaimpeel_ow
  -input_output              in
  -gobj_filename             "tmp_mask
  -peel_iter                 0
   
/write
  -name                      in
  -filename                  "P4
  -compress_type             bin
  -version_020               true    

..
$ say "!! MASK__OFF.COM: completed	 "
$ say "=========================================================="
$ exit
$
$ terminate:
$ say "!! P1 : name of input file"
$ say "!! P2 : name of mask file"
$ say "!! P3 : logfile"
$ say "!! P4 : output file"
$ exit
