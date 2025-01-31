$!************************* EZ_IPL *****************************************           
$! ADD_2_AIMS.COM
$!
$!  Written by: Vincent Stadelmann 2011.09.20
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$!
$!
$! DESCRIPTION:
$!   Add two AIMs
$! 
$! USAGE:
$!   @ue:add_2_aims.com 'tmp1_filename' 'tmp2_filename' 'out_filename'
$! 
$! PARAMETERS:
$!  P1 : input aim 1
$!  P2 : input aim 2
$!  P3 : sum of aims
$!
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! ADD_2_AIMS.COM: "
$ say "=========================================================="
$!*
$
$  	if (p1 .eqs. "") then goto terminate
$  	if (p2 .eqs. "") then goto terminate
$  	if (p3 .eqs. "") then goto terminate
$
$   show symbol p1
$   show symbol p2
$   show symbol p3
$!
$ IPL_BATCH

/read
  -name                      aim1
  -filename                  "p1

/read
  -name                      aim2
  -filename                  "p2
  
/add_aims
  	-input1                  aim1
  	-input2                  aim2
  	-output                  sum  
  	
/write
    -name                    sum
    -filename                "p3
    -compress_type           bin
    -version_020             true

..
$!#
$ say "!! ADD_2_AIMS.COM: completed."
$ say "=========================================================="
$ exit
$
$ terminate:
$ say "  P1 : AIM1 NAME"
$ say "  P2 : AIM2 NAME"
$ say "  P3 : AIM1+AIM2 NAME"
$ exit
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
