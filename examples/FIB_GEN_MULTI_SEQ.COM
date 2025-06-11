$!  submit/notify/noprint/que=sys$fast/priority=101 ue:FIBERS_GENERATOR_MULTI_DIA.COM /params=(disk21:[vincent.data.00000105.00000282]a00000100.aim,100,200,0,500,0) /log=disk21:[vincent.data.00000105.00000282]a000000100_fib10.log 
$!  submit/notify/noprint/que=sys$fast/priority=101 ue:FIBERS_GENERATOR_MULTI_DIA.COM /params=(disk21:[vincent.data.00000105.00000282]a00000200.aim,100,200,0,500,0) /log=disk21:[vincent.data.00000105.00000282]a000000200_fib10.log 
$!  submit/notify/noprint/que=sys$fast/priority=101 ue:FIBERS_GENERATOR_MULTI_DIA.COM /params=(disk21:[vincent.data.00000105.00000282]a00000020.aim,20,200,0,500,0) /log=disk21:[vincent.data.00000105.00000282]a00000020_f.log 
$!  submit/notify/noprint/que=sys$fast/priority=101 ue:FIB_GEN_MULTI_SEQ.COM /params=(disk21:[vincent.data.00000105.00000282]a00000050.aim,50,10,0,3.5,0.067) /log=disk21:[vincent.data.00000105.00000282]a00000050_f.log 
$!
$!
$ say == "write sys$output "
$ on error then goto list_errors
$ set output_rate=00:00:01
$ wait 00:00:01
$ say "=========================================================="
$ say "!!	FIB_GEN_MULTI_SEQ.COM			"
$ say "!!	2017.10.03 - first draft		    "
$ say "!!	2017.11.01 - all diameters ordered		    "
$ say "!!			    "
$ say "!!	Usage:		    "
$ say "!!	P1: AIM name		    "
$ say "!!	P2: number of fibers		    "
$ say "!!	P3: fiber length		    "
$ say "!!	P4: min fiber diameter		    "
$ say "!!	P5: max fiber diameter	    "
$ say "!!	P6: voxel size	    "
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
$       dt_filename  	:== 'location''filename'_dt.aim
$!
$!  Text files: 
$   	tmat_filename   :== 'location''filename'_tmat.dat
$   	stats_filename  :== 'location''filename'_stats.csv
$   	log_filename    :== 'location''filename'_fibers_gen.log
$
$!  Numerics:
$       num_fibers           	= p2
$       fib_length_mm           = p3 ! mm
$       min_fib_radius_mm       = p4 ! mm
$       max_fib_radius_mm       = p5 ! mm
$       vx_size              	= p6 ! mm
$       tab                  	== f$fao("!_")
$!
$!  Init stats table
$     open/write output_file 'stats_filename'
$     write output_file "FiberNo, Length, Radius, PosX, PosY"
$     close output_file
$
$     say "!! Converting units:"
$     icalc 1/'vx_size'
$     vx_mm = icalc_out
$     @ez:vector__make.com  		Fib_dat_mm 'fib_length_mm' 'min_fib_radius_mm' 'max_fib_radius_mm' 
$     @ez:vector__multiply.com   'Fib_dat_mm' 'vx_mm' Fib_dat_vx
$     @ez:vector__floor.com      'Fib_dat_vx' Fib_dat_vx
$
$     icalc ('Fib_dat_mm_3'-'Fib_dat_mm_2')/'num_fibers'
$     dr_mm = icalc_out ! radius increment at each step of loop
$     icalc floor('dr_mm'/'vx_size')
$     dr_vx = icalc_out ! radius increment at each step of loop
$     sh sym dr_*
$	  if(dr_vx .eq. 0) then goto terminate0
$
$     
$     icalc floor('Fib_dat_vx_3'/2) + 1
$     cyl_pos_y_vx = icalc_out
$
$!	Generate empty canvas:
$    @ez:create_canvas.com	'aim_filename' 0.0.0 1.1.1 0.0.0 'vx_size'
$
$    previous_dia_vx = 0
$    y_row = 0
$
$! Loop n fibers:
$   nf = 0
$   loop_fib:
$
$     say " "
$     say "!! Loop N=''nf'"
$
$! Cyl center point
$     icalc 'Fib_dat_vx_3' - 'nf'*'dr_vx'
$     fib_radius_vx = icalc_out
$
$     icalc 'previous_dia_vx'+'fib_radius_vx' + 1
$     cyl_pos_x_vx = icalc_out
$     icalc 'previous_dia_vx'+2*('fib_radius_vx' + 1)
$     previous_dia_vx = icalc_out
$
$     icalc floor('Fib_dat_vx_1'/2) + 1
$     cyl_pos_z_vx = icalc_out
$
$     sh sym cyl_pos_*
$
$     @ez:vector__make.com  		Point_C_vx 'cyl_pos_x_vx' 'cyl_pos_y_vx' 'cyl_pos_z_vx' 
$     @ez:vector__multiply.com   'Point_C_vx' 'vx_size' Point_C_mm
$!
$!   Generate cylinder
$     @ez:vector__make.com  		Point_O 0 0 0 
$     @ez:create__cylinder.com	'cyl_filename' 'fib_radius_vx' 'Point_O' 'Fib_dat_vx_1' 'vx_size' vx 127
$
$     say " "
$     say "!! Record numbers in table:"
$     open/append output_file 'stats_filename'
$     write output_file "''nf',''Fib_dat_vx_1',''fib_radius_vx',''Point_C_vx'"
$     close output_file
$     Say " "
$
$!   Create  transformation rotation then O -> C and apply to cylinder
$     say " "
$     say "!! Create transform matrix:"
$     open/write output_file 'tmat_filename'
$     write output_file "SCANCO TRANSFORMATION DATA VERSION: 10"                  
$     write output_file "TRANSLATE:''tab'''Point_C_mm__ipl'"    !   O->C translation
$     close output_file
$     Say " "
$     type 'tmat_filename'
$     say " "
$     say "!! Apply transformation:"
$     @ez:transform.com	 'cyl_filename' 'tmat_filename' 'tmp_filename' 0 0   ! ROI of real defect diam
$!
$     @ez:add_2_aims.com    'tmp_filename' 'aim_filename' 'aim_filename'
$!
$     nf = nf + 1
$     y_row = y_row + 1
$	  if(y_row .eq. 10) ! every ten cyls move up one row, dy = 2r + 1
$		then 
$         icalc floor(3 * 'fib_radius_vx') + 1 + 'cyl_pos_y_vx'
$         cyl_pos_y_vx = icalc_out
$         previous_dia_vx = 0
$         y_row = 0
$	   endif
$
$!    Cleanup
$     purge 'aim_filename'
$     purge 'cyl_filename'
$     purge 'tmp_filename'
$     purge 'tmat_filename'
$
$  if(nf .lt. num_fibers) then goto loop_fib
$
$ @ez:set_header.com		'aim_filename' 'aim_filename' 0.0.0 0.0.0 -1.-1.-1
$ @ez:compute__dt_th.com	'aim_filename' 'dt_filename' 
$
$
$ say "!!	FIB_GEN_MULTI_SEQ.COM: Completed			"
$ say "=========================================================="
$ exit
$ terminate0:
$   say "!! Delta radius is 0 vx, choose less fibers of wider range"
$   exit
$
$ terminate1:
$   say "!! Error: missing parameter"
$   exit
$!
