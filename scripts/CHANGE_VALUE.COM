$!************************* EZ_IPL *****************************************           
$!
$! CHANGE_VALUE.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2017.12.04
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$! 
$! DESCRIPTION:
$!  Assign new_value to voxels with old_value in a seg image 
$!
$! USAGE:
$!  @ez:change_value.com  	'in_file' 'out_file' 'old_val' 'new_val'
$!
$! PARAMETERS:
$!  P1 : Input AIM file
$!  P2 : Output AIM file
$!  P3* : Old value (*127)
$!  P4* : New value (*127)
$! 
$! EXAMPLE:
$!  Replace value 127 by 100 in seg.aim  
$!  @ez:change_value seg.aim seg.aim 127 100
$!
$! VERSION HISTORY:
$!  2018.10.19 EZ Format
$!
$!***************************************************************************            
$
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! CHANGE_VALUE.COM:  "
$ say "=========================================================="
$!*
$!
$
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then goto terminate
$ if (p3 .eqs. "") then p3 = 127
$ if (p4 .eqs. "") then p4 = 127
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$
$ icalc 'p4'-('p3')
$ delta = icalc_out
$ show symbol delta
$!
$ ipl_batch

/read
  -name                      in
  -filename                  "p1
  
/absolute_threshold
  -input                     in
  -output                    dif
  -lower_in_abs              "p3
  -upper_in_abs              "p3
  -grayscale_or_scaledvalues true
  -value_in_range            "delta

/add_aims
  	-input1                  in
  	-input2                  dif
  	-output                  out    

/write
  -name                      out
  -filename                  "p2
  -compress_type             bin
  -version_020               true    

..
$!#
$ say "!! CHANGE_VALUE.COM:	Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper CHANGE_VALUE.com
$ exit