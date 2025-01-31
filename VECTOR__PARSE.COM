$!************************* EZ_IPL *****************************************    
$!       
$! VECTOR__PARSE.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2017.08.23
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Parses coordinates from 'ux,uy,uz'
$!
$! PARAMETERS:
$!  P1 : Vector (u1,u2,u3)
$!  P2 : Vector name
$!
$! USAGE:
$!  @ez:vector__parse.com  'ux,uy,uz' vecname   
$!
$! VERSION HISTORY:
$!  2018.10.22 EZ Format
$!  2018.11.21 Icalc_nolog
$!
$!***************************************************************************            
$!
$  @ez:vector__init.com 
$
$! say "  "
$! say "=========================================================="
$! say "!! VECTOR__PARSE.COM:  "
$! say "=========================================================="
$!
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then goto terminate
$
$! Test inputs
$  if (f$locate(",", p1) .eq. f$length(p1)) then goto terminate1
$  if (f$element(0,",",p1) .eqs. "") then goto terminate1
$  if (f$element(1,",",p1) .eqs. "") then goto terminate1
$  if (f$element(2,",",p1) .eqs. "") then goto terminate1
$!
$!  show symbol p2
$!
$  __vp_u__1 = f$element(0,",",p1)
$  __vp_u__2 = f$element(1,",",p1)
$  __vp_u__3 = f$element(2,",",p1)
$!
$  @ez:vector__make.com  'p2' '__vp_u__1' '__vp_u__2' '__vp_u__3'
$!
$! say "!! VECTOR__PARSE.COM:	Completed "
$! say "=========================================================="
$ exit
$
$ terminate1:
$   say "  "
$  'p2'__H == "F"   
$   say "!! VECTOR__PARSE Error : invalid coordinates "
$   sh sym p1
$   exit
$
$ terminate:
$    @ez:helper VECTOR__PARSE.com
$   exit