$!************************* EZ_IPL *****************************************           
$!
$! MULTIPLY.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.06.18
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Mulitply an AIM by a factor voxel by voxel
$! 
$! USAGE:
$!  @ez:multiply.com  'input_file' 'output_file' 'factor' 
$!
$! PARAMETERS:
$!  P1 : Input AIM
$!  P2 : Output AIM
$!  P3*: Factor      (*1)
$! 
$! EXAMPLE:
$!  Multiply an image by a factor 3 
$!  @ez:multiply image_in.aim image_out.aim 3
$! 
$! VERSION HISTORY:
$!  2019.03.20 EZ Format
$!
$!***************************************************************************            
$!*
$
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! MULTIPLY.COM: 	" 
$ say "=========================================================="
$!*
$
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then goto terminate
$ if (p3 .eqs. "") then p3 = 1
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$
$
$ ipl_batch

/read
  -name                      in
  -filename                  "p1
  
/mult_constant_ow
  -in_out                    in
  -factor                    "p3
     
/write
  -name                      in
  -filename                  "p2
  -compress_type             bin
  -version_020               true    

..
$!#
$ say "!! MULTIPLY.COM: completed."
$ say "=========================================================="
$ exit
$
$ exit
$ terminate:
$  @ez:helper MULTIPLY
$ exit
