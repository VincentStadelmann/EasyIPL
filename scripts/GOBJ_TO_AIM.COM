$!****************************************************************************************            
$! 
$! GOBJ_TO_AIM.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Create binary AIM from GOBJ mask
$! 
$! USAGE:
$!  @ez:gobj_to_aim.com	'gobj_file' 'aim_file' 'value' 'peel'
$!
$! PARAMETERS:
$!  P1  : Input GOBJ file
$!  P2  : Output AIM file (*_GTA.AIM)
$!  P3* : Value object    (*127)
$!  P4* : Peel dist       (*0)
$! 
$! VERSION HISTORY:
$!  2014.12.03 Created
$!  2017.11.13 Added ipl_value p3
$!  2018.10.19 Added peel p4
$!  2018.10.20 EZ format
$!
$!****************************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! GOBJ_TO_AIM.COM:  "
$ say "=========================================================="
$!*
$!
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then p2 = p1 - ".GOBJ" + "_GTA.AIM"
$  if (p3 .eqs. "") then p3 = 127
$  if (p4 .eqs. "") then p4 = 0
$!
$ IPL_BATCH

/gobj_to_aim
  -gobj_filename             "p1
  -output                    in
  -peel_iter                 "p4
    
/set_value
  -input                     in
  -value_object              "p3
  -value_background          0
  
/write_v020
  -name                      in
  -filename                  "p2
  -compress_type             bin
  -version_020               true
  
..
$
$!#
$ say "!! GOBJ_TO_AIM.COM: Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper GOBJ_TO_AIM.com
$ exit
