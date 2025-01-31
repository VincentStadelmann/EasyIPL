$!*************************************************
$! EXTRUDE__XRAY.COM
$!  2018.06.12 VStadelmann
$!
$! Description:
$! 	Extrude an 1-slice AIM (eg. x-ray) along an axis
$!  P1: AIM filename
$!  P2: AIM output filename
$!  P3: LOG file
$!  P4: axis
$!  P5: dimensions vector (pos,dim)
$!
$! USAGE:
$!  @ue:EXTRUDE__XRAY.com	'input' 'output' 'log_filename' 'dim_vec'
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
$ say "!!		EXTRUDE__XRAY.COM      	     	  "
$ say "=========================================================="
$!*
$!
$!  ====================   Filenames   ====================================
$!
$! Parse input
$ 	if (p1 .eqs. "") then goto terminate
$ 	if (p2 .eqs. "") then goto terminate
$ 	if (p3 .eqs. "") then goto terminate
$ 	if (p4 .eqs. "") then goto terminate
$
$   show symbol p1
$   show symbol p2
$   show symbol p3
$   show symbol p4
$
$! Define intermediate filename
$   __tmp_filename  = p1 - ".AIM" + "___TMP.AIM"
$!
$!  ====================  Script body  ====================================
$!
$! Check if p5 is vector
$ if (f$locate(",", p4) .lt. f$length(p4))
$ 	then
$   	__out__pos_z   = f$element(0,",",p4)
$   	__out__dim_z   = f$element(1,",",p4)
$ 	else
$       goto terminate
$ endif
$
$   @ez:get__geometry.com	'p1' 'p3' __org
$   @ez:scale__.com	      	'p1' '__tmp_filename' 1 1,1,'__out__dim_z' 0
$   @ez:set__header.com		'__tmp_filename' 'p2' '__org__pos_x','__org__pos_y','__out__pos_z' -1,-1,-1 '__org__els_x','__org__els_y','__org__els_z'
$
$ del '__tmp_filename';*
$ say "!!  "
$ say "!! EXTRUDE__XRAY.COM: completed"
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
$   say "!!  P5: position, dimension (eg. 10,100) along proj axis"
$  exit
$
