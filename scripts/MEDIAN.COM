$!************************* EZ_IPL *****************************************           
$!
$! MEDIAN.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2014.12.18 
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Apply median filter of support S to an image 
$!  The filter kernel is K = 2*S+1
$!  The first S slices of the image are lost after filtering, 
$!  the fill_offset = true will fill the lost slices with copies
$! 
$! USAGE:
$!  @ez:median	'in_file' 'out_file' 'kernel' 'fill_offset?' 
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2* : Output AIM file       (*_MED.AIM)
$!  P3* : Kernel size           (*0)
$!  P4* : Fill offset?          (*true/false)
$! 
$! EXAMPLE:
$!  Filter image.aim with a median filter of kernel 5 
$!  and fill the 5 lost slices with duplicates
$!  @ez:median image.aim median.aim 5 true
$! 
$! VERSION HISTORY:
$!  2015.12.01 New option fill_offset
$!  2018.10.19 EZ Format
$!
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! MEDIAN.COM: "
$ say "=========================================================="
$!*
$
$! Check inputs
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_MED.AIM"
$  if (p3 .eqs. "") then p3 = 0
$  if (p4 .nes. "FALSE") then p4 = "TRUE"
$
$  show symbol p1
$  show symbol p2
$  show symbol p3
$  show symbol p4
$
$! Optional fill_offset
$  fill_offs = "!!"
$  if (p4 .eqs. "TRUE") then fill_offs = "/fill_offset_duplicate out"
$  show symbol fill_offs
$
$!
$ IPL_BATCH

/read
  -name                      in
  -filename                  "P1
  
/median_filter
  -input                     in
  -output                    out
  -support                   "P3
  
"fill_offs

/write
  -name                      out
  -filename                  "P2
  -compress_type             bin
  -version_020               true    

..
$!#
$ say "!! MEDIAN.COM: Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper median.com
$ exit
