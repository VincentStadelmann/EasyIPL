$!************************* EZ_IPL *****************************************    
$!       
$! VECTOR__DIVIDE.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.01.16
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Division of vector by a vector or a factor
$!
$! PARAMETERS:
$!  P1 : Input vector U (u1,u2,u3)
$!  P2 : Input vector V (v1,v2,v3) or factor (v)
$!  P3 : Output vector name
$!
$! USAGE:
$!   @ez:vector__divide.com  'in1_vec' 'in2_vec' out_vec
$!
$! VERSION HISTORY:
$!  2018.10.22 EZ Format
$!  2018.11.21 New attributes
$!  2019.02.28 Test for division by 0
$!
$!***************************************************************************                    
$
$  @ez:vector__init.com 
$
$ say "  "
$
$! say "  "
$! say "=========================================================="
$ say "!! VECTOR__DIVIDE.COM:  "
$! say "=========================================================="
$!
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then goto terminate
$  if (p3 .eqs. "") then goto terminate
$
$!
$  @ez:vector__parse.com  'p1' __vd_u 
$  if (__vd_u__h .nes. "V") then goto terminate1
$
$  if (f$locate(",", p2) .lt. f$length(p2)) 
$    then 
$!     say "!! Dividing vector by vector: w = u/v = (u_1/v_1,u_2/v_2,u_3/v_3) "
$      @ez:vector__parse.com  'p2' __vd_v 
$      if('__vd_v__1' .eq. 0 .or. '__vd_v__2' .eq. 0 .or. '__vd_v__3' .eq. 0) then goto terminate2
$
$      ic_nolog
$      icalc '__vd_u__1' / '__vd_v__1' 
$      __vd_w__1 = icalc_out
$      ic_nolog
$      icalc '__vd_u__2' / '__vd_v__2' 
$      __vd_w__2 = icalc_out
$      ic_nolog
$      icalc '__vd_u__3' / '__vd_v__3' 
$      __vd_w__3 = icalc_out
$!
$    else
$!     say "!! Divide vector by numeric : w = 1/v * u "
$      if('p2' .eq. 0) then goto terminate2
$
$      ic_nolog
$     icalc  '__vd_u__1'/'p2'
$     __vd_w__1 = icalc_out
$      ic_nolog
$     icalc '__vd_u__2'/'p2'
$     __vd_w__2 = icalc_out
$      ic_nolog
$     icalc '__vd_u__3'/'p2'
$     __vd_w__3 = icalc_out
$ endif
$!
$   @ez:vector__make.com  'p3' '__vd_w__1' '__vd_w__2' '__vd_w__3'
$!
$! say "!! VECTOR__DIVIDE.COM:	Completed "
$! say "==========================================================" 
$ exit 
$
$ terminate:
$   @ez:helper VECTOR__DIVIDE
$   exit
$
$ terminate1:
$   say "  "
$   say "!! VECTOR__DIVIDE Error: invalid parameters"
$   sh sym p1
$   sh sym p2
$   sh sym p3
$   exit
$
$ terminate2:
$   say "  "
$   say "!! VECTOR__DIVIDE Error: division by 0"
$   sh sym p1
$   sh sym p2
$   sh sym p3
$   exit