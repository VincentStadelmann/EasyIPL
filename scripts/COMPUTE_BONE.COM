$!************************* EZ_IPL *****************************************           
$!
$! COMPUTE_BONE.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2015.04.05
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Compute BV, BV/TV, Mean1, Mean2 & write into database
$! 
$! USAGE:
$!  @ez:compute_bone.com 'aim_file' 'seg_file' 'gobj_file'
$!
$! PARAMETERS:
$!  P1  : Input grayscale AIM file
$!  P2  : Input seg file
$!  P3  : ROI GOBJ file
$!
$! EXAMPLE:
$!   
$!
$! VERSION HISTORY:
$!  2015.04.05 V Stadelmann
$!  2017.07.03 VS fixed mean2 with __tmp_seg_gobj_file mask
$!  2017.07.20 VS voxgobj instead of vox
$!  2018.12.09 EZ format
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! COMPUTE_BONE.COM: "
$ say "=========================================================="
$!*
$
$   if (p1 .eqs. "") then goto terminate
$   if (p2 .eqs. "") then goto terminate
$   if (p3 .eqs. "") then goto terminate
$   show symbol p1
$   show symbol p2
$   show symbol p3
$!
$! update get__volume_skip for compatibility with get__volume.com:
$   if ("''get__volume_skip'" .eqs. "") then get__volume_skip == 0
$   get__volume_skip == get__volume_skip + 1
$
$! temporary seg mask for mean2
$   __tmp_seg_gobj_file = p3 - ".GOBJ" + "_CB_TMP.AIM"
$   show symbol __tmp_seg_gobj_file
$!
$ 	ipl_batch

    /read
      -name                 org
      -filename             "p1
    
    /read 
      -name                 seg
      -filename             "p2
      
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
      -filename                  "__tmp_seg_gobj_file
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
      -gobj_filename             "__tmp_seg_gobj_file
      -peel_iter                 2
      -region_number 	     	 1
..
$
$ 	delete '__tmp_seg_gobj_file';*
$
$!#
$ 	say "!! COMPUTE_BONE.COM: Completed "
$ 	say "=========================================================="
$ 	exit
$
$ terminate:
$  @ez:helper COMPUTE_BONE.com
$ exit