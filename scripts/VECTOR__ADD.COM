$!************************* EZ_IPL *****************************************    
$!       
$! VECTOR__ADD.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2017.07.10
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Computes sum of two vectors
$!
$! PARAMETERS:
$!  P1 : vector U (u1,u2,u3)
$!  P2 : vector V (v1,v2,v3)
$!  P3 : Output vector name
$!
$! USAGE:
$!   @ez:vector__add.com  'in1_vec' 'in2_vec' out_vec
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
$ say "!! VECTOR__ADD.COM:  "
$! say "=========================================================="
$
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then goto terminate
$  if (p3 .eqs. "") then goto terminate
$
$  !show symbol p1
$  !show symbol p2
$  !show symbol p3
$
$  @ez:vector__parse.com  'p1' __va_u 
$  @ez:vector__parse.com  'p2' __va_v 
$  if (__va_u__h .nes. "V") then goto terminate1
$  if (__va_v__h .nes. "V") then goto terminate1
$
$! Compute sum: W = U + V"
$   ic_nolog
$   icalc '__va_v__1' + '__va_u__1'
$   __va_w__1 = icalc_out
$   ic_nolog
$   icalc '__va_v__2' + '__va_u__2'
$   __va_w__2 = icalc_out
$   ic_nolog
$   icalc '__va_v__3' + '__va_u__3'
$   __va_w__3 = icalc_out
$
$   @ez:vector__make.com  'p3' '__va_w__1' '__va_w__2' '__va_w__3'
$
$ !say "  "
$ !say "!! VECTOR__ADD.COM:	Completed "
$ !say "==========================================================" 
$ exit 
$
$ terminate:
$   @ez:helper VECTOR__ADD
$   exit
$
$ terminate1:
$   say "  "
$   say "!! VECTOR__ADD Error : invalid parameters "
$   sh sym p1
$   sh sym p2
$   sh sym p3
$   exit