$ say == "write sys$output "
$ on error then goto list_errors
$ say "=========================================================="
$ say "!!	FIBERS_GENERATOR.COM			"
$ say "!!	2017.10.03 - first draft		    "
$ say "!!			    "
$ say "!!	Usage:		    "
$ say "!!	P1: AIM name		    "
$ say "!!	P2: number of fibers		    "
$ say "!!	P3: min fiber length		    "
$ say "!!	P4: varia fiber length		    "
$ say "!!	P5: max fiber translation	    "
$ say "!!	P6: max rotation angle	    "
$ say "=========================================================="
$!
$   j = 0
$   pj_loop:
$    j = j + 1
$    sh sym p'j'
$    if (p'j' .eqs. "") then goto terminate1
$    if (j .lt. 6) then goto pj_loop
$
$   inquire dummy "Continue?" 
$
$!	Parse input
$   	filename 		= 	f$parse(p1,,,"name")
$   	location 		= 	f$parse(p1,,,"device") + f$parse(p1,,,"directory")
$!
$!  Directories:
$       coms            :== adisk1:[vincent.eval]
$!
$!  Filenames:
$   	isq_filename  	:== 'location''filename'.isq
$   	aim_filename  	:== 'location''filename'.aim
$   	tmp_filename  	:== 'location''filename'_tmp.aim
$       cyl_filename  	:== 'location''filename'_cyl.aim
$!
$!  Text files: 
$   	tmat_filename   :== 'location''filename'_tmat.dat
$   	stats_filename  :== 'location''filename'_stats.csv
$   	log_filename    :== 'location''filename'_fibers_gen.log
$
$!  Numerics:
$       num_fibers           = p2
$       min_fib_length       = p3
$       var_fib_length       = p4
$       max_fib_dx           = p5
$       max_rot_angle        = p6
$!
$       min_fib_radius      :== 7
$       var_fib_radius      :== 2
$!
$       vx_size             :== 0.003
$       tab                  == f$fao("!_")
$!
$!  Init stats table
$     open/write output_file 'stats_filename'
$     write output_file "FiberNo, Length, Radius, PosX, PosY, PosZ, RotX, RotY, RotZ"
$     close output_file
$
$!	Generate empty canvas:
$    @ez:create_canvas.com	'aim_filename' 0.0.0 1.1.1 0.0.0 'vx_size'
$
$! Loop n fibers:
$   nf = 1
$   loop_fib:
$
$     say " "
$     say "!! Loop N=''nf'"
$
$!	 Generate random numbers:
$     say " "
$     say "!! Generating random numbers:"
$     __ceil = var_fib_length
$     gosub rand 
$     cyl_length_vx = random + min_fib_length
$
$     __ceil = var_fib_radius
$     gosub rand 
$     fib_radius_vx = random + min_fib_radius
$
$     __ceil = max_rot_angle
$     gosub rand 
$     rot_angle_x = random
$     gosub rand 
$     rot_angle_y = random
$     gosub rand 
$     rot_angle_z = random
$
$     __ceil = max_fib_dx
$     gosub rand 
$     cyl_pos_x_vx = random
$     gosub rand 
$     cyl_pos_y_vx = random
$     gosub rand 
$     cyl_pos_z_vx = random
$
$     sh sym rot_angle_*
$     sh sym cyl_pos_*
$     sh sym cyl_length_vx
$
$    @ez:vector__make.com  		Vector_R 'rot_angle_x' 'rot_angle_y' 'rot_angle_z' 
$    @ez:vector__make.com  		Point_P_vx 'cyl_pos_x_vx' 'cyl_pos_y_vx' 'cyl_pos_z_vx' 
$    @ez:vector__multiply.com   'Point_P_vx' 'vx_size' Point_P_mm
$!
$!   Generate cylinder with random length 
$     @ez:vector__make.com  		Point_O 0 0 0 
$     @ez:create__cylinder.com	'cyl_filename' 'fib_radius_vx' 'Point_O' 'cyl_length_vx' 'vx_size' vx 1
$
$     say " "
$     say "!! Record numbers in table:"
$     open/append output_file 'stats_filename'
$     write output_file "''nf',''cyl_length_vx',''fib_radius_vx',''Point_P_vx',''Vector_R'"
$     close output_file
$     Say " "
$
$!   Create  transformation rotation then O -> P and apply to cylinder
$     say " "
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
$      @ez:transform.com	 'cyl_filename' 'tmat_filename' 'tmp_filename' 0 0   ! ROI of real defect diam
$!
$      @ez:add_2_aims.com    'tmp_filename' 'aim_filename' 'aim_filename'
$!
$      nf = nf + 1
$      purge 'aim_filename'
$      purge 'cyl_filename'
$      purge 'tmp_filename'
$      purge 'tmat_filename'
$
$  if(nf .lt. num_fibers) then goto loop_fib
$
$ @ez:set_header.com	'aim_filename' 'aim_filename' 0.0.0 0.0.0 -1.-1.-1
$
$
$ say "!!	FIBERS_GENERATOR.COM: Completed			"
$ say "=========================================================="
$ exit
$ terminate1:
$   say "!! Error: missing parameter"
$   exit
$!
$! RAND - returns a positive random number ("RANDOM") between 0 and __CEIL - 1. 
$! sharris-at-sdsdmvax.fb3.noaa.gov 
$ RAND: 
$ 
$ IF F$TYPE(__SEED) .EQS. "" 
$ THEN 
$     ! seed the random number generator, ... 
$     __NOW = F$CVTIME() 
$     __HOUR = 'F$EXTRACT(11,2,__NOW)' 
$     __MINUTE = 'F$EXTRACT(14,2,__NOW)' 
$     __SECOND = 'F$EXTRACT(17,2,__NOW)' 
$     __TICK = 'F$EXTRACT(20,2,__NOW)' 
$ 
$     __SEED == __TICK + (100 * __SECOND) + (6000 * __MINUTE) + (360000 * __HOUR) 
$     ! the generator tends to do better with a large, odd seed, ... 
$     __SEED == (__SEED .OR. 1) 
$     ! clean up, ... 
$     DELETEX/SYMBOL __NOW 
$     DELETEX/SYMBOL __HOUR 
$     DELETEX/SYMBOL __MINUTE 
$     DELETEX/SYMBOL __SECOND 
$     DELETEX/SYMBOL __TICK 
$ ENDIF 
$ 
$ IF F$TYPE(__CEIL) .EQS. "" THEN __CEIL = %X3FFFFFFF 
$ 
$ __SEED == __SEED * 69069 + 1 
$ 
$ RANDOM == (__SEED.AND.%X3FFFFFFF)/(%X40000000/__CEIL) 
$ 
$ RETURN 
