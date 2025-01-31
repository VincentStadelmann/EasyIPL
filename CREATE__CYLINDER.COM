$!*************************************************            
$! CREATE_CYLINDER.COM
$! 2017.06.19 V Stadelmann
$! 2018.04.24 VS new format ","
$! 
$! Description:
$! Creates a cylinder AIM (see below)
$!   P1: Filename 
$!   P2: Radius                      
$!   P3: Cyl center          (default=(r,r,r) )
$!   P4: Height              (default = 2r)        
$!   P5: Voxel size          (default = 1.00) 
$!   P6: Units (mm/vx)       (default = mm)
$!   P7: Value               (default = 127) 
$!
$! USAGE:
$!  @ez:create__cylinder.com	'cyl_filename' 'cyl_radius' 'cyl_center*' 'opt_cyl_height*' 'el_size*' 'units*' 'value*' 
$!*************************************************            
$!*
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! CREATE__CYLINDER.COM: "
$ say "=========================================================="
$!
$  if ("''coms'" .eqs. "") then coms = "ue:"
$  if (f$search("ez:vector__parse.com") .eqs. "") then goto terminate0
$  if (f$search("ez:vector__make.com") .eqs. "") then goto terminate0
$!
$! Test inputs
$  j = 0
$  pj_loop1:
$    j = j + 1
$    show symbol p'j'
$    if (p'j' .eqs. "") then goto terminate1
$    if (j .lt. 2) then goto pj_loop1
$  pj_loop2:
$    j = j + 1
$    show symbol p'j'
$    if (j .lt. 7) then goto pj_loop2
$!
$  if (p2 .eqs. 0)  then goto terminate2
$  if (p3 .eqs. "") then p3 := 'p2','p2','p2'
$  if (p4 .eqs. "") 
$    then 
$      icalc 2 * 'p2'
$      p4 = icalc_out
$  endif
$  if (p5 .eqs. "") then p5  = 1
$  if (p6 .eqs. "") then p6 := MM
$  if (p6 .nes. "MM" .and. p6 .nes. "VX") then goto terminate3
$  if (p7 .eqs. "") then p7  = 127
$
$! Parse inputs
$   say "!! Conversion factor 1/elsize_mm :"
$   elsize_mm = p5
$   icalc 1/'elsize_mm'
$   elsize_vx = icalc_out
$
$! Convert units
$   if (p6 .eqs. "MM")
$    then
$     say "!! Convert mm to vx"
$     cyl_radius_mm = p2
$     cyl_height_mm = p4
$     @ez:vector__parse.com  'p3' cyl_center_mm
$
$     icalc 'cyl_radius_mm' * 'elsize_vx'
$     cyl_radius_vx = icalc_out
$     icalc 'cyl_height_mm' * 'elsize_vx'
$     cyl_height_vx = icalc_out
$     @ez:vector__multiply.com  'cyl_center_mm' 'elsize_vx' cyl_center_vx
$   endif
$!
$   if (p6 .eqs. "VX")
$    then
$     say "!! Convert vx to mm"
$     cyl_radius_vx = p2
$     cyl_height_vx = p4
$     @ez:vector__parse.com  'p3' cyl_center_vx
$
$     icalc 'cyl_radius_vx' * 'elsize_mm'
$     cyl_radius_mm = icalc_out
$     icalc 'cyl_height_vx' * 'elsize_mm'
$     cyl_height_mm = icalc_out
$     @ez:vector__multiply.com  'cyl_center_vx' 'elsize_mm' cyl_center_mm
$   endif
$
$   sh sym cyl_radius_*
$   sh sym cyl_height_*
$!
$! Compute canvas size in voxels:
$   say " "
$   say "!! Compute canvas dim and pos:"
$   say "!! Canvas dimensions = 2 r x 2 r x height (+2*margins)"
$   icalc 2 * 'cyl_radius_vx'
$   canvas_dim_xy = icalc_out
$   @ez:vector__make.com 	canvas_dim 'canvas_dim_xy' 'canvas_dim_xy' 'cyl_height_vx'
$   @ez:vector__make.com 	vec_margin 4 4 4
$   @ez:vector__floor.com	'canvas_dim' canvas_dim_vx
$   @ez:vector__add.com 	    'canvas_dim_vx' 'vec_margin'  canvas_dim_vx
$
$   say "!! Canvas position = center_x - r, center_y - r, center_z - h/2 (-1 margin)"
$   say "!! Compute h/2: "
$   icalc floor('cyl_height_vx'/2)
$   cyl_halfheight_vx = icalc_out
$   icalc 'cyl_height_mm'/2
$   cyl_halfheight_mm = icalc_out
$
$   @ez:vector__make.com 	canvas_delta_vx 'cyl_radius_vx' 'cyl_radius_vx' 'cyl_halfheight_vx'
$   @ez:vector__make.com 	vec_margin 2 2 2
$   @ez:vector__subtract.com 'cyl_center_vx' 'canvas_delta_vx' canvas_pos
$   @ez:vector__floor.com	'canvas_pos' canvas_pos_vx
$   @ez:vector__subtract.com 'canvas_pos_vx' 'vec_margin'  canvas_pos_vx
$ 
$   say "!! Cylinder base = center_x , center_y , center_z - h/2 "
$   @ez:vector__make.com 	base_delta_mm 0 0 'cyl_halfheight_mm'
$   @ez:vector__subtract.com 'cyl_center_mm' 'base_delta_mm' cyl_base_mm

$!
$ IPL_BATCH

/create_canvas
  -output                    in
  -dim                       "canvas_dim_vx__ipl
  -off                       0 0 0
  -pos                       "canvas_pos_vx__ipl
  -el_size_mm                "elsize_mm
  -type                      char

/cr_cylinder
  -input_output              in
  -center                    "cyl_base_mm__ipl
  -radius                    "cyl_radius_mm
  -length                    "cyl_height_mm
  -value                     "p7
  -mode                      0

/write_v020
  -name                      in
  -filename                  "p1
  -compress_type             bin
  -version_020               true

..
$ say "!! CREATE_CYLINDER.COM:	Completed "
$ say "=========================================================="
$ exit
$!
$ terminate0:
$   say "  "
$   say "!! Error: vector_floor.com requires vector__parse.com and vector__make.com in ''coms' "
$   exit
$ terminate1:
$   say "  "
$   say "P1: Filename "
$   say "P2: Radius    "                  
$   say "P3*: Cyl center  (default=r,r,r) "      
$   say "P4*: Height      (default=2r) "      
$   say "P5*: Voxel size  (default=1)"
$   say "P6*: Units       (MM*/VX)"
$   say "P7*: Value       (default = 127) "
$   exit
$ terminate2:
$	say "!! Cylinder of radius 0 not possible"
$   exit
$ terminate3:
$	say "!! Units must be ""MM"" or ""VX"" "
$   exit
