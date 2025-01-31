$!*************************************************            
$! REG__TRANS.COM
$! 2012.08.13 V. Stadelmann
$! 2018.01.17 VS vector format
$! 2018.01.17 check inputs
$! 
$! USAGE:
$!   @ue:reg__trans.com	 'input_filename' 'ref_filename' 'tmat.dat_filename' 'reg_filename' 'scaling_vec' 'tolerance,min_cor,orientation' 'interpol'
$!
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! REG__TRANS.COM	"
$ say "=========================================================="
$!*
$
$! check inputs
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then goto terminate
$  if (p3 .eqs. "") then p3 = p1 - ".AIM" + "_R.TMAT"
$  if (p4 .eqs. "") then p4 = p1 - ".AIM" + "_R.AIM"
$  if (p5 .eqs. "") then p5 = "10,4,1"
$  if (p6 .eqs. "") then p6 = "0.001,0.5,5"
$  if (p7 .eqs. "") then p7 = "0"
$!
$  reg_verif = p1 - ".AIM" + "_REG_VERIF.AIM"
$
$ if (f$locate(",", p5) .lt. f$length(p5))
$ 	then 
$   	reg_scale_1 = f$element(0,",",p5)
$   	reg_scale_2 = f$element(1,",",p5)
$   	reg_scale_3 = f$element(2,",",p5)
$		reg_scale := 'reg_scale_1' 'reg_scale_2' 'reg_scale_3'
$ 	else	
$       ! no comma 
$       say "!! Warning: reg_scale wrongly defined: ''p5', using ""10 4 1"" instead... "
$		reg_scale = "10 4 1" 
$ endif
$
$ if (f$locate(",", p6) .lt. f$length(p6))
$ 	then 
$   	reg_tolerance   = f$element(0,",",p6)
$   	reg_min_corr    = f$element(1,",",p6)
$   	reg_orientation = f$element(2,",",p6)
$ 	else	
$       ! no comma 
$       say "!! Warning: reg params vector (tol, cor_min, init) wrongly defined: ''p6' "
$       say "!! Using ""0.001,0.5,5"" instead... "
$   	reg_tolerance   = "0.001"
$   	reg_min_corr    = "0.5"
$   	reg_orientation = "5"
$ endif
$
$   show symbol p1
$   show symbol p2
$   show symbol p3
$   show symbol p4
$   show symbol p5
$   show symbol p6
$   show symbol p7
$   show symbol reg_*
$!
$ ipl_batch

/read
  -name                      org
  -filename                  "P1

/read
  -name                      ref
  -filename                  "P2
  
/register
  -in1                       ref
  -gobj_filename_in1         none
  -in2                       org
  -gobj_filename_in2         none
  -Tmat_file_name            "P3
  -orientation_search        "reg_orientation
  -initial_rotation          0.000 0.000 0.000
  -initial_translation       0.000 0.000 0.000
  -delta_rotation            0.100 0.100 0.500
  -delta_translation         0.100 0.100 0.500
  -resolution_scaling        "reg_scale
  -delta_scaling             1.000 0.100 0.100
  -tolerance                 "reg_tolerance
  -min_corr_coef             "reg_min_corr
  -min_method                1
  -object_func               1
  -max_nr_iter               3000
  -output_option             2 
 ..
$!
$! Apply transformation 
$ ipl_batch

/read
  -name                      org
  -filename                  "P1
  
/transform
  -in                        org
  -out                       reg
  -Tmat_file_name            "P3
  -img_interpol_option       "P7
  -el_size_mm_out            -1.000 -1.000 -1.000

/bounding_box_cut
  -input                     reg
  -output                    out
  -z_only                    false
  -border                    0 0 0

/write
  -name                      out
  -filename                  "P4
  -compress_type             bin
  -version_020               true
  
/delete
  -name                      reg 

/delete
  -name                      org 

/read
  -name                      ref
  -filename                  "P2

/add_aims
  -input1                    out
  -input2                    ref
  -output                    sum
  
/header_geo_set
  -input                     sum
  -off_new                   0 0 0
  -pos_new                   0 0 0
  -el_size_mm_new            -1.000 -1.000 -1.000

/write_v020
  -name                      sum
  -filename                  "reg_verif
  -compress_type             bin
  -version_020               true
  
..
$ say "!! REG__TRANS.COM: Completed	"
$ say "=========================================================="
$ exit
$ terminate:
$ say "!! P1 : name of input file"
$ say "!! P2 : name of reference file"
$ say "!! P3* : transformation matrix file "
$ say "!! P4* : registered file "
$ say "!! P5* : scaling vec (10,4,1)"
$ say "!! P6* : tolerance,min_corelation,orientation (0.001,0.5,5)"
$ say "!! P7* : interpolate transform (1/0*)"
$ exit
