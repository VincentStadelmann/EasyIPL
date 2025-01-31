$!************************* EZ_IPL *****************************************           
$!
$! DIVIDE_AIMS.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.06.18
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Divide voxel values of one AIM by voxels values of another AIM
$! 
$! USAGE:
$!  @ez:divide_aims.com 'aim1_file' 'aim2_file' 'div_file' 'common_only?'
$! 
$! PARAMETERS:
$!  P1  : Input AIM 1
$!  P2  : Input AIM 2
$!  P3* : Output AIM (*_DIV.AIM)
$!  P4* : Common region only? (*true/false)
$!
$! EXAMPLE:
$!   Divide numerator.aim by denominator.aim only in common region
$!   @ez:divide_aims  numerator.aim denominator.aim result.aim 
$!
$! VERSION HISTORY:
$!  2018.10.19 EZ Format
$!
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! DIVIDE_AIMS.COM: "
$ say "=========================================================="
$!*
$! Check inputs
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then goto terminate
$  if (p3 .eqs. "") then p3 = p1 -".AIM" + "_DIV.AIM"
$  if (p4 .nes. "FALSE") then p4 = "TRUE"
$
$  show symbol p1
$  show symbol p2
$  show symbol p3
$  show symbol p4
$!
$ IPL_BATCH

/read
  -name                      aim1
  -filename                  "P1

/read
  -name                      aim2
  -filename                  "P2
  
/divide_volumes
  -input1                    aim1
  -input2                    aim2
  -output                    div
  -common_region_only        "p4
  	
/write
  -name                      div
  -filename                  "P3
  -compress_type             bin
  -version_020               true

..
$ say "!! DIVIDE_AIMS.COM: completed."
$ say "=========================================================="
$ exit
$ terminate:
$  @ez:helper DIVIDE_AIMS.com
$ exit
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
