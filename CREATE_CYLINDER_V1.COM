$!*************************************************            
$! CREATE_CYLINDER.COM
$! 2017.06.19 V Stadelmann
$! 
$! USAGE:
$! Creates a cylinder AIM 
$!  @'scripts_dir'create_cylinder.com	'cyl_filename' 'cyl_radius' 'cyl_center' 'cyl_height' 
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! CREATE_CYLINDER.COM:	Creates a cylinder AIM "
$ say "!!  - P1: Canvas Filename "
$ say "!!  - P2: Output Filename "
$ say "!!  - P3: Radius                      [mm]"
$ say "!!  - P4: Base circle center (sep=|)  [mm]"
$ say "!!  - P5: Height (default = 1)        [mm]"
$ say "=========================================================="
$!
$ show symbol p1 
$ show symbol p2 
$ show symbol p3 
$ show symbol p4
$ show symbol p5
$ show symbol p6
$!
$! Test inputs
$  cyl_radius_mm := 'p3'
$!
$! Parse center from inputs
$   if (f$locate("|", "''p4'") .lt. f$length("''p4'"))
$ 	  then 
$	    say "!! Parsing center from p4 list"
$       cyl_center_x_mm = f$element(0,"|",p4)
$       cyl_center_y_mm = f$element(1,"|",p4)
$       cyl_base_z_mm = f$element(2,"|",p4)
$   endif
$!
$   if (p5 .eqs. "")
$    then 
$	   say "!! Cylinder height by default = 1.00 [mm] "
$      cyl_height_mm := 1.00
$    else
$      cyl_height_mm := 'p5'
$   endif
$!
$   sh sym cyl_*
$!
$ IPL_BATCH

/read
  -name                      in
  -filename                  "p1
  
/cr_cylinder
  -input_output              in
  -center                    "cyl_center_x_mm "cyl_center_y_mm "cyl_base_z_mm
  -radius                    "cyl_radius_mm
  -length                    "cyl_height_mm
  -value                     127
  -mode                      0

/write_v020
  -name                      in
  -filename                  "p2
  -compress_type             bin
  -version_020               true

..
$ say "!! CREATE_CYLINDER.COM:	Completed "
$ say "=========================================================="
$ exit
