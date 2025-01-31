$!**************************************************************************************************                        
$! VECTOR__COPY.COM
$! 2017.07.11 V. Stadelmann 
$! 2017.08.24 VS New format 
$! 
$! DESCRIPTION:
$!  Copies a vector to a new one
$!  P1 : vector U (ux.uy.uz)
$!  P2 : new vector  
$!
$! USAGE:
$!   @'coms'vector__copy.com	'ux.uy.uz' 'new_vec'
$!
$!**************************************************************************************************                        
$!
$ say = "write sys$output"
$ say "  "
$! say "=========================================================="
$ say "!! VECTOR__COPY.COM:  "
$! say "=========================================================="
$!
$! if ("''coms'" .eqs. "") then coms = "ue:"
$ if (f$search("ez:vector__parse.com") .eqs. "") then goto terminate0
$ if (f$search("ez:vector__make.com") .eqs. "") then goto terminate0
$!
$ show symbol p1
$ show symbol p2
$!
$  @'coms'vector__parse.com  'p1' vec_u 
$  if (vec_u .eqs. "") then goto terminate1
$!
$  if (p2 .eqs. "") then p2 := vec_copy
$!
$  if (f$locate(",", p1) .eq. f$length(p1)) then goto terminate2
$
$   @'coms'vector__parse.com 'p1' vec_r 
$   @'coms'vector__make.com  'p2' 'vec_r_1' 'vec_r_2' 'vec_r_3'
$!
$! say "!! VECTOR__COPY.COM:	Completed "
$! say "==========================================================" 
$ exit 
$!
$ terminate0:
$   say "  "
$   say "!! Error: vector__parse.com and vector__make.com required in ez: "
$   exit
$!
$ terminate1:
$   say "  "
$   say "!! Error: missing coordinates"
$   say "!!  P1 : vector U (ux.uy.uz) "
$   exit
$
$ terminate2:
$   say "  "
$   say "!! Error: incorect coordinates"
$   say "!!  P1 : vector U (ux.uy.uz) "
$   exit
