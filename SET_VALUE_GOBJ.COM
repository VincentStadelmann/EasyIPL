$!************************* EZ_IPL *****************************************           
$!
$! SET_VALUE_GOBJ.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2015.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Define values of a SEG aim with new_value_within_gobj, 
$!  new_value_outside_gobj and value_background
$! 
$! USAGE:
$!  @ez:set_value_gobj.com 'in_file' 'out_file' 'gobj_file' 'value_list' 
$!
$! PARAMETERS:
$!  P1 : Input AIM file
$!  P2 : Output AIM file                
$!  P3 : Input GOBJ file                
$!  P4* : New values list val_in,val_out,val_bg (-127...127)  (*127,100,0)
$! 
$! EXAMPLE:
$!  Set image.aim value in mask.gobj to 110, outside 127 and background 10 
$!  @ez:set_value image.aim image.aim mask.gobj 110,127,10
$! 
$! VERSION HISTORY:
$!  2018.02.26 Added gobj
$!  2018.10.20 EZ Format
$!
$!****************************************************************************************            
$!*
$
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! SET_VALUE_GOBJ.COM:  "
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
$ if (f$locate(",", p4) .eq. f$length(p4)) then goto terminate
$ @ez:vector__parse 'p4' __svg_values
$
$ __minus_svg_values__2 = -1 * __svg_values__2
$ sh sym __minus_svg_values__2
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
  -value_object              "__svg_values__1
  -value_background          0
  
/set_value
  -input                     neg
  -value_object              "__minus_svg_values__2
  -value_background          0

/set_value
  -input                     out
  -value_object              "__svg_values__2
  -value_background          "__svg_values__3
  
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
$ say "!! SET_VALUE_GOBJ.COM: Completed "
$ say "=========================================================="
$ exit
$ terminate:
$  @ez:helper SET_VALUE_GOBJ.com
$ exit
