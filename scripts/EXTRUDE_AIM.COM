$!************************* EZ_IPL *****************************************           
$!
$! EXTRUDE_AIM.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.03.09
$!  Copyright (c) 2019 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Extrude binary AIM along an axis
$! 
$! USAGE:
$!  @ez:extrude_aim 'aim_in' 'aim_out'  'axis' 'vec_pos,dim' 'log_filename'
$! 
$! PARAMETERS:
$!  P1: AIM filename
$!  P2: AIM output filename
$!  P3: axis (X, Y or Z)       
$!  P4: Vector position,dimension of extrusion
$!  P5: LOG file               (*eval_logfile2)
$!
$! EXAMPLE:
$!    
$!
$! VERSION HISTORY:
$!  2018.10.18 EZ format
$!  2019.03.11 New name, new params order
$!
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! EXTRUDE_AIM.COM: "
$ say "=========================================================="
$!*
$
$!  ====================   Filenames   ====================================
$!
$! Parse input
$ 	if (p1 .eqs. "") then goto terminate
$ 	if (p2 .eqs. "") then goto terminate
$ 	if (P3 .eqs. "") then goto terminate
$ 	if (P4 .eqs. "") then goto terminate
$   if (p5 .eqs. "") then p5 = eval_logfile2
$
$! Check direction of projection:
$    if (P3 .nes. "X" .and. P3 .nes. "Y" .and. P3 .nes. "Z") then goto terminate
$
$! Parse p4, must be 2D vector, trick: add a silent coordinate to make it 3D
$   @ez:vector__parse 'p4',0 __ea_pdv    
$   if (__ea_pdv__h .nes. "V") then goto terminate
$
$   show symbol p1
$   show symbol p2
$   show symbol P4
$   show symbol P3
$   show symbol p5
$
$! Define intermediate filename
$   __ea_tmp_file  = p1 - ".AIM" + "__EA_TMP.AIM"
$   __ea_rot_file  = p1 - ".AIM" + "__EA_ROT.AIM"
$   __ea_xra_file  = p1 - ".AIM" + "__EA_XRA.AIM"
$   __ea_xrs_file  = p1 - ".AIM" + "__EA_XRS.AIM"
$   __ea_xra_gobj  = p1 - ".AIM" + "__EA_XRA.GOBJ"
$   __ea_sca_gobj  = p1 - ".AIM" + "__EA_SCA.GOBJ"
$   __ea_rxt_file  = p1 - ".AIM" + "__EA_RXT.AIM"
$   __ea_can_file  = p1 - ".AIM" + "__EA_CAN.AIM"
$   __ea_tmat_file = p1 - ".AIM" + "__EA_ROT.TMAT"
$!
$!  ====================  Script body  ====================================
$!
$
$! Get original geo into vec for later
$   @ez:get_geometry 	'p1' __ea_org_geo 'p5'
$
$! Rotate image to put extrusion direction in Z temporarily
$   if (P3 .eqs. "X") then @ez:make_tmat.com '__ea_tmat_file' "ROT_Y:-90"
$   if (P3 .eqs. "Y") then @ez:make_tmat.com '__ea_tmat_file' "ROT_X:-90"
$   if (P3 .eqs. "Z") then @ez:make_tmat.com '__ea_tmat_file' "ROT_Z:0"
$
$   @ez:transform 	 	'p1' '__ea_tmat_file' '__ea_tmp_file' 
$   @ez:get_geometry 	'__ea_tmp_file' __ea_tmp_geo 'p5'
$   @ez:set_header 		'__ea_tmp_file' '__ea_rot_file' 0,0,0  0,0,0 
$   @ez:get_geometry 	'__ea_rot_file' __ea_rot_geo  'p5'
$
$ ! project (xray) to get shape of mask
$   @ez:make_xray.com	'__ea_rot_file' '__ea_xra_file' 1 '__ea_rot_geo__dim_z'
$   @ez:abs_threshold 	'__ea_xra_file' '__ea_xrs_file' 1 1000 127
$
$ ! convert to gobj before scaling to gain speed
$   @ez:aim_to_gobj	   	'__ea_xrs_file' '__ea_xra_gobj' 0 0 5 
$   @ez:scale		    '__ea_xra_gobj' '__ea_sca_gobj' 1 1,1,'__ea_pdv__2' 1
$
$ ! create empty aim to fit scaled up gobj
$   @ez:vector__make    __can__vec_dim '__ea_rot_geo__dim_x' '__ea_rot_geo__dim_y' '__ea_pdv__2'    
$   @ez:make_aim      '__ea_can_file' 0,0,0 '__can__vec_dim' 0,0,0 '__ea_rot_geo__vec_els'
$
$ ! Apply scaled gobj -> extruded mask
$   @ez:apply_gobj      '__ea_can_file' '__ea_sca_gobj' '__ea_rxt_file' 0 false
$
$  ! move extruded mask back to original position in original space
$   @ez:set_header 		'__ea_rxt_file' '__ea_tmp_file' '__ea_tmp_geo__vec_pos' '__ea_tmp_geo__vec_off'   ! back to post transform position
$   @ez:transform       '__ea_tmp_file' '__ea_tmat_file' '__ea_tmp_file' 0 1                              ! inverse transform matrix
$   if (P3 .eqs. "X") then @ez:vector__make    __ext__vec_pos '__ea_pdv__1' '__ea_org_geo__pos_y' '__ea_org_geo__pos_z' 
$   if (P3 .eqs. "Y") then @ez:vector__make    __ext__vec_pos '__ea_org_geo__pos_x' '__ea_pdv__1' '__ea_org_geo__pos_z' 
$   if (P3 .eqs. "Z") then @ez:vector__make    __ext__vec_pos '__ea_org_geo__pos_x' '__ea_org_geo__pos_y' '__ea_pdv__1' 
$   @ez:set_header   	'__ea_tmp_file' 'p2' '__ext__vec_pos' '__ea_org_geo__vec_off' 
$
$   del/log '__ea_tmp_file';* 
$   del/log '__ea_rot_file';* 
$   del/log '__ea_xra_file';* 
$   del/log '__ea_xrs_file';* 
$   del/log '__ea_xra_gobj';* 
$   del/log '__ea_sca_gobj';* 
$   del/log '__ea_rxt_file';* 
$   del/log '__ea_can_file';* 
$   del/log '__ea_tmat_file';* 
$
$!#
$ say "!! EXTRUDE_AIM.COM: completed"
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper EXTRUDE_AIM
$ exit
$