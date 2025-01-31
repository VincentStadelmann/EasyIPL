$!**************************************************************************************************                        
$! SUBTRACT_VECTORS.COM
$! 2017.07.10 V. Stadelmann 
$! 2017.07.11 VS output vector symbol
$! 
$! USAGE:
$! Sums two vectors
$!  P1 : vector U (ux.uy.uz)
$!  P2 : vector V (vx,vy,vz)
$!  P3 : new vector symbol (Default UMV)
$!
$! USAGE:
$!   @'scripts_dir'subtract_vectors.com	'ux.uy.uz' 'vx.vy.vz' 'new_vector*'
$!   (Opt. newvector := 'umv')
$!**************************************************************************************************                        
$!
$ say = "write sys$output"
$ say "  "
$ say "=========================================================="
$ say "!! SUBTRACT_VECTORS.COM:  "
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
$  if (p3 .eqs. "") then p3 := umv
$!
$  u_1 = F$ELEMENT(0,".",P1)
$  u_2 = F$ELEMENT(1,".",P1)
$  u_3 = F$ELEMENT(2,".",P1)
$  v_1 = F$ELEMENT(0,".",P2)
$  v_2 = F$ELEMENT(1,".",P2)
$  v_3 = F$ELEMENT(2,".",P2)
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
$  say "!! Compute subtraction: UMV = U - V"
$   icalc  'u_1' - 'v_1'
$   umv_1 = icalc_out
$   icalc 'u_2' - 'v_2'
$   umv_2 = icalc_out
$   icalc 'u_3' - 'v_3'
$   umv_3 = icalc_out
$   umv := 'umv_1'.'umv_2'.'umv_3'
$   sh sym umv
$   'p3' :== 'umv'
$   sh sym 'p3'
$!
$ say "  "
$ say "!! SUBTRACT_VECTORS.COM:	Completed "
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
