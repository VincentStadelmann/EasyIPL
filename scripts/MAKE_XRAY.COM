$!************************* EZ_IPL *****************************************           
$!
$! MAKE_XRAY.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2015.07.13
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Generate the Xray projection of an AIM
$! 
$! USAGE:
$!  @ez:make_xray 'aim_file' 'xray_file' 'start_slice' 'nb_slice' 'fixed_norm' 
$!
$! PARAMETERS:
$!  P1 : name of input file
$!  P2 : name of xray file
$!  P3* : start slice      (*0)
$!  P4* : number of slices (*16)
$!  P5* : fixed norm       (*true/false)                 
$!
$! EXAMPLE:
$!   
$!
$! VERSION HISTORY:
$!  2015.07.13
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! MAKE_XRAY.COM "
$ say "=========================================================="
$!*
$
$! Test inputs
$    if (p1 .eqs. "") then goto terminate
$    if (p2 .eqs. "") then goto terminate
$    if (p3 .eqs. "") then p3 = 0
$    if (p4 .eqs. "") then p4 = 16
$    if (p5 .eqs. "") then p5 := true
$    show symbol p1
$    show symbol p2
$    show symbol p3
$    show symbol p4
$    show symbol p5
$!
$ IPL_BATCH

/read
  -name                      in
  -filename                  "P1
  
/xray
  -input                     in
  -output                    out
  -startslice                "P3
  -number_of_slices          "P4
  -fixed_norm_char           "P5
 
/write
  -name                      out
  -filename                  "P2
  -compress_type             bin
  -version_020               true    

..
$ say "!! MAKE_XRAY.COM: completed	 "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper MAKE_XRAY
$ exit