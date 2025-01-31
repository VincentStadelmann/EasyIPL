$!************************* EZ_IPL *****************************************    
$!       
$! VECTOR__ANGLES.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2017.08.24
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Get the angles of a vector against X Y Z axes
$!
$! PARAMETERS:
$!  P1 : vector U (u1,u2,u3)
$!  P2 : Angles vector name
$!
$! USAGE:
$!   @ez:vector__angles.com	'ux.uy.uz' 'vec_angles'
$!
$! VERSION HISTORY:
$!  2017.08.24 New format ","
$!  2018.10.22 EZ Format
$!  2018.11.20 New attributes
$!  2018.11.21 Icalc_nolog
$!
$!***************************************************************************                    
$
$  @ez:vector__init.com 
$!**************************************************************************************************                        
$! VECTOR__ANGLES.COM
$! 2017.08.24 V. Stadelmann 
$! 
$! DESCRIPTION:
$!  Get the angles of a vector against X Y Z axes
$!  P1 : vector U (ux.uy.uz)
$!  P2 : angles vector 
$!
$! USAGE:
$!   @ez:vector__angles.com	'ux.uy.uz' 'vec_angles*'
$!**************************************************************************************************                        
$!
$ say = "write sys$output"
$ say "  "
$! say "=========================================================="
$ say "!! VECTOR__ANGLES.COM:  "
$! say "=========================================================="
$!
$  @ez:vector__init.com 
$!
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then goto terminate
$!
$  @ez:vector__parse.com  'p1' __va_u 
$  if (__va_u__h .nes. "V") then goto terminate1
$  
$  ! Compute angles: "
$  !    alpha = acos(u_1/||u||)
$  !    beta  = acos(u_2/||u||)
$  !    gamma = acos(u_3/||u||)
$   ic_nolog
$   icalc  acos('__va_u__1'/'__va_u__norm')
$   alpha = icalc_out
$   ic_nolog
$   icalc  acos('__va_u__2'/'__va_u__norm')
$   beta = icalc_out
$   ic_nolog
$   icalc  acos('__va_u__3'/'__va_u__norm')
$   gamma = icalc_out
$
$   @ez:vector__make.com  'p2' 'alpha' 'beta' 'gamma'
$!
$! say "!! VECTOR__ANGLES.COM:	Completed "
$! say "==========================================================" 
$ exit 
$!
$
$ terminate:
$   @ez:helper VECTOR__ANGLES
$   exit
$
$ terminate1:
$   say "  "
$   say "!! VECTOR__ANGLES Error: invalid parameters"
$   sh sym p1
$   sh sym p2
$   sh sym p3
$   exit