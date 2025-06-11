$!****************************************************************************************            
$! 
$! COMPLAB_SLW.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.10.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:                      
$!   Select objects between Min_volume and Max_volume       
$!   in % of total on a slice by slice basis                 
$!
$! USAGE:
$!  @ez:complab_slw	'in_file' 'out_file' 'min_vol_%' 'max_vol_%' 'value_out'
$!
$! PARAMETERS:
$!  P1  : Input SEG file
$!  P2* : Output SEG file       (*_CLSW.AIM)
$!  P3* : Min volume            (*5%)
$!  P4* : Max volume        	(*100%)
$!  P5* : Value object out      (*127)
$! 
$! VERSION HISTORY:
$!  2018.10.12 Minor bugs
$!  2018.10.19 EZ Format
$!
$!****************************************************************************************            
$!
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! COMPLAB_SLW.COM:	"
$ say "=========================================================="
$!*
$!
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_CLSW.AIM"
$ if (p3 .eqs. "") then p3 = 5
$ if (p4 .eqs. "") then p4 = 100
$ if (p5 .eqs. "") then p5 = 127
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$ show symbol p5
$
$
$ IPL_BATCH

/read
  -name                      in
  -filename                  "p1

  
/cl_slicewise_extractow
  -input_output              in
  -lo_vol_fract_in_perc      "p3
  -up_vol_fract_in_perc      "p4
  -value_in_range            "p5
  -topology                  6

  
/write
  -name                      in
  -filename                  "p2
  -compress_type             bin
  -version_020               true
  
..
$
$ completed:
$!#
$ say "!! COMPLAB_SLW.COM:	completed	 "
$ say "=========================================================="
$ exit
$!
$ terminate:
$  @ez:helper COMPLAB_SLW.com
$ exit