$!**************************************************************************************************                        
$! VECTOR__CREATE_TRANSFORM_MATRIX.COM
$! 2017.08.24 V. Stadelmann 
$! 
$! USAGE:
$!  Makes a vector 'p1' from coordinates 'ux uy uz'
$!  P1 : vector name
$!  P2 : coord x 
$!  P3 : coord y 
$!  P4 : coord z 
$!
$! USAGE:
$!   @'coms'vector__make.com  'vecname' 'vx' 'vy' 'vz'  
$!
$!**************************************************************************************************                        
$!
$ say = "write sys$output"
$ say "  "
$ say "=========================================================="
$ say "!! VECTOR__CREATE_TRANSFORM_MATRIX.COM  "
$ say "=========================================================="
$!
$

... in progress

$     say "!! Create transform matrix:"
$     open/write output_file 'tmat_filename'
$     write output_file "SCANCO TRANSFORMATION DATA VERSION: 10"
$     write output_file "ROT_X:''tab'''rot_angle_x'"                      
$     write output_file "ROT_Y:''tab'''rot_angle_y'"                      
$     write output_file "ROT_Z:''tab'''rot_angle_z'"                      
$     write output_file "TRANSLATE:''tab'''Point_P_mm__ipl'"    !   O->P translation
$     close output_file
$     Say " "
$     type 'tmat_filename'
$     Say " "
$
$!   Apply transform to cylinder
$      say " "
$      say "!! Apply transformation:"
$      @'coms'transform.com	 'cyl_filename' 'tmat_filename' 'tmp_filename' 0 0   ! ROI of real defect diam

see FIBERS_GENERATOR.COM
