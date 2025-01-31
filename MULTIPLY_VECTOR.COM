$!**************************************************************************************************                        
$! MULTIPLY_VECTOR.COM
$! 2017.07.11 V. Stadelmann 
$! 
$! USAGE:
$! Adjust vector norm to given value (1*)
$!  P1 : vector U (ux.uy.uz)
$!  P2 : factor (r)
$!  P3 : new vector (Default umr) 
$!
$! USAGE:
$!   @'scripts_dir'multiply_vector.com	'ux.uy.uz' 'factor' 'new_vec*'
$!   new_vec := umr
$!**************************************************************************************************                        
$!
$ say = "write sys$output"
$ say "  "
$ say "=========================================================="
$ say "!! MULTIPLY_VECTOR.COM:  "
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
$  say "!! Multiply vector: unr = f * u "
$   icalc 'p2' * 'u_1'
$   unr_1 = icalc_out
$   icalc 'p2' * 'u_2'
$   unr_2 = icalc_out
$   icalc 'p2' * 'u_3'
$   unr_3 = icalc_out
$!
$   unr := 'unr_1'.'unr_2'.'unr_3'
$   sh sym unr
$   'p3' :== 'unr'
$!
$  say "!! Multiply vector: unr = floor(f * u) "
$   icalc floor('p2' * 'u_1')
$   unr_1 = icalc_out
$   icalc floor('p2' * 'u_2')
$   unr_2 = icalc_out
$   icalc floor('p2' * 'u_3')
$   unr_3 = icalc_out
$!
$   unr := 'unr_1'.'unr_2'.'unr_3'
$   sh sym unr
$   'p3'_vx :== 'unr'
$   sh sym 'p3'*
$!
$ say "  "
$ say "!! MULTIPLY_VECTOR.COM:	Completed "
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
