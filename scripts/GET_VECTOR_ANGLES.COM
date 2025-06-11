$!**************************************************************************************************                        
$! GET_VECTOR_ANGLES.COM
$! 2017.07.11 V. Stadelmann 
$! 
$! USAGE:
$! Get the angles of a vector against X Y Z axes
$!  P1 : vector U (ux.uy.uz)
$!  P2 : angles symbol (default AnglesU)
$!
$! USAGE:
$!   @'scripts_dir'get_vector_angles.com	'ux.uy.uz' 'angles_symbol'
$!**************************************************************************************************                        
$!
$ say = "write sys$output"
$ say "  "
$ say "=========================================================="
$ say "!! GET_VECTOR_ANGLES.COM:  "
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
$  if (p2 .eqs. "") then p2 := AnglesU
$!
$  u_1 = f$element(0,".",p1)
$  u_2 = f$element(1,".",p1)
$  u_3 = f$element(2,".",p1)
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
$  say "  "
$  say "!! Compute angles: "
$  say "!!    alpha = acos( u.Ox / ||u||) = acos(u_1/normu)"
$  say "!!    beta  = acos( u.Oy / ||u||) = acos(u_2/normu)"
$  say "!!    gamma = acos( u.Oz / ||u||) = acos(u_3/normu)"
$   icalc  acos('u_1'/'normu')
$   AnglesU_1 = icalc_out
$   icalc  acos('u_2'/'normu')
$   AnglesU_2 = icalc_out
$   icalc  acos('u_3'/'normu')
$   AnglesU_3 = icalc_out
$   AnglesU := 'AnglesU_1'.'AnglesU_2'.'AnglesU_3'
$   sh sym AnglesU*
$!
$   'p2'_1 :== 'AnglesU_1'
$   'p2'_2 :== 'AnglesU_2'
$   'p2'_3 :== 'AnglesU_3'
$   'p2'   :== 'AnglesU'
$   sh sym 'p2'*
$!
$ say "  "
$ say "!! GET_VECTOR_ANGLES.COM:	Completed "
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
