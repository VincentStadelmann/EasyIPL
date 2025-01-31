$!*************************************************
$! EXTRUDE__GOBJ.COM
$!  2018.03.09 VStadelmann
$!
$! Description:
$! 	Extrude a GOBJ along an axis
$!  P1: GOBJ filename
$!  P2: GOBJ output filename
$!  P3: LOG file
$!  P4: axis,dimensions vector
$!
$! USAGE:
$!  @ue:extrude__gobj.com	'gobj_input' 'gobj_output' 'log_filename'  'axis' 'dim_vec'
$!
$!*************************************************
$!
$ say == "write sys$output "
$ on error then exit
$ set output_rate=00:00:01
$ wait 00:00:01
$ icalc :== $ut:icalc.exe
$! if ("''coms'" .eqs. "") then coms = "ue:"
$
$ say "=========================================================="
$ say "!!		EXTRUDE__GOBJ.COM      	     	  "
$ say "=========================================================="
$!*
$!
$!  ====================   Filenames   ====================================
$!
$! Parse input
$   show symbol p1
$   show symbol p2
$   show symbol p3
$   show symbol p4
$   show symbol p5
$!
$ 	if (p1 .eqs. "") then goto terminate
$ 	if (p2 .eqs. "") then goto terminate
$ 	if (p3 .eqs. "") then goto terminate
$ 	if (p4 .eqs. "") then goto terminate
$ 	if (p5 .eqs. "") then goto terminate
$!
$! Define intermediate filename
$   __tmp_filename  = p1 - ".GOBJ" + "___TMP.AIM"
$   __roi_filename  = p1 - ".GOBJ" + "___ROI.AIM"
$   __rot_filename  = p1 - ".GOBJ" + "___ROT.AIM"
$   __xra_filename  = p1 - ".GOBJ" + "___XRA.AIM"
$   __xrs_filename  = p1 - ".GOBJ" + "___XRS.AIM"
$   __xra_gobj      = p1 - ".GOBJ" + "___XRA.GOBJ"
$   __sca_gobj      = p1 - ".GOBJ" + "___SCA.GOBJ"
$   __rxt_filename  = p1 - ".GOBJ" + "___RXT.AIM"
$   __ext_filename  = p1 - ".GOBJ" + "___EXT.AIM"
$   __can_filename  = p1 - ".GOBJ" + "___CAN.AIM"
$   __tmat_filename = p1 - ".GOBJ" + "___ROT.TMAT"
$!
$!  ====================  Script body  ====================================
$!
$! Check if p5 is vector
$ if (f$locate(",", p5) .lt. f$length(p5))
$ 	then
$   	__pos_axis   = f$element(0,",",p5)
$   	__dim_axis   = f$element(1,",",p5)
$       __scale_vec := 1,1,'__dim_axis'
$ 	else
$       goto terminate
$ endif
$
$! Check direction of projection:
$    if (p4 .nes. "X" .and. p4 .nes. "Y" .and. p4 .nes. "Z") then goto terminate
$
$! Transform GOBJ into mask
$   @ez:gobj_to_aim.COM	  	'p1' '__roi_filename' 127
$   @ez:get__geometry.com	'__roi_filename' 'p3' __org
$
$! Rotate image to proj. direction
$   if (p4 .eqs. "X") then @ez:make__tmat.com	'__tmat_filename' "ROT_Y:-90"
$   if (p4 .eqs. "Y") then @ez:make__tmat.com	'__tmat_filename' "ROT_X:-90"
$   if (p4 .eqs. "Z") then @ez:make__tmat.com	'__tmat_filename' "ROT_Z:0"
$
$   @ez:transform.com	 	'__roi_filename' '__tmat_filename' '__tmp_filename' 0 0
$   @ez:get__geometry.com	'__tmp_filename' 'p3' __tmp 
$   @ez:set__header.com		'__tmp_filename' '__rot_filename' 0,0,0 0,0,0 
$   @ez:get__geometry.com	'__rot_filename' 'p3' __rot 
$
$   @ez:xray.com	          	'__rot_filename' '__xra_filename' 1 '__rot__dim_z'
$   @ez:abs_threshold.com	'__xra_filename' '__xrs_filename' 1 1000 127
$   @ez:togobj.com	        '__xrs_filename' '__xra_gobj' 0 0 5
$   @ez:scale__.com	      	'__xra_gobj' '__sca_gobj' 1 '__scale_vec' 1
$
$   ! canvas dimensions in rotated space
$   @ez:vector__make.com     __can__vec_dim '__rot__dim_x' '__rot__dim_y' '__dim_axis'    
$   @ez:create__aim.com	    '__can_filename' 0,0,0 '__can__vec_dim' 0,0,0 '__rot__vec_els'
$   @ez:apply_gobj.com	    '__can_filename' '__sca_gobj' '__rxt_filename' 0 0
$
$   @ez:set__header.com		'__rxt_filename' '__tmp_filename' '__tmp__vec_pos' '__tmp__vec_off'
$   @ez:transform.com	 	'__tmp_filename' '__tmat_filename' '__ext_filename' 0 1                   ! inverse matrix
$
$   ! final position in original space
$   if (p4 .eqs. "X") then @ez:vector__make.com   __ext__vec_pos '__pos_axis' '__org__pos_y' '__org__pos_z' 
$   if (p4 .eqs. "Y") then @ez:vector__make.com   __ext__vec_pos '__org__pos_x' '__pos_axis' '__org__pos_z' 
$   if (p4 .eqs. "Z") then @ez:vector__make.com   __ext__vec_pos '__org__pos_x' '__org__pos_y' '__pos_axis' 
$   @ez:set__header.com		'__ext_filename' '__ext_filename' '__ext__vec_pos' '__org__vec_off' 
$   @ez:togobj.com	        '__ext_filename'  'p2' 0 0 5
$
$
$   del/log '__tmp_filename';*
$   del/log '__roi_filename';*
$   del/log '__rot_filename';*
$   del/log '__xra_filename';*
$   del/log '__xrs_filename';*
$   del/log '__xra_gobj';*
$   del/log '__sca_gobj';*
$   del/log '__rxt_filename';*
$   del/log '__ext_filename';*
$   del/log '__can_filename';*
$   del/log '__tmat_filename';*
$
$ say "!!  "
$ say "!! EXTRUDE__GOBJ.COM: completed"
$ say "=========================================================="
$ exit
$!
$ terminate:
$   say "!! Description:"
$   say "!!  Extrude a GOBJ along an axis"
$   say "!!  P1: GOBJ filename"
$   say "!!  P2: GOBJ output filename"
$   say "!!  P3: LOG file"
$   say "!!  P4: axis (X,Y or Z),
$   say "!!  P6: position, dimension (eg. 10,100) along proj axis"
$  exit
$
