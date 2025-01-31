$!*************************************************            
$! MAKE__CYL_GOBJ_CENTER.COM
$!  2017.06.19 VS                    
$!  2017.11.01 VS center Z is H/2    
$!  2017.11.03 VS standalone module    
$!
$! Description:
$! 	Creates a cylinder GOBJ at center of radius P4 [mm]
$!  P1: ISQ filename
$!  P2: GOBJ output filename
$!  P3: LOG file
$!  P4: Cyl radius
$!  P5: Height
$!  P6: Z pos base
$!
$! USAGE:
$!  @ue:make__cyl_gobj_center.com	'isq_file' 'gobj_output' 'log_filename'  'radius' 'height' 'z_base'
$!
$!*************************************************            
$!
$ say == "write sys$output "
$ on error then exit
$ set output_rate=00:00:01
$ wait 00:00:01
$ icalc :== $ut:icalc.exe
$
$ say "=========================================================="
$ say "!!		MAKE__CYL_GOBJ_CENTER.COM      	     	  "
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
$ 	if (p4 .eqs. "") then goto terminate1
$ 	if (p5 .eqs. "") then p5 = 1
$!
$! Define intermediate filename
$   cyl_filename  = p2 - ".GOBJ" + "_CYL_TMP.AIM"
$!
$!  ====================  Script body  ====================================
$!
$! Get ISQ headers and geometry
$   @ue:get__ctheader.com	'p1' 'p3' ISQ
$!
$  say "!! Converting units [voxels] <-> [mm]:"
$!
$! Radius:
$   cyl_radius_mm = p4
$   icalc floor('cyl_radius_mm'/'isq__voxel_size')
$   cyl_radius_vox = icalc_out
$   sh sym cyl_radius*
$!
$! Calculate Cyl Base:
$	say "!! Setting center at image center"
$   icalc floor('isq__dim_x' / 2)
$   cyl_center_x_vox = icalc_out
$   icalc floor('isq__dim_y' / 2)
$   cyl_center_y_vox = icalc_out
$   icalc floor(('isq__dim_z'-'p5') / 2)
$   cyl_base_z_vox = icalc_out
$ 	if (p6 .nes. "") then cyl_base_z_vox = p6
$
$   @ue:vector__make.com  Point_B 'cyl_center_x_vox' 'cyl_center_y_vox' 'cyl_base_z_vox'
$!
$! Height:
$   max_cyl_height_vox = 'isq__dim_z' - 'cyl_base_z_vox'
$   sh sym max_cyl_height_vox
$   if (p5 .gt. 0) 
$    then
$	    say "!! p4 > 0"
$       if (p5 .gt. max_cyl_height_vox) 
$         then 
$           cyl_height_vox = max_cyl_height_vox
$         else
$           cyl_height_vox = p5
$       endif
$    else 
$	    say "!! p4 <= 0"
$       cyl_height_vox = max_cyl_height_vox
$   endif
$
$   icalc 'cyl_height_vox' * 'isq__voxel_size'
$   cyl_height_mm == icalc_out
$   icalc 'cyl_height_vox' / 2
$   cyl_height_half == icalc_out
$   sh sym cyl_height*
$
$! Center C is at B + H/2
$   @ue:vector__make.com  Vec_height_half 0 0 'cyl_height_half'
$   @ue:vector__add.com  'Point_B' 'Vec_height_half' Point_C
$!
$! Generate cylinder
$   @ue:create__cylinder.com	'cyl_filename' 'cyl_radius_vox' 'Point_C' 'cyl_height_vox' 'isq__voxel_size' vx 127
$   @ue:togobj.com	        	'cyl_filename' 'p2' 
$!
$ exit
$!
$ terminate:
$   say "!! Description:"
$   say "!! 	Creates a cylinder GOBJ at center of radius P4 [mm]"
$   say "!!  P1: ISQ filename"
$   say "!!  P2: GOBJ output filename"
$   say "!!  P3: LOG file"
$   say "!!  P4: Cyl radius [mm]"
$   say "!!  P5: Height [vx]"
$   say "!!  P6: Z pos base [vx]"
$
$ terminate1:
$   say "!! radius must be > 0 "
$   exit
