$!************************* EZ_IPL *****************************************    
$!       
$! VECTOR__MULTIPLY.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2017.07.11
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Multiply a vector by a factor or vector (element by element multiplication)
$!
$! PARAMETERS:
$!  P1 : Vector u (u1,u2,u3)
$!  P2 : Factor (r) or Vector (v1,v2,v3) for multiplication
$!  P3 : Output vector name
$!
$! USAGE:
$!   @ez:vector__multiply.com	'u1,u2,u3' 'factor or vector' out_vec
$!
$! VERSION HISTORY:
$!  2017.08.24 Formatting of outputs coordinates _i -> __i
$!             Remove __inp
$!  2018.10.22 EZ Format
$!  2018.11.20 New attributes
$!  2018.11.21 Icalc_nolog
$!
$!***************************************************************************            
$
$  @ez:vector__init.com 
$
$  say " "
$! say "=========================================================="
$ say "!! VECTOR__MULTIPLY.COM:  "
$! say "=========================================================="
$
$  j = 0
$  pj_loop:
$    j = j + 1
$    !sh sym p'j'
$    if (p'j' .eqs. "") then goto terminate
$    if (j .lt. 3) then goto pj_loop
$!
$  @ez:vector__parse.com  'p1' __vm_u
$  if (__vm_u__h .nes. "V") then goto terminate1
$!
$  if (f$locate(",", p2) .lt. f$length(p2)) 
$    then 
$!     say "!! Multiply vector by vector: u*v = (u1*v1,u2*v2,u3*v3) "
$      @ez:vector__parse.com  'p2' __vm_v 
$      if (__vm_v__h .nes. "V") then goto terminate1
$      ic_nolog
$      icalc '__vm_v__1' * '__vm_u__1'
$      __vm_uxv__1 = icalc_out
$      ic_nolog
$      icalc '__vm_v__2' * '__vm_u__2'
$      __vm_uxv__2 = icalc_out
$      ic_nolog
$      icalc '__vm_v__3' * '__vm_u__3'
$      __vm_uxv__3 = icalc_out
$!
$    else
$!     say "!! Multiply vector by factor: u*r = r*u1,r*u2,r*u3 "
$     ic_nolog
$     icalc 'p2' * '__vm_u__1'
$     __vm_uxv__1 = icalc_out
$      ic_nolog
$     icalc 'p2' * '__vm_u__2'
$     __vm_uxv__2 = icalc_out
$      ic_nolog
$     icalc 'p2' * '__vm_u__3'
$     __vm_uxv__3 = icalc_out
$  endif
$
$   @ez:vector__make.com  'p3' '__vm_uxv__1' '__vm_uxv__2' '__vm_uxv__3'
$!
$! say "!! VECTOR__MULTIPLY.COM:	Completed "
$! say "==========================================================" 
$ exit 
$
$ terminate:
$   @ez:helper VECTOR__MULTIPLY
$   exit
$
$ terminate1:
$   say "  "
$   say "!! VECTOR__MULTIPLY Error : invalid parameters"
$   sh sym p1
$   sh sym p2
$   sh sym p3
$   exit