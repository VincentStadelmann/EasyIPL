$!**************************************************************************************************                        
$! COMPUTE_VECTOR.COM
$! 2017.07.10 V. Stadelmann 
$! 
$! USAGE:
$! Computes vector between two points
$!  P1 : point A (ax.ay.az)
$!  P2 : point B (bx,by,bz)
$!
$! USAGE:
$!   @'scripts_dir'compute_vector.com	'ax.ay.az' 'bx,by,bz' 
$!**************************************************************************************************                        
$!
$ say = "write sys$output"
$ say "  "
$ say "=========================================================="
$ say "!! COMPUTE_VECTOR.COM:  "
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
$  say "  "
$  say "!! Input coordinates:"
$   a_1 = F$ELEMENT(0,".",P1)
$   a_2 = F$ELEMENT(1,".",P1)
$   a_3 = F$ELEMENT(2,".",P1)
$   b_1 = F$ELEMENT(0,".",P2)
$   b_2 = F$ELEMENT(1,".",P2)
$   b_3 = F$ELEMENT(2,".",P2)
$   sh sym a_*
$   sh sym b_*
$!
$  j = 0
$  elj_loop:
$    j = j + 1
$    if (a_'j' .eqs. ".") then goto terminate2
$    if (b_'j' .eqs. ".") then goto terminate2
$    if (j .lt. 3) then goto elj_loop
$
$  say "  "
$  say "!! Vector ab = b-a:"
$   icalc 'b_1' - 'a_1'
$   ab_1 == icalc_out
$   icalc 'b_2' - 'a_2'
$   ab_2 == icalc_out
$   icalc 'b_3' - 'a_3'
$   ab_3 == icalc_out
$   ab :== 'ab_1'.'ab_2'.'ab_3'
$   sh sym ab
$!
$ say "  "
$ say "!! COMPUTE_VECTOR.COM:	Completed "
$ say "==========================================================" 
$ exit 
$!
$ terminate1:
$   say "!! Error: missing coordinates"
$   say "!! P1 : vector U (ux.uy.uz) "
$   say "!! P2 : vector V (vx,vy,vz) "
$   exit
$ terminate2:
$   say "!! Error: incorect coordinates"
$   say "!! P1 : vector U (ux.uy.uz) "
$   say "!! P2 : vector V (vx,vy,vz) "
$   exit
