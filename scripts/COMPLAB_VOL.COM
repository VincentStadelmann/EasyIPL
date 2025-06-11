$!****************************************************************************************            
$! COMPLAB_VOL.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Select objects between Min_volume and Max_volume 
$!  Volumes can be expressed in voxels or in % of total
$!
$! USAGE:
$!  @ez:complab_vol	'in_file' 'out_file' 'min_vol' 'max_vol' 'value_out'
$!
$! PARAMETERS:
$!  P1  : Input SEG file
$!  P2* : Output SEG file       (*_CL.AIM)
$!  P3* : Min volume            (*5%)
$!  P4* : Max volume        	(*100%)
$!  P5* : Value object out      (*127)
$! 
$! VERSION HISTORY:
$!  2018.07.29 Minor bugs
$!  2018.10.19 EZ Format
$!
$!****************************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! COMPLAB_VOL.COM:	"
$ say "=========================================================="
$!*
$!
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_CL.AIM"
$ if (p3 .eqs. "") then p3 := 5%
$ if (p5 .eqs. "") then p5 = 127
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$ show symbol p5
$
$! Detect if volume expressed in voxels or percent
$ if (f$locate("%", p3) .lt. f$length(p3)) then goto cl_in_percent
$ if (p4 .eqs. "") then p4 = 0
$
$ cl_in_vol:
$ IPL_BATCH

/read
  -name                      in
  -filename                  "P1

/cl_nr_extract
  -input                     in
  -output                    cl
  -min_number                "p3
  -max_number                "p4
  -value_in_range            "p5
  -topology                  6
  
/write
  -name                      cl
  -filename                  "P2
  -compress_type             bin
  -version_020               true
  
..
$ goto completed
$
$ cl_in_percent:
$ if (p4 .eqs. "") then p4 := 100%
$
$ IPL_BATCH

/read
  -name                      in
  -filename                  "p1

/cl_extract
  -input                     in
  -output                    cl
  -lo_vol_fract_in_perc      "p3
  -up_vol_fract_in_perc      "p4
  -value_in_range            "p5
  -topology                  6
  
/write_v020
  -name                      cl
  -filename                  "p2
  -compress_type             bin
  -version_020               true
  
..
$
$ completed:
$!#
$ say "!! COMPLAB_VOL.COM:	completed	 "
$ say "=========================================================="
$ exit
$!
$ terminate:
$  @ez:helper COMPLAB_VOL.com
$ exit