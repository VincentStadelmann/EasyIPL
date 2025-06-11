$!**************************************************************************************************                        
$! MATRIX__TRANS_U_TO_V.COM
$! 2017.08.28 V. Stadelmann 
$! 
$! Description:
$!  Makes a matrix 'p1' to transform vector u into v
$!  P1 : matrix name
$!  P2 : vector u 
$!  P3 : vector v  
$!
$! Reference:
$!   http://immersivemath.com/forum/question/rotation-matrix-from-one-vector-to-another/
$!
$! USAGE:
$!   @'coms'matrix__trans_u_to_v.com  'matname' 'u' 'v'
$!
$!**************************************************************************************************                        
$!
$ say = "write sys$output"
$ say "  "
$! say "=========================================================="
$ say "!! MATRIX__TRANS_U_TO_V.COM:  "
$! say "=========================================================="
$!
$  if ("''coms'" .eqs. "") then coms = "ue:"
$  if (f$search("''coms'vector__parse.com") .eqs. "") then goto terminate0
$  if (f$search("''coms'vector__make.com") .eqs. "") then goto terminate0
$  if (f$search("''coms'matrix__make.com") .eqs. "") then goto terminate0
$
$  if (p1 .eqs. "") then goto terminate1
$
$  j = 1
$  pj_loop:
$    j = j + 1
$    if (p'j' .eqs. "") then goto terminate1
$    if (f$locate(",", p'j') .eq. f$length(p'j')) then goto terminate2
$    if (j .lt. 3) then goto pj_loop
$!
$  Say "!! Parse vectors, dot and cross products"
$    @'coms'vector__parse.com  			'p2' vec__uu
$    @'coms'vector__parse.com  			'p3' vec__vv
$    @'coms'vector__norm.com 	        'vec__uu' 1  vec__u
$    @'coms'vector__norm.com 	        'vec__vv' 1  vec__v
$
$    @'coms'vector__cross_product.com 	'vec__u' 'vec__v'  vec__a
$    @'coms'vector__get_angle.com		'vec__u' 'vec__v'  angle__alpha
$    sh sym vec__a
$    sh sym angle__alpha
$
$ Say "!! Compute trigonometric elements c=cos(alpha) and s=sin(alpha)"
$    icalc cos('angle__alpha')
$    float__c == icalc_out
$    icalc sin('angle__alpha')
$    float__s == icalc_out
$    icalc 1-'float__c'
$    float__d == icalc_out
$    sh sym float__c
$    sh sym float__s
$    sh sym float__d
$!
$ Say "!! Compute matrix elements"
$!   Say "M_11"
$    icalc ('vec__a_1'^2*'float__d') + 'float__c'
$    M_11 =  icalc_out
$!   Say "M_12"
$    icalc 'vec__a_1'*'vec__a_2'*'float__d' - 'float__s'*'vec__a_3'
$    M_12 = icalc_out
$!   Say "M_13"
$    icalc 'vec__a_1'*'vec__a_3'*'float__d' + 'float__s'*'vec__a_2'
$    M_13 = icalc_out
$    @'coms'vector__make.com  	mat_row1 'm_11' 'm_12' 'm_13'
$
$!   Say "M_21"
$    icalc 'vec__a_1'*'vec__a_2'*'float__d' + 'float__s'*'vec__a_3'
$    M_21 = icalc_out
$!   Say "M_22"
$    icalc ('vec__a_2'^2*'float__d') + 'float__c'
$    M_22 =  icalc_out
$!   Say "M_23"
$    icalc 'vec__a_2'*'vec__a_3'*'float__d' - 'float__s'*'vec__a_1'
$    M_23 = icalc_out
$    @'coms'vector__make.com  	mat_row2 'm_21' 'm_22' 'm_23'
$
$!   Say "M_31"
$    icalc 'vec__a_1'*'vec__a_3'*'float__d' - 'float__s'*'vec__a_2'
$    M_31 = icalc_out
$!   Say "M_32"
$    icalc 'vec__a_2'*'vec__a_3'*'float__d' + 'float__s'*'vec__a_1'
$    M_32 = icalc_out
$!   Say "M_33"
$    icalc 'vec__a_3'^2*'float__d' + 'float__c'
$    M_33 =  icalc_out
$    @'coms'vector__make.com  	mat_row3 'm_31' 'm_32' 'm_33'
$
$    @'coms'matrix__make.com  	'p1' 'mat_row1' 'mat_row2' 'mat_row3' 
$    
$
$! say "!! MATRIX__TRANS_U_TO_V.COM:	Completed "
$! say "==========================================================" 
$ exit 
$!
$ terminate0:
$   say "  "
$   say "!! Error: vector__parse.com and matrix__make.com required in ''coms' "
$   exit
$
$ terminate1:
$    say "  "
$    say " Makes a matrix 'p1' to transform vector u into v " 
$    say " P1 : matrix name"
$    say " P2 : vector u "
$    say " P3 : vector v  "
$    exit
$ terminate2:
$   say "  "
$   say "!! Error: incorrect parameters"
$    say "P1 : matrix name"
$    say "P2 : vector u "
$    say "P3 : vector v  "
$    say "P4 : vector w  "
$    say "P5 : direction (ROWS*, COLS) "
$   exit
