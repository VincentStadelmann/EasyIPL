$!************************* EZ_IPL *****************************************    
$!       
$! VECTOR__DOT_PRODUCT.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2017.07.11
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Computes the dot product of u.v = u_1*v_1 + u_2*v_2 + u_3*v_3
$!
$! PARAMETERS:
$!  P1 : vector U (u1,u2,u3)
$!  P2 : vector V (v1,v2,v3)
$!  P3 : Output vector name
$!
$! USAGE:
$!   @ez:vector__dot_product.com	'vec_u' 'vec_v' product
$!
$! VERSION HISTORY:
$!  2017.07.11 Output vector symbol
$!  2017.08.24 New format ","
$!  2018.10.22 EZ Format
$!  2018.11.20 New attributes
$!  2018.11.21 Icalc_nolog
$!
$!***************************************************************************                    
$
$  @ez:vector__init.com 
$
$ say "  "
$! say "=========================================================="
$ say "!! VECTOR__DOT_PRODUCT.COM:  "
$! say "=========================================================="
$
$
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then goto terminate
$  if (p3 .eqs. "") then goto terminate
$
$!  show symbol p1
$!  show symbol p2
$!  show symbol p3
$
$  @ez:vector__parse.com  'p1' __vdp_u 
$  @ez:vector__parse.com  'p2' __vdp_v 
$  if (__vdp_u__h .nes. "V") then goto terminate1
$  if (__vdp_v__h .nes. "V") then goto terminate1
$
$!  say "!! Compute dot product: u.v = u_1*v_1 + u_2*v_2 + u_3*v_3"
$   ic_nolog
$   icalc  '__vdp_u__1'*'__vdp_v__1' + '__vdp_u__2'*'__vdp_v__2' + '__vdp_u__3'*'__vdp_v__3'
$   'p3' == icalc_out
$   
$  sh sym 'p3'
$!
$! say "  "
$! say "!! VECTOR__DOT_PRODUCT.COM:	Completed "
$! say "==========================================================" 
$ exit 
$
$
$ terminate:
$   @ez:helper VECTOR__DOT_PRODUCT
$   exit
$
$ terminate1:
$   say "  "
$   say "!! VECTOR__DOT_PRODUCT Error: invalid parameters"
$   sh sym p1
$   sh sym p2
$   sh sym p3
$   exit