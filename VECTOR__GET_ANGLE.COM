$!************************* EZ_IPL *****************************************    
$!       
$! VECTOR__GET_ANGLE.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2017.08.24
$!  Copyright (c) 2019 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Get the angle between two vectors
$!
$! PARAMETERS:
$!  P1 : vector U (ux,uy,uz)
$!  P1 : vector V (vx,vy,vz)
$!  P2 : Output angles vector
$!
$! USAGE:
$!   @ez:vector__get_angle.com	'vec_u' 'vec_v' alpha
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
$! say "=========================================================="
$ say "!! VECTOR__GET_ANGLE.COM:  "
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
$  @ez:vector__parse.com  'p1' __ga_u 
$  @ez:vector__parse.com  'p2' __ga_v 
$  if (__ga_u__h .nes. "V") then goto terminate1
$  if (__ga_v__h .nes. "V") then goto terminate1
$
$  !Compute norms and dot product
$  ! Compute angle: "
$  ! alpha = acos( u1.u2 / ||u1||*||u2|| )
$
$   @ez:vector__dot_product.com	'__ga_u' '__ga_v' u_dot_v
$   icalc  acos('u_dot_v'/('__ga_u__norm' * '__ga_v__norm') )
$ 
$   'p3' == icalc_out
$   'p3'_rad == icalc_out
$   icalc 'icalc_out' * 57.295779513 ! 1 rad = 180/pi degree
$   'p3'_deg == icalc_out
$   sh sym 'p3'*
$
$! say "!! VECTOR__GET_ANGLE.COM:	Completed "
$! say "==========================================================" 
$ exit 
$
$ terminate:
$   @ez:helper VECTOR__GET_ANGLE
$   exit
$
$ terminate1:
$   say "  "
$   say "!! VECTOR__GET_ANGLE Error: invalid parameters"
$   sh sym p1
$   sh sym p2
$   sh sym p3
$   exit