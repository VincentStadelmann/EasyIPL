$!************************* EZ_IPL *****************************************    
$!       
$! VECTOR__MAKE.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2017.08.24
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Makes a vector 'p1' from coordinates 'ux uy uz'
$!
$! PARAMETERS:
$!  P1 : Vector name
$!  P2 : Coord x 
$!  P3 : Coord y 
$!  P4 : Coord z 
$!
$! USAGE:
$!  @ez:vector__make.com  vecname 'vx' 'vy' 'vz'   
$!
$! VERSION HISTORY:
$!  2018.10.22 Formatting of outputs coordinates _i -> __i
$!             Remove __inp
$!  2018.10.22 EZ Format
$!  2018.11.20 New attributes
$!  2018.11.21 Icalc_nolog
$!
$!***************************************************************************            
$!
$  @ez:vector__init.com 
$
$  j = 0
$  pj_loop:
$    j = j + 1
$    if (p'j' .eqs. "") then goto terminate
$    if (f$locate(",", p'j') .lt. f$length(p'j')) then goto incomplete
$    if (j .lt. 4) then goto pj_loop
$
$! Create vector symbol
$   'p1' :== 'p2','p3','p4'
$   sh sym 'p1'
$
$! Create vector attributes
$   'p1'__H == "V"   ! Header V means "Verified" ie vector has three coordinates
$   'p1'__1 == p2
$   'p1'__2 == p3
$   'p1'__3 == p4
$
$!  Norm
$!   ||u|| = sqrt(u_1^2+u_2^2+u_3^2)
$    ic_nolog
$    icalc  sqrt(('p2')^2 + ('p3')^2 + ('p4')^2)
$    'p1'__norm == icalc_out
$
$!  Norm square
$!   ||u||^2 = u_1^2+u_2^2+u_3^2
$    ic_nolog
$    icalc  ('p2')^2 + ('p3')^2 + ('p4')^2
$    'p1'__norm2 == icalc_out
$
$!  IPL output:
$   'p1'__ipl :== 'p2' 'p3' 'p4'
$
$ exit 
$
$ incomplete:
$   say "==========================================================" 
$  'p1'__H == "F"   ! Header F means "FALSE" ie vector is incomplete
$   say "!! VECTOR__MAKE Error - Coordinates incomplete  " 
$   show symbol p1
$   show symbol p2
$   show symbol p3
$   show symbol p4
$   say " " 
$   say "==========================================================" 
$   exit
$
$!
$ terminate:
$   @ez:helper VECTOR__MAKE
$ exit