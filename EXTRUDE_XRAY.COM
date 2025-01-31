$!************************* EZ_IPL *****************************************           
$!
$! EXTRUDE_XRAY.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.03.09
$!  Copyright (c) 2019 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Extrude an 1-slice grayscale AIM (eg. x-ray) along an axis
$! 
$! USAGE:
$!  @ue:extrude_xray.com	'input_file' 'output_file'  'dim_vec' 'log_file'
$! 
$! PARAMETERS:
$!  P1 : AIM filename
$!  P2 : AIM output filename
$!  P3 : Z Dimensions vector z_pos,z_dim  
$!  P4*: LOG file                        (*eval_logfile2)
$!
$! EXAMPLE:
$!    
$!
$! VERSION HISTORY:
$!  2018.06.12 VS bug fix
$!  2019.03.25 EZ format
$!
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! EXTRUDE_XRAY.COM: "
$ say "=========================================================="
$!*
$
$! Parse input
$ 	if (p1 .eqs. "") then goto terminate
$ 	if (p2 .eqs. "") then goto terminate
$ 	if (p3 .eqs. "") then goto terminate
$ 	if (p4 .eqs. "") then p4 = eval_logfile2
$
$   show symbol p1
$   show symbol p2
$   show symbol p3
$   show symbol p4
$
$! Define intermediate filename
$   __ex_tmp_file  = p1 - ".AIM" + "__EX_TMP.AIM"
$!
$!  ====================  Script body  ====================================
$!
$! Parse p3, must be 2D vector, trick: add a silent coordinate to make it 3D
$   @ez:vector__parse 'p3',0 __ex_pdv    
$   if (__ex_pdv__h .nes. "V") then goto terminate
$
$   @ez:get_geometry	'p1' __ex_org 'p4'
$   @ez:scale	      	'p1' '__ex_tmp_file' 1 1,1,'__ex_pdv__2' false
$   @ez:set_header		'__ex_tmp_file' 'p2' '__ex_org__pos_x','__ex_org__pos_y','__ex_pdv__1' -1,-1,-1 '__ex_org__els'
$
$ del '__ex_tmp_file';*
$ say "!!  "
$!#
$ say "!! EXTRUDE_XRAY.COM: completed"
$ say "=========================================================="
$ exit
$!
$ terminate:
$  @ez:helper EXTRUDE_XRAY
$ exit
$
$
