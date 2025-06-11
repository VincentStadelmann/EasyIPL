$!****************************************************************************************            
$!
$! SEG_GAUSS.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Apply a gaussian filter to an image to reduce noise then threshold it
$!
$! USAGE:
$!  @ez:seg_gauss 'in_file' 'out_file' 'lower' 'upper' 'sigma' 'support' 'value'
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2* : Output SEG file       (*_SEG.AIM)
$!  P3* : Lower threshold       (*200)
$!  P4* : Upper threshold       (*1000)
$!  P5* : Gauss sigma           (*0.5)
$!  P6* : Gauss support         (*1)
$!  P7* : Value object out      (*127)
$! 
$! EXAMPLE:
$!  Apply a gaussian of sigma=1 support=2 to image.aim 
$!  and select object between 100 and 200 scanco units
$!  @ez:seg_gauss image.aim seg.aim 100 200 1 2 
$! 
$! VERSION HISTORY:
$!  2011.09.01 Created 
$!  2012.02.08 Minor bugs & formatting
$!  2017.09.07 /SUP
$!  2018.10.19 EZ Format
$!
$!****************************************************************************************            
$
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! SEG_GAUSS.COM:	 "
$ say "=========================================================="
$!*
$!
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_SEG.AIM"
$  if (p3 .eqs. "") then p3 := 200 
$  if (p4 .eqs. "") then p4 := 1000
$  if (p5 .eqs. "") then p5 := 0.5
$  if (p6 .eqs. "") then p6 := 1
$  if (p7 .eqs. "") then p7 := 127 
$
$ IPL_BATCH

/read
  -name                      tmp
  -filename                  "P1
 
/sup_divide
  -input                     tmp
  -supdim_numbers            4 4 1
  -testoff_pixels            "P6
  -suppos_pixels_local       -1 -1 -1
  -subdim_pixels             -1 -1 -1
 
/seg_gauss
  -input                     tmp
  -output                    seg
  -sigma                     "P5
  -support                   "P6
  -lower_in_perm_aut_al      "P3
  -upper_in_perm_aut_al      "P4
  -value_in_range            "P7
  -unit                      0

/write
  -name                      seg
  -filename                  "P2
  -compress_type             bin
  -version_020               true    

..
$
$!#
$ say "!! SEG_GAUSS.COM: completed	 "
$ say "=========================================================="
$ exit
$
$
$ terminate:
$  @ez:helper SEG_GAUSS.com
$ exit
