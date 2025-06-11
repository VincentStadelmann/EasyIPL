$!*************************************************            
$! MAKE_CYL_GOBJ.COM
$!  2017.06.19 VS                    
$!  2017.11.01 VS center Z is H/2    
$!  2017.11.03 VS standalone module     
$!
$! Description:
$! 	Creates a cylinder GOBJ 
$!  P1: ISQ filename
$!  P2: GOBJ output filename
$!  P3: LOG file
$!  P4: 
$!
$! USAGE:
$!  @ue:make_cyl_gobj.com	'isq_file' 'gobj_output' 'log_filename' 'ipl_support' 
$!
$!*************************************************            
$!


$ Incomplete !! Replace ipl_misc* in file by Px... 

$ exit
 
 
$ say == "write sys$output "
$ on error then exit
$ set output_rate=00:00:01
$ wait 00:00:01
$
$ say "=========================================================="
$ say "!!		MAKE_CYL_GOBJ.COM      	     	  "
$ say "=========================================================="
$!
$!  ====================   Filenames   ====================================
$!
$!	Parse input
$    show symbol p1
$    show symbol p2
$    show symbol p3
$!
$!  Define intermediate filename
$    cyl_filename  = p2 - ".GOBJ" + "_CYL_TMP.AIM"
$!
$!  ====================  Script body  ====================================
$!
$! Get ISQ headers and geometry
$   @ue:get__ctheader.com	'p1' 'p3' ISQ
$!
$  say "!! Converting units [voxels] <-> [mm]:"
$  sh sym ipl_misc1_*
$!
$! Radius:
$   if (ipl_misc1_1 .eqs. "") then goto terminate1
$   cyl_radius_mm = ipl_misc1_1
$   icalc floor('cyl_radius_mm'/'isq__voxel_size')
$   cyl_radius_vox = icalc_out
$   sh sym cyl_radius*
$
$! Verifying radius size compared to image diagonal
$   icalc floor((sqrt(2) * 'isq__dim_x')/2)
$   max_cyl_radius_vox = icalc_out
$   icalc 'max_cyl_radius_vox' * 'isq__voxel_size'
$   max_cyl_radius_mm = icalc_out
$   sh sym max_cyl_radius_*
$   if (cyl_radius_vox .gt. max_cyl_radius_vox) then goto terminate2
$!
$
$! Calculate Base:
$   if (f$locate(" ", "''ipl_misc1_0'") .lt. f$length("''ipl_misc1_0'"))
$ 	  then 
$       @ue:vector__make.com  Point_B 'ipl_misc1_0' 
$       cyl_base_z_vox = Point_B_3
$   else	
$	  say "!! Setting center at image center"
$     icalc floor('isq__dim_x' / 2)
$     cyl_center_x_vox = icalc_out
$     icalc floor('isq__dim_y' / 2)
$     cyl_center_y_vox = icalc_out
$     cyl_base_z_vox = 1
$     @ue:vector__make.com  Point_B 'cyl_center_x_vox' 'cyl_center_y_vox' 'cyl_base_z_vox'
$   endif
$!
$! Height:
$   max_cyl_height_vox = 'isq__dim_z' - ('cyl_base_z_vox'-1)
$   sh sym max_cyl_height_vox
$   if ('ipl_misc1_2' .gt. 0) 
$    then
$	    say "!! ipl_misc1_2 > 0"
$       if ('ipl_misc1_2' .gt. 'max_cyl_height_vox') 
$         then 
$           cyl_height_vox = max_cyl_height_vox
$         else
$           cyl_height_vox = ipl_misc1_2
$       endif
$    else 
$	    say "!! ipl_misc1_2 < 0"
$       cyl_height_vox = max_cyl_height_vox
$   endif
$   icalc 'cyl_height_vox' * 'isq__voxel_size'
$   cyl_height_mm == icalc_out
$   icalc 'cyl_height_vox' / 2
$   cyl_height_2 == icalc_out
$   sh sym cyl_height*
$
$! Center is at Base + H/2
$   @ue:vector__make.com  Vec_H2 0 0 'cyl_height_2'
$   @ue:vector__add.com  'Point_B' 'Vec_H2' Point_C
$!
$! Generate cylinder
$   @ue:create__cylinder.com	'ipl_fname0' 'cyl_radius_vox' 'Point_C' 'cyl_height_vox' 'isq__voxel_size' vx 127
$   @ue:togobj.com	        	'ipl_fname0' 'ipl_fname1' 
$!
$ exit
$!
$ terminate1:
$   say "!! ipl_misc1_1 must be > 0 "
$   exit
$ terminate2:
$   say "!! Error: radius too large. Enter value in [mm]"
$   say "!! Maximum value for this ISQ: ''max_cyl_radius_mm' [mm]"
$   exit
