$!****************************************************************************************            
$! COMPUTE_BONE.COM
$! 2015.04.05 V Stadelmann
$! 2017.07.03 VS fixed mean2 with seg_gobj_filename mask
$! 
$! Description:
$! 	computes bv/tv, mean1, mean2
$! 	p1 : grayscale aim
$! 	p2 : segmented aim
$! 	p3 : gobj
$!
$! Usage:
$!   @'scripts_dir'compute_bone.com	'input_filename' 'seg_filename' 'gobj_filename'
$!****************************************************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! COMPUTE_BONE.COM: computes bv/tv, mean1, mean2 "
$ say "=========================================================="
$!
$   show symbol p1
$   show symbol p2
$   show symbol p3
$!
$   seg_tmp_filename = p3 - ".GOBJ" + "_COMPBONE_SEG.AIM"
$   gobj_tmp_filename = p3 - ".GOBJ" + "_COMPBONE_SEG.GOBJ"
$   show symbol *_tmp_filename
$!
$ 	ipl_batch

		/read
		  -name                      org
		  -filename    				 "p1
		
		/read 
		  -name                      seg
		  -filename    				 "p2
		  
		! tmp mask for tissue density
		/gobj
		  -input_output              seg
		  -gobj_filename             "p3
		  -peel_iter                 0

		/write_v020
		  -name                      seg
          -filename                  "seg_gobj_filename
		  -compress_type             bin
		  -version_020               true

		/togobj_from_aim
		  -input                     seg
          -gobj_filename             "gobj_tmp_filename
          -min_elements              0
          -max_elements              0
          -curvature_smooth          1

		/db_scanco_activate true
		
		/db_clear_eval org
		
		! BV/TV
		/vox_scanco_param
  		  -input                     seg

		! Apparent density 
		/voxgobj_scanco_param
		  -input                     org
		  -gobj_filename             "p3
		  -peel_iter                 0
		  -region_number 	     	 0

		! Tissue (matrix) density of segmented volume
		/voxgobj_scanco_param
		  -input                     org
		  -gobj_filename             "gobj_tmp_filename
		  -peel_iter                 1
		  -region_number 	     	 1
..
$!
$! 	delete 'seg_gobj_filename';*
$!
$ 	say "!! COMPUTE_BONE.COM: Completed "
$ 	say "=========================================================="
$ 	exit
