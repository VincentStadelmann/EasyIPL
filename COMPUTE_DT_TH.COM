$!************************* EZ_IPL *****************************************           
$!
$! COMPUTE_DT_TH.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2017.10.31
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Compute thickness map of object with distance transform and 
$!  write results to database.
$! 
$! USAGE:
$!  @ez:compute_dt_th 'seg_file' 'th_file' 'histo_f' 'gobj_f' 'boundary' 'dtvars'
$!
$! PARAMETERS:
$!  P1  : Input segmented AIM
$!  P2  : Output thickness map AIM
$!  P3* : Output histogram file (.txt)                 (* _DT.TXT)
$!  P4* : Input GOBJ                                   (* gobj_from_log)    
$!  P5* : Supress_boundary                             (*0,1,2,3)    
$!  P6* : Peel_iter,Ridge_epsilon,Assign_epsilon       (*0,0.9,1.8)    
$!
$!  Options for P5 suppress_boundary:         
$!   0 = no suppression
$!   1 = suppress AIM boundary only
$!   2 = suppress GOBJ boundary only
$!   3 = suppress AIM and GOBJ boundary
$!
$! EXAMPLE:
$!   
$!
$! VERSION HISTORY:
$!  2017.10.31 V Stadelmann
$!  2018.12.09 Added P5 & P6
$!  2018.12.10 EZ format
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! COMPUTE_DT_TH.COM: "
$ say "=========================================================="
$!*
$
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then goto terminate
$ if (p3 .eqs. "") then p3 = p1 - ".AIM" + "_DT.TXT"
$ if (p4 .eqs. "") then p4 = "gobj_from_log"
$ if (p5 .eqs. "") then p5 = "0"
$ if (p5 .nes. "0" .and. p5 .nes. "1" .and. p5 .nes. "2" .and. p5 .nes. "3") then p5 = "0"
$ if (p6 .eqs. "") then p6 := 0,0.9,1.8
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$ show symbol p5
$ show symbol p6
$
$ @ez:vector__parse.com  'p6' __dt_params   
$ if (__dt_params__h .eqs. "F") then goto terminate
$
$
$ 	ipl_batch

/db_scanco_activate true

/read
  -name                      seg
  -filename    				 "p1

/dt_thickness
  -input                     seg
  -output                    out
  -gobj_filename             "p4
  -peel_iter                 "__dt_params__1
  -ridge_epsilon             "__dt_params__2
  -assign_epsilon            "__dt_params__3
  -histofile_or_screen       "p3
  -suppress_boundary         "p5
  -version                   3
  
/examine
  -input                     out
  -item                      stat

/write_v020
  -name                      out
  -filename                  "p2
  -compress_type             bin
  -version_020               true

..
$
$!#
$ 	say "!! COMPUTE_DT_TH.COM: Completed "
$ 	say "=========================================================="
$ 	exit
$!
$ terminate:
$  @ez:helper COMPUTE_DT_TH.com
$ exit
