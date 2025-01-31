$!************************* EZ_IPL *****************************************           
$!
$! ABS_THRESHOLD.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2012.09.05
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Threshold an image with absolute value
$! 
$! USAGE:
$!  @ez:abs_threshold.com 'input_filename' 'seg_filename' 'lower' 'upper' 'value'
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2* : Output binary AIM file   (*_SEG.AIM)
$!  P3* : Lower absolute threshold (*0)
$!  P4* : Upper absolute threshold (*32767)
$!  P5* : Value object (*127)
$!
$! EXAMPLE:
$!  Threshold a binary image 'seg1_file' from value 10 to 20 only into 'seg2_file'
$!  @ez:abs_threshold.com 'seg1_file' 'seg2_file' 10 20
$!
$! VERSION HISTORY:
$!  2016.01.10 Added default values
$!  2018.10.18 EZ format
$!
$!***************************************************************************            
$
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! ABS_THRESHOLD.COM:  "
$ say "=========================================================="
$!*
$
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then p2 = p1 -".AIM" + "_SEG.AIM"
$  if (p3 .eqs. "") then p3 = 0 
$  if (p4 .eqs. "") then p4 = 32767
$  if (p5 .eqs. "") then p5 = 127 
$
$  show symbol p1
$  show symbol p2
$  show symbol p3
$  show symbol p4
$  show symbol p5
$!
$ ipl_batch

/read
  -name                      in
  -filename                  "p1
  
/absolute_threshold
  -input                     in
  -output                    out
  -lower_in_abs              "p3
  -upper_in_abs              "p4
  -grayscale_or_scaledvalues true
  -value_in_range            "p5
     
/write
  -name                      out
  -filename                  "p2
  -compress_type             bin
  -version_020               true    

..
$!#
$ say "!! ABS_THRESHOLD.COM:	Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper ABS_THRESHOLD.com
$ exit