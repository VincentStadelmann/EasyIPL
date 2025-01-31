$!************************* EZ_IPL *****************************************    
$!       
$! VECTOR__GET_NORM.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2017.07.10
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Get the norm of a vector
$!
$! PARAMETERS:
$!  P1 : vector U (ux.uy.uz)
$!  P2 : Norm symbol 
$!
$! USAGE:
$!   @ez:VECTOR__GET_NORM  'in_vec' out_norm
$!
$! VERSION HISTORY:
$! 2017.07.11 V. Stadelmann 
$! 2017.08.24 new format "," 
$! 2019.02.28 EZ  
$!
$!***************************************************************************                    
$
$  @ez:vector__init.com 
$
$ say "  "
$! say "=========================================================="
$ say "!! VECTOR__GET_NORM.COM:  "
$! say "=========================================================="                    
$
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then goto terminate
$
$!  show symbol p1
$!  show symbol p2
$
$  @ez:vector__parse.com  'p1' __vgn_u 
$  if (__vgn_u__h .nes. "V") then goto terminate1
$
$! Compute norm: ||u|| = sqrt(u_1^2+u_2^2+u_3^2)"
$   ic_nolog
$   icalc  sqrt(('__vgn_u__1')^2 + ('__vgn_u__2')^2 + ('__vgn_u__3')^2)
$   normu = icalc_out
$   'p2' == normu
$
$   ic_nolog
$   icalc floor('normu')
$   'p2'_int == icalc_out
$   
$   sh sym 'p2'*
$!
$ say "  "
$ say "!! VECTOR__GET_NORM.COM:	Completed "
$ say "==========================================================" 
$ exit 
$
$ terminate:
$   @ez:helper VECTOR__GET_NORM
$   exit
$
$ terminate1:
$   say "  "
$   say "!! VECTOR__GET_NORM Error: invalid parameters"
$   sh sym p1
$   sh sym p2
$   sh sym p3
$   exit