$!**************************************************************************************************                        
$! COMPUTE_CROSS_PRODUCT.COM
$! 2017.07.10 V. Stadelmann 
$! 2017.07.11 VS output vector symbol
$! 
$! USAGE:
$! Computes cross product of two vectors
$!  P1 : vector U (ux.uy.uz)
$!  P2 : vector V (vx,vy,vz)
$!  P3 : new vector symbol (Default  UXV)
$!
$! USAGE:
$!   @'scripts_dir'compute_cross_product.com	'ux.uy.uz' 'vx.vy.vz'  'new_vector'
$!   (opt. newvector := 'uxv')
$!**************************************************************************************************                        
$!
$ say = "write sys$output"
$ say "  "
$ say "=========================================================="
$ say "!! COMPUTE_CROSS_PRODUCT.COM:  "
$ say "=========================================================="
$!
$! Test inputs
$  j = 0
$  pj_loop:
$    j = j + 1
$    show symbol p'j'
$    if (p'j' .eqs. "") then goto terminate1
$    if (f$locate(".", p'j') .eq. f$length(p'j')) then goto terminate2
$    if (j .lt. 2) then goto pj_loop
$!
$  sh sym p3
$  if (p3 .eqs. "") then p3 := uxv
$!
$  u_1 = f$element(0,".",p1)
$  u_2 = f$element(1,".",p1)
$  u_3 = f$element(2,".",p1)
$  v_1 = f$element(0,".",p2)
$  v_2 = f$element(1,".",p2)
$  v_3 = f$element(2,".",p2)
$!
$!  say "  "
$!  say "!! Input coordinates:"
$!  sh sym u_*
$!  sh sym v_*
$!
$  j = 0
$  elj_loop:
$    j = j + 1
$    if (u_'j' .eqs. ".") then goto terminate2
$    if (v_'j' .eqs. ".") then goto terminate2
$    if (j .lt. 3) then goto elj_loop
$!
$  say "  "
$  say "!! Compute cross product: UXV = U x V"
$   icalc ('u_2'*'v_3') - ('u_3'*'v_2')
$   uxv_1 = icalc_out
$   icalc ('u_1'*'v_3') - ('u_3'*'v_1')
$   uxv_2 = icalc_out
$   icalc ('u_1'*'v_2') - ('u_2'*'v_1')
$   uxv_3 = icalc_out
$   uxv := 'uxv_1'.'uxv_2'.'uxv_3'
$   sh sym uxv
$   'p3' :== 'uxv'
$   sh sym 'p3'
$!
$ say "  "
$ say "!! COMPUTE_CROSS_PRODUCT.COM:	Completed "
$ say "==========================================================" 
$ exit 
$!
$!
$ terminate1:
$   say "  "
$   say "!! Error: missing coordinates"
$   say "!!  P1 : vector U (ux.uy.uz) "
$   say "!!  P2 : vector V (vx,vy,vz) "
$   exit
$ terminate2:
$   say "  "
$   say "!! Error: incorect coordinates"
$   say "!!  P1 : vector U (ux.uy.uz) "
$   say "!!  P2 : vector V (vx,vy,vz) "
$   exit
