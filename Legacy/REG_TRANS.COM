$!*************************************************            
$! REG_TRANS.COM
$! 2012.08.13 V. Stadelmann
$! 
$! USAGE:
$!   @ue:REG_TRANS.COM	 'input_filename' 'ref_filename' 'tmat.dat_filename' 'reg_filename' 'scaling' 'tolerance' 'correlation' 'init'
$! 
$! Version history:
$!   - 2016.12.15 : still using IPLREG_BATCH for Davos IPL_BATCH for others
$!
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! REG_TRANS.COM	"
$ say "=========================================================="
$!*
$!
$   show symbol p1
$   show symbol p2
$   show symbol p3
$   show symbol p4
$   show symbol p5
$   show symbol p6
$   show symbol p7
$   show symbol p8
$!
$ say "!! Processing inputs..."
$ 	reg_verif = p1 - ".AIM" + "_REG_VERIF.AIM"
$   show symbol reg_verif
$! 
$  if p5 .eqs. "" 
$  	then 
$   	ipl_scale_1 = "10"
$   	ipl_scale_2 = "4"
$   	ipl_scale_3 = "1"
$  endif
$!
$  if p5 .nes. "" 
$  	then 
$   	ipl_scale_1 = f$element(0,".",p5)
$   	ipl_scale_2 = f$element(1,".",p5)
$   	ipl_scale_3 = f$element(2,".",p5)
$  endif
$!
$  if p6 .eqs. "" 
$  	then 
$   	p6 := 0.0001
$  endif
$!
$  if p7 .eqs. "" 
$  	then 
$   	p7 := 0.5
$  endif
$!
$  if p8 .eqs. "" 
$  	then 
$   	p8 = 0
$  endif
$!
$   show symbol p1
$   show symbol p2
$   show symbol p3
$   show symbol p4
$   show symbol p5
$   show symbol p6
$   show symbol p7
$   show symbol p8
$  	show symbol ipl_scale_*
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
  -orientation_search        "P8
  -initial_rotation          0.000 0.000 0.000
  -initial_translation       0.000 0.000 0.000
  -delta_rotation            0.100 0.100 0.500
  -delta_translation         0.100 0.100 0.500
  -resolution_scaling        "ipl_scale_1 "ipl_scale_2 "ipl_scale_3
  -delta_scaling             1.000 0.100 0.100
  -tolerance                 "P6
  -min_corr_coef             "P7
  -min_method                1
  -object_func               1
  -max_nr_iter               3000
  -output_option             2 
 ..
$!
$! Apply transformation 
$ ipl_batch

/read
  -name                      ref
  -filename                  "P2
  
/read
  -name                      org
  -filename                  "P1
  
/transform
  -in                        org
  -out                       reg
  -Tmat_file_name            "P3
  -img_interpol_option       1
  -el_size_mm_out            -1.000 -1.000 -1.000

/delete
  -name                      org 

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
$ say "!! REG_TRANS.COM: Completed	"
$ say "=========================================================="
$ exit
