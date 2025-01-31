$!****************************************************************************************            
$! SET__VALUE_GOBJ.COM
$! 
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! VERSION HISTORY:
$!  2012.06.07 V. Stadelmann
$!  2018.02.26 added gobj
$! 
$! DESCRIPTION:
$!  Set value of seg aim with value within gobj, value outside gobj, value background
$! 
$! USAGE:
$!  @ue:set__value_gobj.com	'ipl_input' 'ipl_output' 'gobj' 'ipl_value_list' 
$!
$! PARAMETERS:
$!  P1 : input aim file
$!  P2 : output aim file
$!  P3 : gobj file
$!  P4 : values object (in,out,background)
$!
$!****************************************************************************************            
$
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! SET__VALUE_GOBJ.COM:  "
$ say "=========================================================="
$!*
$
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then goto terminate
$ if (p3 .eqs. "") then goto terminate
$ if (p4 .eqs. "") then p3 := 127,100,0
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$
$ val_in  = f$element(0,",",p4)
$ val_out = f$element(1,",",p4)
$ val_bg  = f$element(2,",",p4)
$ val_neg = -1 * val_out
$ sh sym val_*
$
$ IPL_BATCH

/read
  -name                      in
  -filename                  "p1

/copy
  -in                        in
  -out                       out
  
/gobj_maskaimpeel_ow
  -input_output              in
  -gobj_filename             "p3
  -peel_iter                 0
  
/copy
  -in                        in
  -out                       neg

/set_value
  -input                     in
  -value_object              "val_in
  -value_background          0
  
/set_value
  -input                     neg
  -value_object              "val_neg
  -value_background          0

/set_value
  -input                     out
  -value_object              "val_out
  -value_background          "val_bg
  
/add_aims
  -input1                    out
  -input2                    neg
  -output                    tmp
  
/add_aims
  -input1                    tmp
  -input2                    in
  -output                    out
  
/write
  -name                      out
  -filename                  "P2
  -compress_type             bin
  -version_020               true    

..
$!#
$ say "!! SET__VALUE_GOBJ.COM: Completed "
$ say "=========================================================="
$ exit
$ terminate:
$   say "!! P1 : input file"
$   say "!! P2 : output file"
$   say "!! P3 : gobj file"
$   say "!! P4 : ipl_value_list (value_in,value_out,value_bg)"
$ exit
