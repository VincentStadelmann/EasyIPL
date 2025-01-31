$!************************* EZ_IPL *****************************************           
$!
$! AIM_TO_3DTIF.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2016.02.05
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$!
$!
$! DESCRIPTION:
$!  Makes 3D rendering of AIM with preset file
$! 
$! USAGE:
$!   @ez:aim_to_3dtif.com	'aim_filename' 'tif_filename' 'preset_filename' 'vec_orientation' 'vec_light' 'size'
$! 
$! DEPENDENCIES:
$!  UCT_3D_BATCH == "$UM:UCT_RAY_BATCH.EXE"
$! 
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2* : Output 3D rendering TIF file (*.tif)
$!  P3* : Preset filename (*NONE)
$!  P4* : Vector_orientation (elevation/rotation *30,35)
$!  P5* : Vector_light (Ambient,Shadow *0.2,1)
$!  P6* : Image size (0...4096 *1024)
$!
$! EXAMPLE:
$!   Make a 3D rendering of seg.aim using the preset my_preset.aim
$!   @ez:aim_to_3dtif.com seg.aim sys$scratch:render.tif uu:my_preset.dat
$!
$! VERSION HISTORY:
$!  2018.10.18 Minor formatting
$!  2018.10.20 EZ__HELP
$!
$!***************************************************************************            
$!*
$ say " "
$ say "=========================================================="
$ say "!! AIM_TO_3DTIF.COM:  "
$ say "=========================================================="
$!*
$
$   say "!! Testing inputs"
$  	if (p1 .eqs. "") then goto terminate
$  	if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_3D.TIF"
$  	if (p3 .eqs. "") then p3 = "NONE"
$  	if (p4 .eqs. "") then p4 = "30,35"
$  	if (p5 .eqs. "") then p5 = "0.2,1"
$  	if (p6 .eqs. "") then p6 = "1024"
$
$   show symbol p1
$   show symbol p2
$   show symbol p3
$   show symbol p4
$   show symbol p5
$   show symbol p6
$   say " "
$
$!
$   if (p3 .eqs. "NONE")
$     then 
$       ! Option 1: with num parameters
$       say "!! Using numeric parameters"
$       command_file = p1 - ".AIM" + "_TMP_3DTIF.COM"
$       elevation = f$element(0,",",p4)
$       rotation  = f$element(1,",",p4)
$       ambient   = f$element(0,",",p5)
$       shadow    = f$element(1,",",p5)
$       im_size   = p6
$       show symbol elevation
$       show symbol rotation
$       show symbol ambient
$       show symbol shadow
$       show symbol im_size
$
$       open/write comfile 'command_file'
$       write comfile "$! Generating 3D View:"
$       write comfile "$ UCT_3D_BATCH "
$       write/symbol comfile p1
$       write/symbol comfile p2
$       write comfile "''ambient'"
$       write comfile "''shadow'"
$       write comfile "''im_size'"
$       write comfile "''elevation'"
$       write comfile "''rotation'"
$       write comfile "0"
$       write comfile "$!"
$       close comfile
$       @'command_file'
$       delete 'command_file';*
$
$     else
$      say "!! Using preset file ''p3'"
$      !Option 2: uct_3d_batch in line: 
$      !uct_3d_batch 'd3_preset_file' 'seg_filename' 'tif_filename'
$      uct_3d_batch 'p3' 'p1' 'p2'
$
$   endif
$
$!#
$ say "!! AIM_TO_3DTIF.COM: completed."
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper AIM_TO_3DTIF.com
$ exit