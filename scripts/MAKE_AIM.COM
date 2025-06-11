$!************************* EZ_IPL *****************************************           
$!
$! MAKE_AIM.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2017.07.17
$!  Copyright (c) 2011-2019 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Creates a new AIM with a constant value
$! 
$! USAGE:
$!  @ez:MAKE_AIM 'aim_file' 'pos' 'dim' 'offset' 'elsize' 'type' 'val'
$!
$! PARAMETERS:
$!   P1: Filename 
$!   P2*: Position vector        (*0,0,0)                      
$!   P3*: Dimension vector       (*10,10,10)
$!   P4*: Offset vector          (*0,0,0)
$!   P5*: Element size           (*1)
$!   P6*: Type                   (*char) 
$!   P7*: Value                  (*127) 
$!
$! EXAMPLE:
$!   
$!
$! VERSION HISTORY:
$!  2018.03.08 Vector format
$!  2019.03.11 EZ format
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! MAKE_AIM.COM:  "
$ say "=========================================================="
$!*
$
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 := 0,0,0
$ if (p3 .eqs. "") then p3 := 10,10,10
$ if (p4 .eqs. "") then p4 := 0,0,0
$ if (p5 .eqs. "") then p5 := 1
$ if (p6 .eqs. "") then p6 := char
$ if (p7 .eqs. "") then p7 = 127
$
$! Parse inputs
$  @ez:vector__parse.com  'p2' __can_pos
$  @ez:vector__parse.com  'p3' __can_dim
$  @ez:vector__parse.com  'p4' __can_off
$  if (__can_pos__h .nes. "V") then goto terminate 
$  if (__can_dim__h .nes. "V") then goto terminate 
$  if (__can_off__h .nes. "V") then goto terminate 
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$ show symbol p5
$ show symbol p6
$ show symbol p7
$
$ IPL_BATCH

/create_canvas
  -output                    in
  -dim                       "__can_dim__ipl
  -off                       "__can_off__ipl
  -pos                       "__can_pos__ipl
  -el_size_mm                "p5
  -type                      "p6

/set_value
  -input                     in
  -value_object              "p7
  -value_background          "p7

/write_v020
  -name                      in
  -filename                  "p1
  -compress_type             bin
  -version_020               true

..
$!#
$ say "!! MAKE_AIM.COM:	Completed "
$ say "=========================================================="
$ exit
$ terminate:
$   @ez:helper MAKE_AIM
$ exit