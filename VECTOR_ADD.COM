$!**************************************************************************************************                        
$! VECTOR__ADD.COM
$! 2017.07.10 V. Stadelmann 
$! 2017.07.11 VS output vector symbol
$! 2017.08.23 VS "," instead of ","
$! 
$! USAGE:
$! Subtracts two vectors
$!  P1 : vector U (ux,uy,uz)
$!  P2 : vector V (vx,vy,vz)
$!  P3 : new vector symbol 
$!
$! USAGE:
$!   @'coms'vector__add.com 'ux,uy,uz' 'vx,vy,vz' 'new_vector*'
$!
$!**************************************************************************************************                        
$!
$ say = "write sys$output"
$ say "  "
$ say "=========================================================="
$ say "!! VECTOR__ADD.COM:  "
$ say "=========================================================="
$!
$  if ("''coms'" .eqs. "") then coms = "ue:"
$  if (f$search("''coms'vector__parse.com") .eqs. "") then goto terminate0
$  if (f$search("''coms'vector__make.com") .eqs. "") then goto terminate0
$!
$  show symbol p1
$  show symbol p2
$  show symbol p3
$  if (p1 .eqs. "") then goto terminate1
$  if (p2 .eqs. "") then goto terminate1
$  if (p3 .eqs. "") then goto terminate1
$
$  @'coms'vector__parse.com  'p1' vec_u 
$  @'coms'vector__parse.com  'p2' vec_v 
$
$!
$  say "  "
$  say "!! Compute sum: Vec_UPV = U + V"
$   icalc 'vec_u_1' + 'vec_v_1'
$   vec_upv_1 = icalc_out
$   icalc 'vec_u_2' + 'vec_v_2'
$   vec_upv_2 = icalc_out
$   icalc 'vec_u_3' + 'vec_v_3'
$   vec_upv_3 = icalc_out
$
$   @'coms'vector__make.com  'p3' 'vec_upv_1' 'vec_upv_2' 'vec_upv_3'
$!
$ say "  "
$ say "!! VECTOR__ADD.COM:	Completed "
$ say "==========================================================" 
$ exit 
$!
$ terminate0:
$   say "  "
$   say "!! Error: vector__parse.com and vector__make.com required in ''coms' "
$   exit
$!
$ terminate1:
$   say "  "
$   say "!! Error: missing parameter"
$   say "!!  P1 : vector U (ux,uy,uz) "
$   say "!!  P2 : vector V (vx,vy,vz) "
$   say "!!  P3 : new vector name "
$   exit
