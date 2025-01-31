$!**************************************************************************************************                        
$! GET_VECTOR_NORM.COM
$! 2017.07.11 V. Stadelmann 
$! 
$! USAGE:
$! Get the norm of a vector
$!  P1 : vector U (ux.uy.uz)
$!  P2 : Norm symbol (default NORMU)
$!
$! USAGE:
$!   @'scripts_dir'get_vector_norm.com	'ux.uy.uz' 'norm_symbol'
$!**************************************************************************************************                        
$!
$ say = "write sys$output"
$ say "  "
$ say "=========================================================="
$ say "!! GET_VECTOR_NORM.COM:  "
$ say "=========================================================="
$!
$! Test inputs
$  j = 0
$  pj_loop:
$    j = j + 1
$    show symbol p'j'
$    if (p'j' .eqs. "") then goto terminate1
$    if (f$locate(".", p'j') .eq. f$length(p'j')) then goto terminate2
$    if (j .lt. 1) then goto pj_loop
$!
$  if (p2 .eqs. "") then p2 := NormU
$!
$  u_1 = F$ELEMENT(0,".",P1)
$  u_2 = F$ELEMENT(1,".",P1)
$  u_3 = F$ELEMENT(2,".",P1)
$!
$!  say "  "
$!  say "!! Input coordinates:"
$!  sh sym u_*
$!
$  j = 0
$  elj_loop:
$    j = j + 1
$    if (u_'j' .eqs. ".") then goto terminate2
$    if (j .lt. 3) then goto elj_loop
$!
$  say "  "
$  say "!! Compute norm: normu = sqrt(u_1^2+u_2^2+u_3^2)"
$   icalc  sqrt(('u_1')^2 + ('u_2')^2 + ('u_3')^2)
$   normu = icalc_out
$   icalc floor('normu')
$   normu_int = icalc_out
$   sh sym normu*
$!
$   'p2' :== 'normu'
$   'p2'_int :== 'normu_int'
$   sh sym 'p2'*
$!
$ say "  "
$ say "!! GET_VECTOR_NORM.COM:	Completed "
$ say "==========================================================" 
$ exit 
$!
$!
$ terminate1:
$   say "  "
$   say "!! Error: missing coordinates"
$   say "!!  P1 : vector U (ux.uy.uz) "
$   exit
$ terminate2:
$   say "  "
$   say "!! Error: incorect coordinates"
$   say "!!  P1 : vector U (ux.uy.uz) "
$   exit
