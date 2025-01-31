$!****************************************************************************************            
$! COMPUTE__BVONLY.COM
$! 2015.04.05 V Stadelmann
$! 2017.07.03 VS fixed mean2 with seg_gobj_filename mask
$! 2017.07.20 VS voxgobj instead of vox
$! 
$! Description:
$! 	computes bv/tv, mean1, mean2
$! 	p1 : grayscale aim
$! 	p2 : segmented aim
$! 	p3 : gobj
$! 	p4 : peel org
$! 	p5 : peel seg
$!
$! Usage:
$!   @'scripts_dir'compute__bvonly.com	'input_filename' 'seg_filename' 'gobj_filename' 'peel1' 'peel2'
$!****************************************************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! COMPUTE__BONE.COM: computes bv/tv, mean1, mean2 "
$ say "=========================================================="
$!*
$!
$   show symbol p1
$   show symbol p2
$   show symbol p3
$   if (p4 .eqs "") then p4 = 0
$   if (p5 .eqs "") then p5 = 2 ! SCANCO default
$   show symbol p4
$   show symbol p5
$!
$   seg_gobj_filename = p3 - ".GOBJ" + "BV_TMP.AIM"
$
$! update get__volume_skip for compatibility with get__volume.com:
$   if ("''get__volume_skip'" .eqs. "") then get__volume_skip == 0
$   get__volume_skip == get__volume_skip + 1
$
$!
$ 	ipl_batch

/read
  -name                      org
  -filename                  "p1

/read
  -name                      seg
  -filename                  "p2

/db_scanco_activate true
/db_clear_eval org
/db_calib_unit_fill seg 

! tmp mask for tissue density
/gobj
  -input_output              seg
  -gobj_filename             "p3
  -peel_iter                 "p4
  
/write_v020
  -name                      seg
  -filename                  "seg_gobj_filename
  -compress_type             bin
  -version_020               true

/db_clear_eval seg

! uncomment if the script shall be started from terminal, 
! without clicking on 'Start 3D evaluation' ever for that measurement
!/db_calib_unit_fill seg

/vox_scanco_param
  -input                     seg

! apparent density 
/voxgobj_scanco_param
  -input                     org
  -gobj_filename             "p3
  -peel_iter                 "p4
  -region_number 	         0

! tissue (matrix) density of segmented volume
/voxgobj_scanco_param
  -input                     org
  -gobj_filename             "seg_gobj_filename
  -peel_iter                 "p5
  -region_number 	         1
..
$!
$!
$ 	say "!! COMPUTE__BVONLY.COM: Completed "
$ 	say "=========================================================="
$ 	exit
