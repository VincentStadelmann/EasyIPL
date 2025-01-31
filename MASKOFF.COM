$!****************************************************************************************            
$! MASKOFF.COM
$! 
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! VERSION HISTORY:
$!  2016.03.04 
$!  2017.05.19 Input can be grayscale
$! 
$! DESCRIPTION:
$!  Masks off part of an AIM with a mask. 
$! 
$! USAGE:
$!  @'scripts_dir'maskoff.com	'ipl_aim1' 'ipl_aim2' 'ipl_maskedaim'
$!
$! PARAMETERS:
$!  P1 : name of original aim
$!  P2 : name of seg aim to use as mask
$!  P3 : name of output aim
$!
$!****************************************************************************************            
$
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! MASKOFF.COM: masks off part of an aim with a seg aim  "
$ say "=========================================================="
$!*
$!
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then goto terminate
$ if (p3 .eqs. "") then goto terminate
$
$ sh sym p1
$ sh sym p2
$ sh sym p3
$
$ tmp_mask = P1 - ".AIM" + "_TMPMASK.GOBJ"
$ sh sym tmp_mask
$!
$ ipl_batch

/read
  -name                      in
  -filename                  "P1

/absolute_threshold
  -input                     in
  -output                    bg
  -lower_in_abs              0
  -upper_in_abs              32767.000000
  -grayscale_or_scaledvalues true
  -value_in_range            127
  
/set_value
  -input                     bg
  -value_object              127
  -value_background          127
  
/read
  -name                      seg
  -filename                  "P2
 
/set_value
  -input                     seg
  -value_object              -127
  -value_background          0
    
/add_aims
  	-input1                  seg
  	-input2                  bg
  	-output                  mask 

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
  -filename                  "P3
  -compress_type             bin
  -version_020               true    

..
$!#
$ say "!! MASKOFF.COM: completed	 "
$ say "=========================================================="
$ exit
$
$ terminate:
$  say "!! P1 : name of input file"
$  say "!! P2 : name of mask file"
$  say "!! P3 : output file"
$ exit
