$!************************* EZ_IPL *****************************************    
$!       
$! VECTOR__CROSS_PRODUCT.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2017.07.10
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Computes the cross product  U X V
$!
$! PARAMETERS:
$!  P1 : Input vector U (u1,u2,u3)
$!  P2 : Input vector V (v1,v2,v3)
$!  P3 : Output vector name
$!
$! USAGE:
$!   @ez:vector__cross_product.com  'in1_vec' 'in2_vec' out_vec
$!
$! VERSION HISTORY:
$!  2017.07.11 VS output vector symbol
$!  2017.08.24 VS new format ","
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
$ say "!! VECTOR__CROSS_PRODUCT.COM:  "
$! say "=========================================================="                    
$
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then goto terminate
$  if (p3 .eqs. "") then goto terminate
$
$!  show symbol p1
$!  show symbol p2
$!  show symbol p3
$
$  @ez:vector__parse.com  'p1' __vcp_u 
$  @ez:vector__parse.com  'p2' __vcp_v 
$  if (__vcp_u__h .nes. "V") then goto terminate1
$  if (__vcp_v__h .nes. "V") then goto terminate1
$!
$  ! Compute cross product: W = U x V
$   ic_nolog
$   icalc ('__vcp_u__2'*'__vcp_v__3') - ('__vcp_u__3'*'__vcp_v__2')
$   __vcp_w__1 = icalc_out
$   ic_nolog
$   icalc ('__vcp_u__3'*'__vcp_v__1') - ('__vcp_u__1'*'__vcp_v__3')
$   __vcp_w__2 = icalc_out
$   ic_nolog
$   icalc ('__vcp_u__1'*'__vcp_v__2') - ('__vcp_u__2'*'__vcp_v__1')
$   __vcp_w__3 = icalc_out
$
$   @ez:vector__make.com  'p3' '__vcp_w__1' '__vcp_w__2' '__vcp_w__3'
$
$ !say "  "
$ !say "!! VECTOR__CROSS_PRODUCT.COM:	Completed "
$ !say "==========================================================" 
$ exit 
$!
$ terminate:
$   @ez:helper VECTOR__CROSS_PRODUCT
$   exit
$!
$ terminate1:
$   say "  "
$   say "!! VECTOR__CROSS_PRODUCT Error: invalid parameters"
$   sh sym p1
$   sh sym p2
$   sh sym p3
$   exit