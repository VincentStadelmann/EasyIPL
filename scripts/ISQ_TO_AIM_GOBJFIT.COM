$!************************* EZ_IPL *****************************************           
$!
$! ISQ_TO_AIM_GOBJFIT.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2016.06.27
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Cuts out an AIM from an ISQ based on the position of a GOBJ
$! 
$! USAGE:
$!  @ez:isq_to_aim_gobjfit.com 'in_file' 'gobj_file' 'out_file' 'border' 'apply_gobj?'
$!
$! PARAMETERS:
$!  P1  : Input ISQ file
$!  P2* : Input GOBJ file       (*.GOBJ)
$!  P3* : Output AIM file       (*.AIM)
$!  P4* : Border                (*0)
$!  P5* : Apply GOBJ ?        	(true/*false)
$! 
$! EXAMPLE:
$!  Cut out image.aim from image.isq based on image.gobj  
$!  @ez:isq_to_aim_gobjfit image.isq image.aim image.gobj
$! 
$! VERSION HISTORY:
$!  2017.10.26 Apply_gobj_str instead of cases
$!  2018.10.19 EZ Format
$!  2018.10.22 Reorder p4 and p5
$!
$!***************************************************************************            
$
$  say = "write sys$output"
$  say " "
$  say "=========================================================="
$  say "!! ISQ_TO_AIM_GOBJFIT.COM: "
$  say "=========================================================="
$!*
$
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then p2 = p1 - ".ISQ" + ".GOBJ"
$  if (p3 .eqs. "") then p3 = p1 - ".ISQ" + ".AIM"
$  if (p4 .eqs. "") then p4 = 0
$  if (p5 .eqs. "1") then p5 = "TRUE"
$  if (p5 .eqs. "T") then p5 = "TRUE"
$  if (p5 .nes. "TRUE") then p5 = "FALSE"
$
$  show symbol p1
$  show symbol p2
$  show symbol p3
$  show symbol p4
$  show symbol p5
$!
$  if (f$locate(",", p4) .eq. f$length(p4)) then __iag_border__ipl = p4
$  if (f$locate(",", p4) .lt. f$length(p4)) then @ez:vector__parse 'p4' __iag_border
$
$  if (p5 .eqs. "TRUE") then __iag_apply_gobj_str = "/gobj_maskaimpeel_ow in ''p2' 0 "
$  if (p5 .nes. "TRUE") then __iag_apply_gobj_str = "!! "
$
$!
$ ipl_batch

/isq_gobjfit_to_aim
  -aim_name                  in
  -isq_filename              "p1
  -gobj_filename             "p2
  -border                    "p4
  
"__iag_apply_gobj_str

/write
  -name                      in
  -filename                  "p3

..
$!#
$  say "!! ISQ_TO_AIM_GOBJFIT.COM:	Completed "
$  say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper ISQ_TO_AIM_GOBJFIT.com
$ exit