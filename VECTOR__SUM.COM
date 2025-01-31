$!**************************************************************************************************                        
$! VECTOR__SUM.COM
$! 2017.07.10 V. Stadelmann 
$! 2017.07.11 VS output vector symbol
$! 2017.08.24 VS new format ","
$! 
$! DESCRIPTION:
$!  Sums two vectors
$!  P1 : vector U (ux.uy.uz)
$!  P2 : vector V (vx,vy,vz)
$!  P3 : new vector symbol (Default Vec_UPV)
$!
$! USAGE:
$!   @'scripts_dir'vector__sum.com	'ux.uy.uz' 'vx.vy.vz' 'new_vector*'
$!   
$!**************************************************************************************************                        
$!
$ say = "write sys$output"
$ say "  "
$ say "=========================================================="
$ say "!! VECTOR__SUM.COM:  "
$ say "=========================================================="
$!
$  @ez:vector__init.com 
$!
$  show symbol p1
$  show symbol p2
$  show symbol p3
$
$  @'coms'vector__parse.com  'p1' vec_u 
$  @'coms'vector__parse.com  'p2' vec_v 
$  if (vec_u .eqs. "") then goto terminate1
$  if (vec_v .eqs. "") then goto terminate1
$
$  if (p3 .eqs. "") then p3 := Vec_UPV
$
$  say "  "
$  say "!! Compute sum: Vec_UPV = U + V"
$   icalc 'vec_v_1' + 'vec_u_1'
$   vec_upv_1 = icalc_out
$   icalc 'vec_v_2' + 'vec_u_2'
$   vec_upv_2 = icalc_out
$   icalc 'vec_v_3' + 'vec_u_3'
$   vec_upv_3 = icalc_out
$
$   @'coms'vector__make.com  'p3' 'vec_upv_1' 'vec_upv_2' 'vec_upv_3'
$!
$ say "  "
$ say "!! VECTOR__SUM.COM:	Completed "
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
$   say "!! Error: missing coordinates"
$   say "!!  P1 : vector U (ux.uy.uz) "
$   say "!!  P2 : vector V (vx,vy,vz) "
$   exit
