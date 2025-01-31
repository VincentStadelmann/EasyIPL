$!*************************************************            
$! CREATE_CANVAS.COM
$! 2017.07.17 V Stadelmann
$! 
$! USAGE:
$!  @'scripts_dir'create_canvas.com	'canvas_filename' 'posx.y.z' 'dimx.y.z' 'offsetx.y.z' 'el_size' 'type' 'val'
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! CREATE_CANVAS.COM: Creates an empty canvas "
$ say "=========================================================="
$!*
$!
$ if (p1 .eqs. "") then goto terminate1
$ show symbol p1 
$ show symbol p2 
$ show symbol p3 
$ show symbol p4
$ show symbol p5
$ show symbol p6
$ show symbol p7
$!
$!
$! Parse inputs
$   if (f$locate(".", p2) .lt. f$length(p2))
$ 	  then 
$	    say "!! Found ""."" in p2 - Parsing position from list"
$       canvas_pos_x = f$element(0,".",p2)
$       canvas_pos_y = f$element(1,".",p2)
$       canvas_pos_z = f$element(2,".",p2)
$   else	
$	  say "!! No ""."" found in p2"
$     goto terminate1
$   endif
$! 
$   if (f$locate(".", p3) .lt. f$length(p3))
$ 	  then 
$	    say "!! Found ""."" in p3 - Parsing position from list"
$       canvas_dim_x = f$element(0,".",p3)
$       canvas_dim_y = f$element(1,".",p3)
$       canvas_dim_z = f$element(2,".",p3)
$   else	
$	  say "!! No ""."" found in p3"
$     goto terminate1
$   endif
$! 
$   if (f$locate(".", p4) .lt. f$length(p4))
$ 	  then 
$	    say "!! Found ""."" in p4 - Parsing position from list"
$       canvas_off_x = f$element(0,".",p4)
$       canvas_off_y = f$element(1,".",p4)
$       canvas_off_z = f$element(2,".",p4)
$   else	
$	  say "!! No ""."" found in p4"
$     goto terminate1
$   endif
$!
$ if (p6 .eqs. "") then p6 := char
$ if (p7 .eqs. "") then p7 = 0
$!
$ IPL_BATCH

/create_canvas
  -output                    in
  -dim                       "canvas_dim_x "canvas_dim_y "canvas_dim_z
  -off                       "canvas_off_x "canvas_off_y "canvas_off_z
  -pos                       "canvas_pos_x "canvas_pos_y "canvas_pos_z
  -el_size_mm                "p5 
  -type                      "p6

/set_value
  -input                     in
  -value_object              "p7
  -value_background          "p7
  
/write_v020
  -name                      in
  -filename                  "p1
  -compress_type             bin
  -version_020               true

..
$ say "!! CREATE_CANVAS.COM:	Completed "
$ say "=========================================================="
$ exit
$ terminate1:
$   say "!!  P1: Filename "
$   say "!!  P2: Position "
$   say "!!  P3: Dimensions "
$   say "!!  P4: Offset "
$   say "!!  P5: El. size"
$   say "!!  P6: Type (default = char) "
$   say "!!  P7: Value (default = 0) "
