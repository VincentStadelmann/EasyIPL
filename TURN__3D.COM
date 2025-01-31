$!*************************************************            
$! TURN3D.COM
$! 2015.06.30 - V.Stadelmann
$! 
$! USAGE:
$! rotation of image in around axis TBD, with angle alpha
$!   @ue:turn3d.com	'input_filename' 'out_filename' 'axes_angle' 'rot_angle' 'interpolate'
$!*************************************************            
$!
$!
$ say "=========================================================="
$ say "!! turn3d.com: "
$ say "=========================================================="
$!
$  sh sym p3
$   ipl_axes_1 = f$element(0,".",p3)
$   ipl_axes_2 = f$element(1,".",p3)
$   ipl_axes_3 = f$element(2,".",p3)
$ sh sym ipl_axes*
$!
$!
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
