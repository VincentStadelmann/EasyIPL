$!****************************************************************************************            
$! MAKE__SURFACE.COM
$! 2018.03.14 V.Stadelmann
$! 
$! usage:
$!  @ez:make__surface.com	'mask_aim' 'surf_aim' 'log_file' 'direction_vec' 'surface_thickness'
$!
$! P1 : name of input aim (mask)
$! P2 : name of surface out
$! P3 : logfile
$! P4 : vector with direction of surface 
$!      (eg 0,1,0 : screen-upper surface on y axis (ie facing low y numbers) )
$! P5 : thickness of surface 
$!
$!****************************************************************************************            
$
$! if ("''coms'" .eqs. "") then coms = "ue:"
$ say = "write sys$output"
$
$ say "=========================================================="
$ say "!! MAKE__SURFACE.COM: makes a surface by translating an AIM  "
$ say "=========================================================="
$!*
$!
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then goto terminate
$ if (p3 .eqs. "") then goto terminate
$ if (p4 .eqs. "") then p3 := 0,1,0
$ if (f$locate(",", p4) .eq. f$length(p4)) then goto terminate
$ if (p5 .eqs. "") then p5 := 1
$
$ sh sym p1
$ sh sym p2
$ sh sym p3
$ sh sym p4
$ sh sym p5
$
$   __tmp_obj1  = p1 - ".AIM" + "__ms1.aim"
$   __tmp_obj2  = p1 - ".AIM" + "__ms2.aim"
$   __tmp_tmat = p1 - ".AIM" + "__ms.tmat"
$   __vec_0  := 0,0,0
$   icalc 127 * 'p5'/abs('p5')
$   __abst = icalc_out ! depending on direction of vector abs threshold is + or - 127
$
$   @ez:vector__multiply.com	    'p4' 'p5' __trans_vec
$   @ez:get__geometry.com		'p1' 'p3' __in_mask
$   @ez:vector__multiply.com	    '__trans_vec' '__in_mask__vec_els' __trans_vec_mm
$   @ez:make__tmat.com			'__tmp_tmat' "TRANSLATE:''__trans_vec_mm__ipl'"
$   @ez:set_value.com			'p1' '__tmp_obj1' 127 0
$   @ez:transform.com	 		'__tmp_obj1' '__tmp_tmat' '__tmp_obj2' 0 
$   @ez:set_value.com			'__tmp_obj2' '__tmp_obj2' -127 0
$   @ez:add_2_aims.com    		'__tmp_obj1' '__tmp_obj2' '__tmp_obj2'
$   @ez:abs_threshold.com	    '__tmp_obj2' '__tmp_obj2' '__abst' '__abst' 127
$   @ez:complab.com				'__tmp_obj2' 'p2' 1 1 127
$
$   del '__tmp_obj1';* /since
$   del '__tmp_obj2';* /since
$
$ say "!! MAKE__SURFACE.COM: completed	 "
$ say "=========================================================="
$ exit
$
$ terminate:
$ say " P1 : name of input aim (mask)"
$ say " P2 : name of surface out"
$ say " P3 : log file "
$ say " P4 : vector with direction of surface "
$ say "     (eg 0,1,0 : screen-upper surface on y axis (ie facing low y numbers) )"
$ say " P5 : thickness of surface"
$ exit
