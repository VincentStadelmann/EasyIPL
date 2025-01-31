$!*************************************** Easy_IPL *****************************************           
$!
$! CONVERT.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2011.09.20
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Converts image to char or short
$! 
$! USAGE:
$!   @ez:convert.com	'input_file' 'out_file' 'type' 
$! 
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2* : Output AIM file (*_CONV.AIM)
$!  P3* : Type (*char/short)
$!
$! EXAMPLE:
$!  Transform image.aim into a short 
$!  @ez:convert image.aim image.aim short
$!
$! VERSION HISTORY:
$!  2018.06.18 Created
$!  2018.10.17 EZ format
$!
$!******************************************************************************************           
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! CONVERT.COM:  "
$ say "=========================================================="
$!*
$!
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 = p1 -".AIM" + "_CONV.AIM"
$ if (p3 .nes. "CHAR") then p3 = "SHORT"
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
  
/convert_to_type           
  -input                     in
  -output                    out
  -out_type                  "p3

     
/write
  -name                      out
  -filename                  "p2
  -compress_type             bin
  -version_020               true    

..
$ say "!! CONVERT.COM: completed."
$ say "=========================================================="
$ exit
$
$ exit
$ terminate:
$  @ez:helper CONVERT.com
$ exit
