$!**************************************************************************************************                        
$! MATRIX__PARSE.COM
$! 2017.08.23 V. Stadelmann 
$! 
$! USAGE:
$!  parses  coordinate from 'm11,m12,m13;m21,m22,m23;m31,m32,m33'
$!  P1 : vector (ux,uy,uz)
$!  P2 : vector name 
$!
$! USAGE:
$!   @'coms'matrix__parse.com  'm11,m12,m13;m21,m22,m23;m31,m32,m33' 'matname' 
$!
$!**************************************************************************************************                        
$!
$ say = "write sys$output"
$ say "  "
$! say "=========================================================="
$ say "!! MATRIX__PARSE.COM:  "
$! say "=========================================================="
$!
$  if ("''coms'" .eqs. "") then coms = "ue:"
$  if (f$search("''coms'vector__parse.com") .eqs. "") then goto terminate0
$  if (f$search("''coms'vector__make.com") .eqs. "") then goto terminate0
$  if (f$search("''coms'matrix__make.com") .eqs. "") then goto terminate0
$!
$! Test inputs
$  j = 0
$  pj_loop:
$    j = j + 1
$!    show symbol p'j'
$    if (p'j' .eqs. "") then goto terminate1
$    if (f$locate(",", p'j') .eq. f$length(p'j')) then goto terminate2
$    if (f$locate(";", p'j') .eq. f$length(p'j')) then goto terminate2
$    if (j .lt. 1) then goto pj_loop
$!
$  if (p2 .eqs. "") then p2 := mat_m
$!
$  mat_m_row_1 = f$element(0,";",p1)
$  mat_m_row_2 = f$element(1,";",p1)
$  mat_m_row_3 = f$element(2,";",p1)
$!
$! Test coordinates
$  j = 0
$  elj_loop:
$    j = j + 1
$    if (mat_m_row_'j' .eqs. ";") then goto terminate2
$    if (f$locate(",", mat_m_row_'j') .eq. f$length(mat_m_row_'j')) then goto terminate2
$    if (j .lt. 3) then goto elj_loop
$!
$! Matrix format
$   @'coms'matrix__make.com  'p2' 'mat_m_row_1' 'mat_m_row_2' 'mat_m_row_3' ROWS
$!
$! say "!! MATRIX__PARSE.COM:	Completed "
$! say "==========================================================" 
$ exit 
$!
$!
$ terminate0:
$   say "  "
$   say "!! Error: vector__parse.com and vector__make.com required in ''coms' "
$   exit
$
$ terminate1:
$   say "  "
$   say "!! Error: missing coordinates"
$   say "!!  P1 : vector U (ux,uy,uz) "
$   exit
$ terminate2:
$   say "  "
$   say "!! Error: incorect coordinates"
$   say "!!  P1 : vector U (ux,uy,uz) "
$   exit
