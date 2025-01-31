$!****************************************************************************************            
$! COMPUTE__DT.COM
$! 2017.10.31 VStadelmann
$! 
$! Description:
$! 	computes distance transform
$! 	p1 : segmented aim
$! 	p2 : dt aim
$! 	p3 : histo file
$! 	p4 : gobj
$!
$! Usage:
$!   @'scripts_dir'compute__dt_th.com	'input_filename' 'dt_filename' 'histo_file*' 'gobj_filename*' 
$!****************************************************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! COMPUTE__DT.COM: computes DT "
$ say "=========================================================="
$!*
$!
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then goto terminate
$ show symbol p1
$ show symbol p2
$!
$ if (p3 .eqs "") then p3 = p1 - ".AIM" + "_DT.TXT"
$ if (p4 .eqs "") then p4 = "gobj_from_log"
$ show symbol p3
$ show symbol p4
$!
$ 	ipl_batch

/db_scanco_activate true

/read
  -name                      seg
  -filename    				 "p1

/dt_thickness
  -input                     seg
  -output                    out
  -gobj_filename             "p4
  -peel_iter                 0
  -ridge_epsilon             0.900000
  -assign_epsilon            1.800000
  -histofile_or_screen       "p3
  -suppress_boundary         0
  -version                   3
  
/examine
  -input                     out
  -item                      stat

/write_v020
  -name                      out
  -filename                  "p2
  -compress_type             bin
  -version_020               true

..
$!
$!
$ 	say "!! COMPUTE__DT.COM: Completed "
$ 	say "=========================================================="
$ 	exit
$!
$ terminate:
$ say "!! P1 : name of input file"
$ say "!! P2 : name of output file"
$ say "!! P3 : name of histo file (optional)"
$ say "!! P4 : name of gobj file (optional)"
$ exit
