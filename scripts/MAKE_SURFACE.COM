$!************************* EZ_IPL *****************************************           
$!
$! MAKE_SURFACE.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.03.14
$!  Copyright (c) 2011-2019 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Generates an surface AIM from a binary AIM
$! 
$! USAGE:
$!  @ez:make_surface 'mask_aim' 'surf_aim' 'direction_vec' 'thickness' 'log_file' 
$!
$! PARAMETERS:
$! P1 : name of input aim (mask)
$! P2 : name of surface out
$! P3* : vector with direction of surface  (*0,1,0)
$!      (eg 1,1,0 : screen-upper left surface)
$! P4* : thickness of surface              (*1)
$!      (>0 surface inside object, <0 surface outside)
$! P5* : logfile                           (*eval_logfile2)
$!
$! EXAMPLE:
$!    
$!
$!
$! VERSION HISTORY:
$!  2018.03.14 VS
$!  2019.03.10 EZ format, new params order
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! MAKE_SURFACE.COM: "
$ say "=========================================================="
$!*
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then goto terminate
$ if (p3 .eqs. "") then p3 := 0,1,0
$ if (p4 .eqs. "") then p4 = 1
$ if (p5 .eqs. "") then p5 = eval_logfile2
$
$  @ez:vector__parse.com  'p3' __ms_u 
$  if (__ms_u__h .nes. "V") then goto terminate
$
$ sh sym p1
$ sh sym p2
$ sh sym p3
$ sh sym p4
$ sh sym p5
$
$! temp objects
$   __ms_tmp1  = p1 - ".AIM" + "__ms_tmp1.aim"
$   __ms_tmp2  = p1 - ".AIM" + "__ms_tmp2.aim"
$   __ms_tmp   = p1 - ".AIM" + "__ms_tmp.aim"
$   __ms_tmp_tmat = p1 - ".AIM" + "__ms.tmat"
$
$! depending on direction of vector abs threshold is + or - 127
$   icalc 127 * 'p4'/abs('p4')
$   __abst = icalc_out 
$
$   @ez:vector__multiply.com	'p3' 'p4' __trans_vec
$   @ez:get_geometry.com		'p1' __in_mask 'p5'
$   @ez:vector__multiply.com	'__trans_vec' '__in_mask__els' __trans_vec_mm
$   @ez:make_tmat.com			'__ms_tmp_tmat' "TRANSLATE:''__trans_vec_mm'"
$   @ez:set_value.com			'p1' '__ms_tmp1' 127 0
$   @ez:transform.com	 		'__ms_tmp1' '__ms_tmp_tmat' '__ms_tmp2' 0 
$   @ez:set_value.com			'__ms_tmp2' '__ms_tmp2' -127 0
$   @ez:add_aims.com    		'__ms_tmp1' '__ms_tmp2' '__ms_tmp'
$   @ez:abs_threshold.com	    '__ms_tmp' '__ms_tmp' '__abst' '__abst' 127
$   @ez:complab.com				'__ms_tmp' 'p2' 1 1 127
$
$!   del '__ms_tmp';* 
$!   del '__ms_tmp1';* 
$!   del '__ms_tmp2';* 
$!   del '__ms_tmp_tmat';* 
$
$!#
$ say "!! MAKE_SURFACE.COM: completed	 "
$ say "=========================================================="
$ exit
$
$ terminate:
$   @ez:helper MAKE_SURFACE
$ exit
