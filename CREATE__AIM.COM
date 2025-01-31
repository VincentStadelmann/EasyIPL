$!*************************************************
$! CREATE__AIM.COM
$! 2017.07.17 V Stadelmann
$! 2018.03.08 VS vector format
$!
$! USAGE:
$!  @'scripts_dir'create__aim.com	'canvas_filename' 'pos_vec' 'dim_vec' 'offset_vec' 'el_size' 'type' 'val'
$!*************************************************
$!
$! if ("''coms'" .eqs. "") then coms = "ue:"
$ say = "write sys$output"
$
$ say "=========================================================="
$ say "!! CREATE__AIM.COM: Creates an empty canvas "
$ say "=========================================================="
$!*
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$ show symbol p5
$ show symbol p6
$ show symbol p7
$
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 := 0,0,0
$ if (p3 .eqs. "") then p3 := 10,10,10
$ if (p4 .eqs. "") then p4 := 0,0,0
$ if (p5 .eqs. "") then p5 := 1
$ if (p6 .eqs. "") then p6 := char
$ if (p7 .eqs. "") then p7 = 127
$
$! Parse inputs
$   if (f$locate(",", p2) .eq. f$length(p2)) then goto terminate
$   if (f$locate(",", p3) .eq. f$length(p3)) then goto terminate
$   if (f$locate(",", p4) .eq. f$length(p4)) then goto terminate
$
$  @ez:vector__parse.com  'p2' __can_pos
$  @ez:vector__parse.com  'p3' __can_dim
$  @ez:vector__parse.com  'p4' __can_off
$
$ IPL_BATCH

/create_canvas
  -output                    in
  -dim                       "__can_dim__ipl
  -off                       "__can_off__ipl
  -pos                       "__can_pos__ipl
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
$ say "!! CREATE__CANVAS.COM:	Completed "
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
