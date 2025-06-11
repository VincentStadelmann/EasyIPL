$!************************* EZ_IPL *****************************************           
$!
$! COMPLAB.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2012.06.07
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Select the Nth to Mth largest objects in image
$! 
$! USAGE:
$!  @ez:complab	'in_file' 'out_file' 'Nth_rank' 'Mth_rank' 'value_out'
$!
$! PARAMETERS:
$!  P1  : Input SEG file
$!  P2* : Output SEG file       (*_CL.AIM)
$!  P3* : Nth rank              (*1)
$!  P4* : Mth rank         		(*1)
$!  P5* : Value object          (*127)
$! 
$! EXAMPLE:
$!  Select only second object in seg.aim 
$!  @ez:complab seg.aim seg.aim 2 2
$! 
$! VERSION HISTORY:
$!  2018.10.19 EZ Format
$!
$!***************************************************************************            
$
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! COMPLAB.COM:	"
$ say "=========================================================="
$!*
$
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_CL.AIM"
$ if (p3 .eqs. "") then p3 = 1
$ if (p4 .eqs. "") then p4 = 1
$ if (p5 .eqs. "") then p5 = 127
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$ show symbol p5
$
$ IPL_BATCH

/read
  -name                      tmp
  -filename                  "p1

/cl_ow_rank_extract
  -input_output              tmp
  -first_rank                "p3
  -last_rank                 "p4
  -connect_boundary          false
  -value_in_range            "p5
  -topology                  6
    
/write
  -name                      tmp
  -filename                  "p2
  -compress_type             bin
  -version_020               true
  
..
$!#
$ say "!! COMPLAB.COM:	completed	 "
$ say "=========================================================="
$ exit
$!
$ terminate:
$  @ez:helper complab.com
$ exit