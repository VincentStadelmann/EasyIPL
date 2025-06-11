$!************************* EZ_IPL *****************************************           
$!
$! EXTRUDE_GOBJ.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.03.09
$!  Copyright (c) 2019 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Extrude GOBJ along an axis
$! 
$! USAGE:
$!  @ez:extrude_gobj 'gobj_in' 'gobj_out'  'axis' 'vec_pos,dim' 'log_filename'
$! 
$! PARAMETERS:
$!  P1 : GOBJ filename
$!  P2 : GOBJ output filename
$!  P3 : axis (X, Y or Z)       
$!  P4 : Vector position,dimension of extrusion
$!  P5*: LOG file               (*eval_logfile2)
$!
$! EXAMPLE:
$!    
$!
$! VERSION HISTORY:
$!  2018.10.18 EZ format, multiple AIMs inputs
$!  2019.03.11 Use Extrude_aim 
$!  2019.03.25 Bug in help + $!#
$!
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! EXTRUDE_GOBJ.COM: "
$ say "=========================================================="
$!*
$!
$!  ====================   Filenames   ====================================
$
$!
$ 	if (p1 .eqs. "") then goto terminate
$ 	if (p2 .eqs. "") then goto terminate
$ 	if (p3 .eqs. "") then goto terminate
$ 	if (p4 .eqs. "") then goto terminate
$   if (p5 .eqs. "") then p5 = eval_logfile2
$
$! Parse input
$   show symbol p1
$   show symbol p2
$   show symbol p3
$   show symbol p4
$   show symbol p5
$
$! Define intermediate filename
$   __eg_tmp_file   = p1 - ".GOBJ" + "__EG_TMP.AIM"
$
$!  ====================  Script body  ====================================
$!
$   @ez:gobj_to_aim  	  	'p1' '__eg_tmp_file' 127
$   @ez:extrude_aim         '__eg_tmp_file' '__eg_tmp_file' 'p3' 'p4' 'p5'
$   @ez:aim_to_gobj	        '__eg_tmp_file'  'p2' 0 0 5
$
$   del/log '__eg_tmp_file';*
$
$!#
$ say "!!  "
$ say "!! EXTRUDE_GOBJ.COM: completed"
$ say "=========================================================="
$ exit
$!
$ terminate:
$  @ez:helper EXTRUDE_GOBJ
$ exit
$
