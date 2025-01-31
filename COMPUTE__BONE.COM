$!****************************************************************************************            
$! COMPUTE__BONE.COM
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
$!   @'scripts_dir'compute__bone.com	'input_filename' 'seg_filename' 'gobj_filename'
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
$!
$! update get__volume_skip for compatibility with get__volume.com:
$   if ("''get__volume_skip'" .eqs. "") then get__volume_skip == 0
$   get__volume_skip == get__volume_skip + 1
$!
$   seg_gobj_filename = p3 - ".GOBJ" + "_CB_TMP.AIM"
$   show symbol seg_gobj_filename
$!
$ 	ipl_batch

		/read
		  -name                      org
		  -filename    				 "p1
		
		/read 
		  -name                      seg
		  -filename    				 "p2
		  
		/db_scanco_activate true
		/db_clear_eval org
		/db_calib_unit_fill seg 
		
		! tmp mask for tissue density
		/gobj
		  -input_output              seg
		  -gobj_filename             "p3
		  -peel_iter                 1

		/write_v020
		  -name                      seg
          -filename                  "seg_gobj_filename
		  -compress_type             bin
		  -version_020               true

		! BV/TV

		/vox_scanco_param
		  -input                     seg

		! Apparent density 
		/voxgobj_scanco_param
		  -input                     org
		  -gobj_filename             "p3
		  -peel_iter                 1
		  -region_number 	     	 0

		! Tissue (matrix) density of segmented volume
		/voxgobj_scanco_param
		  -input                     org
		  -gobj_filename             "seg_gobj_filename
		  -peel_iter                 2
		  -region_number 	     	 1
..
$!
$ 	delete 'seg_gobj_filename';*
$!
$ 	say "!! COMPUTE__BONE.COM: Completed "
$ 	say "=========================================================="
$ 	exit
