$!************************* EZ_IPL *****************************************           
$!
$! ISQ_TO_AIM.COM
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
$!  @ez:isq_to_aim.com 'in_file' 'out_file' 'position' 'dimensions'
$!
$! PARAMETERS:
$!  P1  : Input ISQ file
$!  P2* : Output AIM file           (*.AIM)
$!  P3* : Position of cutting box   (*0,0,0)
$!  P4* : Dimensions of cutting box (*-1,-1,-1 = full image)
$! 
$! EXAMPLE:
$!  Cut out image.aim from image.isq from 300 to 400 in all directions
$!  @ez:isq_to_aim image.isq image.aim 300,300,300 100,100,100
$! 
$! VERSION HISTORY:
$!  2018.03.05 Vec format
$!  2018.10.19 EZ Format
$!  2018.10.22 Reorder p4 and p5
$!  2021.03.07 Typo in title
$!
$!***************************************************************************            
$
$  say = "write sys$output"
$  say " "
$  say "=========================================================="
$  say "!! ISQ_TO_AIM.COM: "
$  say "=========================================================="
$!*
$
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then p2 = p1-".ISQ"+".AIM"
$  if (p3 .eqs. "") then p3 := 0,0,0
$  if (p4 .eqs. "") then p4 := -1,-1,-1
$
$  show symbol p1
$  show symbol p2
$  show symbol p3
$  show symbol p4
$!
$  if (f$locate(",",p3) .eq. f$length(p3)) then p3 := 0,0,0
$  if (f$locate(",",p4) .eq. f$length(p4)) then p4 := -1,-1,-1
$  @ez:vector__parse.com  'p3' __ia_position
$  @ez:vector__parse.com  'p4' __ia_dimensions
$!
$ ipl_batch

/isq_to_aim
  -aim_name                  in
  -isq_filename              "p1
  -pos                       "__ia_position__ipl
  -dim                       "__ia_dimensions__ipl

/write
  -name                      in
  -filename                  "p2

..
$
$!#
$  say "!! ISQ_TO_AIM.COM:	Completed "
$  say "=========================================================="
$ exit
$ terminate:
$  @ez:helper ISQ_TO_AIM.com
$ exit