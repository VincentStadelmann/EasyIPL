$!*************************************************            
$! TURN3D.COM
$! 2015.06.30 - V.Stadelmann
$! 2018.03.15 - vec format + input testing
$! 
$! USAGE:
$! rotation of image in around axis TBD, with angle alpha
$!   @ue:turn3d.com	'input_filename' 'out_filename' 'axes_angle' 'rot_angle' 'interpolate'
$!*************************************************            
$!
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! TURN3D.COM: "
$ say "=========================================================="
$!*
$!
$    if (p1 .eqs. "") then goto terminate
$    if (p2 .eqs. "") then goto terminate
$    if (p3 .eqs. "") then p3 := 90,90,0
$    if (p4 .eqs. "") then p4 := 0
$    if (p5 .eqs. "") then p5 := 1
$    if (p5 .eqs. "1") then p5 = "true"
$    if (p5 .eqs. "0") then p5 = "false"
$    if (p5 .nes. "true" .and. p5 .nes. "false") then p5 = "true"
$
$    sh sym p1
$    sh sym p2
$    sh sym p3
$    sh sym p4
$    sh sym p5
$
$   if (f$locate(",", p3) .lt. f$length(p3)) 
$     then 
$      ipl_axes_1 = f$element(0,",",p3)
$      ipl_axes_2 = f$element(1,",",p3)
$      ipl_axes_3 = f$element(2,",",p3)
$     else
$       if (f$locate(".", p3) .lt. f$length(p3)) 
$         then 
$          ipl_axes_1 = f$element(0,".",p3)
$          ipl_axes_2 = f$element(1,".",p3)
$          ipl_axes_3 = f$element(2,".",p3)
$         else
$          goto terminate
$       endif
$   endif
$
$   sh sym ipl_axes*
$
$ ipl_batch

/read
  -name                      tmp
  -filename                  "p1


/turn3d
  -input                     tmp
  -output                    out
  -turnaxis_angles           "ipl_axes_1 "ipl_axes_2 "ipl_axes_3
  -turnangle                 "p4
  -img_interpol_option       "p5

  
/write
  -name                      out
  -filename                  "p2
  -compress_type             bin
  -version_020               true

  
..
$ say "!! TURN3D.com completed "
$ say "=========================================================="
$ exit
$
$ TERMINATE:
$ 	say "!! P1 : name of input file"
$ 	say "!! P2 : name of output file"
$ 	say "!! P3*: axes angles (eg. 90,90,0)"
$ 	say "!! P4*: rotation angle (eg. 0) "
$ 	say "!! P5*: interpolation (true*/false)"
$ exit
