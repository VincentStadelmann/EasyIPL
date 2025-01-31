$!**************************************************************************************************                        
$! NORM_VECTOR.COM
$! 2017.07.11 V. Stadelmann 
$! 
$! USAGE:
$! Adjust vector norm to given value (1*)
$!  P1 : vector U (ux.uy.uz)
$!  P2 : new norm (r)
$!  P3 : new vector (Default unr) 
$!
$! USAGE:
$!   @'scripts_dir'norm_vector.com	'ux.uy.uz' 'norm' 'new_vec*'
$!   new_vec := unr
$!**************************************************************************************************                        
$!
$ say = "write sys$output"
$ say "  "
$ say "=========================================================="
$ say "!! NORM_VECTOR.COM:  "
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
$  show symbol p2
$  if (p2 .eqs. "") then p2 = 1
$!  if (p2 .lt. 0) then goto terminate3
$!
$  show symbol p3
$  if (p3 .eqs. "") then p3 := unr
$!
$  u_1 = f$element(0,".",p1)
$  u_2 = f$element(1,".",p1)
$  u_3 = f$element(2,".",p1)
$  sh sym u_*
$!
$! Test coordinates
$  j = 0
$  elj_loop:
$    j = j + 1
$    if (u_'j' .eqs. ".") then goto terminate2
$    if (j .lt. 3) then goto elj_loop
$!
$  say "  "
$  say "!! Compute norm: nu = sqrt(u_1^2+u_2^2+u_3^2)"
$   icalc  sqrt(('u_1')^2 + ('u_2')^2 + ('u_3')^2)
$   nu = icalc_out
$!
$  say "!! Norming factor: nf = newnorm/nu"
$   icalc  'p2'/'nu'
$   nf = icalc_out
$!
$  say "!! Multiply vector: unr = floor(nf * u) "
$   icalc floor('nf' * 'u_1')
$   unr_1 = icalc_out
$   icalc floor('nf' * 'u_2')
$   unr_2 = icalc_out
$   icalc floor('nf' * 'u_3')
$   unr_3 = icalc_out
$!
$   unr := 'unr_1'.'unr_2'.'unr_3'
$   sh sym unr
$   'p3' :== 'unr'
$   sh sym 'p3'
$!
$ say "  "
$ say "!! NORM_VECTOR.COM:	Completed "
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
$ terminate3:
$   say "  "
$   say "!! Error: negative norm not possible"
$   say "!!  P2 : new norm (r>=0)"  
$   exit
