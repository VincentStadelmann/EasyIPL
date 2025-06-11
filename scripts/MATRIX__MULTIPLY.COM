$!**************************************************************************************************                        
$! MATRIX__MULTIPLY.COM
$! 2017.08.28 V. Stadelmann 
$! 
$! USAGE:
$!  Multiply a matrix 'p1' by 'p2' (vector or matrix) into 'p3'
$!  P1 : matrix m
$!  P2 : vector u or matrix n
$!  P3 : mult_result  
$!
$! USAGE:
$!   @'coms'matrix__multiply.com  'm' 'u' 'mxv'
$!
$!**************************************************************************************************                        
$!
$ say = "write sys$output"
$ say "  "
$ say "=========================================================="
$ say "!! MATRIX__MULTIPLY.COM:  "
$ say "=========================================================="
$!
$  if ("''coms'" .eqs. "") then coms = "ue:"
$  if (f$search("''coms'vector__parse.com") .eqs. "") then goto terminate0
$  if (f$search("''coms'vector__make.com") .eqs. "") then goto terminate0
$  if (f$search("''coms'vector__dot_product.com") .eqs. "") then goto terminate0
$  if (f$search("''coms'matrix__make.com") .eqs. "") then goto terminate0
$
$  j = 0
$  pj_loop:
$    j = j + 1
$    if (p'j' .eqs. "") then goto terminate1
$    if (f$locate(",", p'j') .eq. f$length(p'j')) then goto terminate2
$    if (j .lt. 2) then goto pj_loop
$!
$  if (f$locate(";", p1) .eq. f$length(p1)) then goto terminate2
$  if (f$locate(";", p2) .lt. f$length(p2)) then goto matrix_x_matrix
$
$  matrix_x_vector:
$    if (p3 .eqs. "") then p3 := vec_mxu
$    @'coms'vector__parse.com  'p2' mm__vec_u 
$    @'coms'matrix__parse.com  'p1' mm__mat_m 
$    @'coms'vector__dot_product.com	'mm__mat_m_row_1' 'mm__vec_u' mm__vec_mxv_1
$    @'coms'vector__dot_product.com	'mm__mat_m_row_2' 'mm__vec_u' mm__vec_mxv_2
$    @'coms'vector__dot_product.com	'mm__mat_m_row_3' 'mm__vec_u' mm__vec_mxv_3
$    @'coms'vector__make.com        'p3' 'mm__vec_mxv_1' 'mm__vec_mxv_2' 'mm__vec_mxv_3'
$    goto complete
$!
$  matrix_x_matrix:
$   say "!! matrix_x_matrix not implemented yet"
$!
$   sh sym 'p3'
$
$ complete:
$ say "!! MATRIX__MULTIPLY.COM:	Completed "
$ say "==========================================================" 
$ exit 
$!
$ terminate0:
$   say "  "
$   say "!! Error: vector__parse.com and vector__make.com required in ''coms' "
$   exit
$
$ terminate1:
$   say "  "
$   say "Multiply a matrix 'p1' by 'p2' (vector or matrix) into 'p3'"
$   say "P1 : matrix m"
$   say "P2 : vector u or matrix n"
$   say "P3 : mult_result  "
$   exit
$ terminate2:
$   say "  "
$   say "!! Error: incorrect parameters"
$    say "P1 : matrix name"
$    say "P2 : vector u "
$    say "P3 : vector v  "
$    say "P4 : vector w  "
$    say "P5 : direction (ROWS*, COLS) "
$   exit
