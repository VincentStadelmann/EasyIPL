$!************************* EZ_IPL *****************************************           
$!
$! GAUSS.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2014.12.18 
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Apply Gaussian filter of sigma sig and support sup to an image 
$!  The first sup slices of the image are lost after filtering, 
$!  the fill_offset = true will fill the lost slices with copies
$! 
$! USAGE:
$!  @ez:gauss	'in_file' 'out_file' 'sigma' 'support' 'fill_offset?' 
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2* : Output AIM file       (*_GAUSS.AIM)
$!  P3* : Gaussian sigma        (*0)
$!  P4* : Gaussian support      (*0)
$!  P5* : Fill offset?          (*true/false)
$! 
$! EXAMPLE:
$!  Filter image.aim with a GAUSS filter of sigma 0.8 and support 2 
$!  and fill the 2 lost slices with duplicates
$!  @ez:gauss image.aim gauss.aim 0.8 2 true
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
$ say "!! GAUSS.COM: "
$ say "=========================================================="
$!*
$
$! Check inputs
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_GAUSS.AIM"
$  if (p3 .eqs. "") then p3 = 0
$  if (p4 .eqs. "") then p4 = 0
$  if (p5 .nes. "FALSE") then p5 = "TRUE"
$
$  show symbol p1
$  show symbol p2
$  show symbol p3
$  show symbol p4
$  show symbol p5
$
$! Optional fill_offset
$  fill_offs = "!!"
$  if (p5 .eqs. "TRUE") then fill_offs = "/fill_offset_duplicate out"
$  show symbol fill_offs
$
$!
$ IPL_BATCH

/read
  -name                      in
  -filename                  "P1
  
/gauss_lp
  -input                     in
  -output                    out
  -sigma                     "p3
  -support                   "p4
  
"fill_offs

/write
  -name                      out
  -filename                  "p2
  -compress_type             bin
  -version_020               true    

..
$!#
$ say "!! GAUSS.COM: Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper GAUSS.com
$ exit
