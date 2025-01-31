$!************************* EZ_IPL *****************************************           
$!
$! SET_VALUE.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Sets non-zero voxels to value_object and zero voxels to value_background
$! 
$! USAGE:
$!  @ez:set_value.com	'in_file' 'out_file'  'val_obj' 'val_bg'
$!
$! PARAMETERS:
$!  P1  : Input binary AIM file
$!  P2* : Output binary AIM file         (*_SV.AIM)
$!  P3* : Value object (-127...127)      (*127)
$!  P4* : Value background (-127...127)  (*0)
$! 
$! EXAMPLE:
$!  Inverse image.aim  
$!  @ez:set_value image.aim inverse.aim 0 127
$! 
$! VERSION HISTORY:
$!  2013.06.07 Minor changes
$!  2018.06.01 Formating
$!  2018.10.20 EZ Format
$!
$!****************************************************************************************            
$
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! SET_VALUE.COM:  "
$ say "=========================================================="
$!*
$
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_SV.AIM"
$  if (p3 .eqs. "") then p3 = 127
$  if (p4 .eqs. "") then p4 = 0
$
$  show symbol p1
$  show symbol p2
$  show symbol p3
$  show symbol p4
$
$ IPL_BATCH

/read
  -name                      tmp
  -filename                  "P1
  
/set_value
  -input                     tmp
  -value_object              "P3
  -value_background          "P4
     
/write
  -name                      tmp
  -filename                  "P2
  -compress_type             bin
  -version_020               true    

..
$
$!#
$ say "!! SET_VALUE.COM: Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper SET_VALUE.com
$ exit
