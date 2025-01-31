$!****************************************************************************************            
$! COMPUTE__MOMENT2D.COM
$! 2015.04.05 V Stadelmann
$! 2017.07.03 VS fixed mean2 with seg_gobj_filename mask
$! 2017.07.20 VS voxgobj instead of vox
$! 
$! Description:
$! 	computes bv/tv, mean1, mean2
$! 	p1 : grayscale aim
$! 	p2 : segmented aim
$! 	p3 : gobj
$!
$! Usage:
$!   @'scripts_dir'compute__moment2d.com	'input_filename' 'output file' 'gobj_filename'
$!****************************************************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! COMPUTE__MOMENT2D.COM: computes bv/tv, mean1, mean2 "
$ say "=========================================================="
$!*
$!
$ if (p1 .eqs. "") then goto terminate
$ if (p3 .eqs. "") then p3 = "none"
$ if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_MOMENT2D.TXT"
$
$   show symbol p1
$   show symbol p2
$   show symbol p3
$!
$!
$ 	ipl_batch


/read
  -name                      in
  -filename                  "P1


/moment2d_of_inertia
  -input                     in
  -fileout_or_screentab      "p2
  -turnangle_cw              0.000000
  -gobj_filename             "p3
  -peel_iter                 "p4

..
$!
$!
$ 	say "!! COMPUTE__MOMENT2D.COM: Completed "
$ 	say "=========================================================="
$ 	exit
$ terminate:
$ say "!! P1  : name of input file"
$ say "!! P2* : output file"
$ say "!! P3* : name of gobj file or <<none>>"
$ say "!! "
$ say "!! *: optional"
$ exit
