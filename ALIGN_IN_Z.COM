$!************************* EZ_IPL *****************************************           
$!
$! ALIGN_IN_Z.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2011.09.20
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Aligns image according to input coordinates (generally from moment3D)
$!  The coordinates are: new origin point, new z-axis point and new xz 
$!  plane point. Then the image is relocated within the (+,+,+) quadrant 
$!  to be uct_evaluation compatible. 
$! 
$! USAGE:
$!  @ez:align_in_z 'in_file' 'out_file' 'pointO' 'pointZ' 'pointXZ' 'interpolate?'
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2* : Output AIM file   (*__AZ.AIM)
$!  P3* : Origin point      (*0,0,0)
$!  P4* : Point on axis OZ  (*0,0,1)
$!  P5* : Point on plane XZ (*1,0,0)
$!  p6* : Interpolate ?     (*true/false)
$!
$! EXAMPLE:
$!   Flip image.aim Z -> Y and save it as image__ZY.aim 
$!   @ez:align_in_z.com	image.aim image__ZY.aim  0,0,0   0,1,0   1,0,0
$!
$! VERSION HISTORY: 
$!  2014.04.02 HEADER, usage
$!  2017.07.10 Take "." or " " for coordinate separation
$!  2018.10.17 Default output name __AZ + take only "," for coordinates
$!  2018.10.18 EZ format
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! ALIGN_IN_Z.COM:  "
$ say "=========================================================="
$!*
$
$  say "!! Test inputs"
$   if (p1 .eqs. "") then goto terminate
$   if (p2 .eqs. "") then p2 = p1 -".AIM" + "__AZ.AIM"
$   if (p3 .eqs. "") then p3 = 0,0,0 
$   if (p4 .eqs. "") then p4 = 0,0,1
$   if (p5 .eqs. "") then p5 = 1,0,0 
$   if (p6 .eqs. "FALSE" .or. p6 .eqs. "F") then p6 = 0
$   if (p6 .nes. "0") then p6 = 1
$   if (f$locate(",", p3) .eq. f$length(p3)) then goto terminate
$   if (f$locate(",", p4) .eq. f$length(p4)) then goto terminate
$   if (f$locate(",", p5) .eq. f$length(p5)) then goto terminate
$
$! Show inputs
$   i = 1
$   loop_i:
$     show sym p'i'
$     i = i+1
$     if (i .le. 6) then goto loop_i
$
$  say "!! Parse coordinates"
$   @ez:vector__parse 'p3' origin_point
$   @ez:vector__parse 'p4' oz_point
$   @ez:vector__parse 'p5' xz_point
$
$ IPL_BATCH

/read
  -name                     in
  -filename                 "p1
  
/align_z
  -input					in
  -output					out
  -origin_point				"origin_point__ipl
  -z-axis_point				"oz_point__ipl
  -xz-plane					"xz_point__ipl
  -img_interpol_option      "p6

/header_geo_set
  -input                     out
  -off_new                   0 0 0 
  -pos_new                   0 0 0 
  -el_size_mm_new            -1
  
/write
  -name                      out
  -filename                  "p2
  -compress_type             bin
  -version_020               true

..
$!#
$ say "!! ALIGN_IN_Z.COM:	Completed "
$ say "==========================================================" 
$ exit 
$
$ terminate:
$  @ez:helper ALIGN_IN_Z.com
$ exit