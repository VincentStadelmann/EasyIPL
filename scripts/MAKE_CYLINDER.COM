$!************************* EZ_IPL *****************************************           
$!
$! MAKE_CYLINDER.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2017.06.19
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Creates a plain cylinder 
$! 
$! USAGE:
$!  @ez:make_cylinder 'cyl_file' 'vec_dims' 'ref_type*' 'ref_pt*' 'units*' 'val*' 
$!
$! PARAMETERS:
$!   P1: Filename 
$!   P2*: Dimensions radius,height,elsize      (*1,2,1)                      
$!   P3*: Reference type (*center/base/corner) (*center)
$!   P4*: Reference coordinates                (*r,r,h/2)
$!   P5*: Units (mm/vx)                        (*mm)
$!   P6*: Value                                (*127) 
$!
$! EXAMPLE:
$!   Create a cylinder of radius=2mm height=10mm 
$!   with its base centered at 5mm,5mm,0mm
$!   and with a voxel size of 0.1mm 
$!   @ez:make_cylinder.com	cylinder.aim 2,10,0.1 base 5,5,0
$!
$! VERSION HISTORY:
$!  2018.04.24 vec format + input testing
$!  2018.11.20 EZ format, new params order
$!  2018.11.20 New name
$!  2022.11.10 Margins only in x,y
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! MAKE_CYLINDER.COM:  "
$ say "=========================================================="
$!*
$! Test inputs
$   if (p1 .eqs. "") then goto terminate
$   if (p2 .eqs. "") then p2 = "1,2,1"
$   ! p4 below
$   if (p3 .eqs. "") then p3 = "CENTER"
$   if (p5 .nes. "VX") then p5 = "MM"
$   if (p6 .eqs. "") then p6 = 127
$
$! Show inputs
$  j = 0
$  pj_loop:
$    j = j + 1
$    show symbol p'j'
$    if (j .lt. 6) then goto pj_loop
$
$! Parse inputs
$   @ez:vector__parse 'p2' __cyl_dimensions
$   if (__cyl_dimensions__h .nes. "V") then goto terminate 
$
$   if (p4 .eqs. "") 
$     then 
$       if (p3 .eqs. "CENTER")
$         then 
$         !p4 = r,r,h/2 from p2
$         icalc '__cyl_dimensions__2'/2
$         p4 := '__cyl_dimensions__1','__cyl_dimensions__1','icalc_out'
$       else
$         say "!! BASE and CORNER options not implemented yet!!! "
$       endif
$   endif
$
$   @ez:vector__parse 'p4' __cyl_position
$   if (__cyl_position__h .nes. "V") then goto terminate 
$
$! El size
$   elsize_mm = __cyl_dimensions__3
$   icalc 1/'elsize_mm'
$   elsize_vx = icalc_out
$ 
$  if (__cyl_dimensions__1 .eqs. 0)  then goto terminate2
$  if (__cyl_dimensions__2 .eqs. 0)  then goto terminate2
$  if (__cyl_dimensions__3 .eqs. 0)  then goto terminate2
$
$! Unit conversions
$   if (p5 .eqs. "MM")
$    then
$     say "!! Convert mm to vx"
$     cyl_radius_mm   = __cyl_dimensions__1
$     cyl_height_mm   = __cyl_dimensions__2
$     cyl_position_mm = __cyl_position
$
$     icalc 'cyl_radius_mm' * 'elsize_vx'
$     cyl_radius_vx = icalc_out
$     icalc 'cyl_height_mm' * 'elsize_vx'
$     cyl_height_vx = icalc_out
$     @ez:vector__multiply.com  'cyl_position_mm' 'elsize_vx' cyl_position_vx
$   endif
$
$   if (p5 .eqs. "VX")
$    then
$     say "!! Convert vx to mm"
$     cyl_radius_vx   = __cyl_dimensions__1
$     cyl_height_vx   = __cyl_dimensions__2
$     cyl_position_vx = __cyl_position
$
$     icalc 'cyl_radius_vx' * 'elsize_mm'
$     cyl_radius_mm = icalc_out
$     icalc 'cyl_height_vx' * 'elsize_mm'
$     cyl_height_mm = icalc_out
$     @ez:vector__multiply.com  'cyl_position_vx' 'elsize_mm' cyl_position_mm
$   endif
$
$   sh sym cyl_*
$
$! Compute canvas size in voxels:
$   if (p3 .eqs. "CENTER")
$      then 
$         say " "
$         say "!! Compute canvas dimensions and position with reference=CENTER"
$         say "!! Canvas dimensions = 2 r x 2 r x height (+2*margins)"
$         icalc 2 * 'cyl_radius_vx'
$         canvas_dim_xy = icalc_out
$         @ez:vector__make.com 	canvas_dim 'canvas_dim_xy' 'canvas_dim_xy' 'cyl_height_vx'
$         @ez:vector__make.com 	vec_margin 4 4 0
$         @ez:vector__floor.com	'canvas_dim' canvas_dim_vx
$         @ez:vector__add.com 	'canvas_dim_vx' 'vec_margin'  canvas_dim_vx
$
$         say "!! Canvas position = center_x - r, center_y - r, center_z - h/2 (-1 margin)"
$         say "!! Compute h/2: "
$         icalc floor('cyl_height_vx'/2)
$         cyl_halfheight_vx = icalc_out
$         icalc 'cyl_height_mm'/2
$         cyl_halfheight_mm = icalc_out
$
$         @ez:vector__make.com 	canvas_delta_vx 'cyl_radius_vx' 'cyl_radius_vx' 'cyl_halfheight_vx'
$         @ez:vector__make.com 	vec_margin 2 2 0
$         @ez:vector__subtract.com 'cyl_position_vx' 'canvas_delta_vx' canvas_pos
$         @ez:vector__floor.com	'canvas_pos' canvas_pos_vx
$         @ez:vector__subtract.com 'canvas_pos_vx' 'vec_margin'  canvas_pos_vx
$ 
$         say "!! Cylinder base = center_x , center_y , center_z - h/2 "
$         @ez:vector__make.com 	base_delta_mm 0 0 'cyl_halfheight_mm'
$         @ez:vector__subtract.com 'cyl_position_mm' 'base_delta_mm' cyl_base_mm
$      else
$        say "!! BASE and CORNER options not implemented yet!!! "
$   endif
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
  -value                     "p6
  -mode                      0

/write_v020
  -name                      in
  -filename                  "p1
  -compress_type             bin
  -version_020               true

..
$!#
$ say "!! MAKE_CYLINDER.COM:	Completed "
$ say "=========================================================="
$ exit
$!
$ terminate:
$   @ez:helper MAKE_CYLINDER
$   exit
$
$ terminate2:
$	say "!! Cylinder of radius 0 or height 0 not possible"
$   exit