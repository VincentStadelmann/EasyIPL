$!************************* EZ_IPL *****************************************    
$!       
$! VECTOR__NORM.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2017.07.10
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Adjust vector norm to specified value 
$!
$! PARAMETERS:
$!  P1 : vector U (ux,uy,uz)
$!  P2 : new norm 
$!  P3 : new vector name
$!
$! USAGE:
$!   @'coms'vector__norm.com	'ux,uy,uz' 'norm' new_vec
$!
$! VERSION HISTORY:
$!  2017.07.11 V. Stadelmann 
$!  2017.08.23 "," instead of "." 
$!  2019.02.26 Icalc_nolog
$!
$!***************************************************************************                    
$
$  @ez:vector__init.com 
$
$ say "  "
$! say "=========================================================="
$ say "!! VECTOR__NORM.COM:  "
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
$  @ez:vector__parse.com  'p1' __vn_u 
$  if (__vn_u__h .nes. "V") then goto terminate1
$
$! Norming factor: nf = newnorm/normu"
$   ic_nolog
$   icalc  'p2'/'__vn_u__norm'
$   nf = icalc_out
$
$  @ez:vector__multiply.com	'p1' 'nf' 'p3'
$
$! say "  "
$! say "!! VECTOR__NORM.COM:	Completed "
$! say "==========================================================" 
$ exit 
$
$ terminate:
$   @ez:helper VECTOR__NORM
$   exit
$
$ terminate1:
$   say "  "
$   say "!! VECTOR__NORM Error: invalid parameters"
$   sh sym p1
$   sh sym p2
$   sh sym p3
$   exit