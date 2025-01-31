$!****************************************************************************************            
$! COMPUTE__TRAB.COM
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
$!   @'scripts_dir'compute__trab.com	'input_filename' 'seg_filename' 'gobj_filename'
$!****************************************************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! COMPUTE__TRAB.COM: computes trab morpho "
$ say "=========================================================="
$!*
$!
$ show symbol p1
$ show symbol p2
$ show symbol p3
$
$ if ("''get__tri_skip'" .eqs. "") then get__tri_skip == 0
$ if (get__tri_skip .nes. "") then skip := "/skip=''get__tri_skip'"
$ if (get__tri_skip .eq. 0) then skip := ""
$ get__tri_skip == get__tri_skip + 1
$
$ sp_filename     = p1 - ".AIM" + "_DT.AIM"
$ th_filename     = p2 - ".AIM" + "_TH.AIM"
$ spres_filename  = p1 - ".AIM" + "_DT.TXT"
$ thres_filename  = p2 - ".AIM" + "_TH.TXT"
$ matres_filename = p2 - ".AIM" + "_1-OVER-N.TXT"
$
$! update get__volume_skip for compatibility with get__volume.com:
$   if ("''get__volume_skip'" .eqs. "") then get__volume_skip == 0
$   get__volume_skip == get__volume_skip + 1
$   if ("''get__tri_skip'" .eqs. "") then get__tri_skip == 0
$   get__tri_skip == get__tri_skip + 1

$!
$   seg_mask_filename = p3 - ".GOBJ" + "_CB_TMP.AIM"
$   show symbol seg_mask_filename
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
  -filename                  "seg_mask_filename
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
  -gobj_filename             "seg_mask_filename
  -peel_iter                 2
  -region_number 	     	 1

/sup seg
  -supdim_numbers            4 4 1
  -testoff_pixels            0 0 0
  -suppos_pixels_local       -1 -1 -1
  -subdim_pixels             -1 -1 -1

/tri seg tri
  -gobj_filename             gobj_from_log
  -peel_iter                 -1
  -ip_sigma                  0.000000
  -ip_support                0
  -ip_threshold              50
  -nr_ave_iter               2
  -t_dir_radius              2
  -epsilon                   1.200000
  -size_image                512 512
  -scale_image               0.700000
  -edges                     false
  -nr_views                  0

/connectivity
  -in_out                    seg

/dt_object
  -input                     seg
  -output                    out
  -gobj_filename             gobj_from_log
  -peel_iter                 -1
  -roi_radius_factor         10000.000000
  -ridge_epsilon             0.900000
  -assign_epsilon            1.800000
  -histofile_or_screen       "thres_filename

/write_v020
  -name                      out
  -filename                  "th_filename
  -compress_type             bin
  -version_020               true

/db_set_mean_accur 
  -input                     seg 
  -region_number             1
  -param_code                1
  -min_number_pixels         6

/dt_background
  -input                     seg
  -output                    out
  -gobj_filename             gobj_from_log
  -peel_iter                 -1
  -roi_radius_factor         10000.000000
  -ridge_epsilon             0.900000
  -assign_epsilon            1.800000
  -histofile_or_screen       "spres_filename

/write_v020
  -name                      out
  -filename                  "sp_filename
  -compress_type             bin
  -version_020               true

/dt_mat
  -input                     seg
  -output                    out
  -gobj_filename             gobj_from_log
  -peel_iter                 -1
  -roi_radius_factor         10000.000000
  -ridge_epsilon             0.900000
  -assign_epsilon            1.800000
  -histofile_or_screen       "matres_filename
..
$!
$ 	delete 'seg_mask_filename';*
$!
$ 	say "!! COMPUTE__TRAB.COM: Completed "
$ 	say "=========================================================="
$ 	exit
