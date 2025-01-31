$!**************************************************************************************************                        
$! MATRIX__MAKE.COM
$! 2017.08.25 V. Stadelmann 
$! 
$! USAGE:
$!  Makes a matrix 'p1' from vector coordinates u v w
$!  P1 : matrix name
$!  P2 : vector u 
$!  P3 : vector v  
$!  P4 : vector w  
$!  P5 : direction (ROWS*, COLS)
$!
$! USAGE:
$!   @'coms'matrix__make.com  'matname' 'u' 'v' 'w' 'dir'
$!
$!**************************************************************************************************                        
$!
$ say = "write sys$output"
$ say "  "
$! say "=========================================================="
$ say "!! MATRIX__MAKE.COM:  "
$! say "=========================================================="
$!
$  if ("''coms'" .eqs. "") then coms = "ue:"
$  if (f$search("''coms'vector__parse.com") .eqs. "") then goto terminate0
$  if (f$search("''coms'vector__make.com") .eqs. "") then goto terminate0
$
$  if (p1 .eqs. "") then goto terminate1
$
$  j = 1
$  pj_loop:
$    j = j + 1
$    if (p'j' .eqs. "") then goto terminate1
$    if (f$locate(",", p'j') .eq. f$length(p'j')) then goto terminate2
$    if (j .lt. 4) then goto pj_loop
$!
$  if (p5 .eqs. "") then p5 := ROWS
$  if (p5 .nes. "ROWS" .and. p5 .nes. "COLS") then goto terminate2
$!
$! Format matrix
$   if (p5 .eqs. "ROWS") 
$     then 
$       'p1' :== 'p2';'p3';'p4'
$!
$!      Parse elements
$         @'coms'vector__parse.com  'p2' 'p1'_row_1 
$         @'coms'vector__parse.com  'p3' 'p1'_row_2 
$         @'coms'vector__parse.com  'p4' 'p1'_row_3
$
$         j = 1
$         j_loop:
$           k = 1
$           k_loop:
$             'p1'_'j''k' == row_'j'_'k'
$!             sh sym 'p1'_'j''k' 
$             k = k + 1
$             if (k .le. 3) then goto k_loop
$           j = j + 1
$           if (j .le. 3) then goto j_loop
$      else
$        say "COLS not implemented yet"
$      endif
$!
$!
$   sh sym 'p1'
$!
$! say "!! MATRIX__MAKE.COM:	Completed "
$! say "==========================================================" 
$ exit 
$!
$ terminate0:
$   say "  "
$   say "!! Error: vector__parse.com and vector__make.com required in ''coms' "
$   exit
$
$ terminate1:
$   say "  "
$    say "Makes a matrix 'p1' from vector coordinates u v w " 
$    say "P1 : matrix name"
$    say "P2 : vector u "
$    say "P3 : vector v  "
$    say "P4 : vector w  "
$    say "P5 : direction (ROWS*, COLS) "
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
