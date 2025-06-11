$!************************* EZ_IPL *****************************************    
$!       
$! VECTOR__FLOOR.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2017.08.23
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Floors each coordinate to next integer
$!
$! PARAMETERS:
$!  P1 : Vector u (u1,u2,u3)
$!  P2 : Output vector name
$!
$! USAGE:
$!   @ez:vector__floor.com	'u1,u2,u3' out_vec
$!
$! VERSION HISTORY:
$!  2018.10.22 EZ Format
$!  2018.11.20 New attributes
$!  2018.11.21 Icalc_nolog
$!
$!***************************************************************************            
$
$  @ez:vector__init.com 
$
$  say "  "
$! say "=========================================================="
$  say "!! VECTOR__FLOOR.COM:  "
$! say "=========================================================="
$
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then goto terminate
$
$  show symbol p1
$  show symbol p2
$
$  @ez:vector__parse.com  'p1' __vf_u 
$
$! Compute floor of each coordinate
$      ic_nolog
$   icalc floor('__vf_u__1')
$   __vf_f__1 = icalc_out
$      ic_nolog
$   icalc floor('__vf_u__2')
$   __vf_f__2 = icalc_out
$      ic_nolog
$   icalc floor('__vf_u__3')
$   __vf_f__3 = icalc_out
$
$   @ez:vector__make.com  'p2' '__vf_f__1' '__vf_f__2' '__vf_f__3'
$
$! say "  "
$! say "!! VECTOR__FLOOR.COM:	Completed "
$! say "==========================================================" 
$ exit 
$
$ terminate:
$   @ez:helper VECTOR__FLOOR
$ exit
