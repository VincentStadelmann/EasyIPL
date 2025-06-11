$!************************* EZ_IPL *****************************************           
$!
$! REGISTER.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2012.08.13
$!  Copyright (c) 2011-2019 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Register an AIM to a reference AIM. Save transformation matrix and 
$!  apply to AIM to generate registered image. 
$!  Notes: 
$!    - max iterations: 3000
$!    - Minimalization method: Simplex, 
$!    - For partial reg, GOBJs have to be applied first
$!    - Registered file may be in a negative position, ie. will crash visualizer 
$!    - A verif file is generated with pos > 0 for visualization 
$!
$!
$! Parameters:
$!   - tolerance: Stop criterion for the minimization procedure (eg. 0.01)
$!   - minimum_correlation: Min. value for correlation coeff.   (eg. 0.5)
$!   - orientation: 0=none; 1=masscenter; 2= masscenter+MoI; 
$!                  3=90 deg; 4=45 deg; 5=22.5 deg intervals
$! 
$! USAGE:
$!   @ez:register 'aim_file' 'ref_file' 'tmat_file' 'reg_file' 'scaling' 'reg_params' 'interpol'
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2  : Reference AIM file   
$!  P3  : Output transormation matrix               
$!  P4  : Output registered AIM    (if 'NONE' no output)           
$!  P5* : Scaling sequence (coarse to fine)  (*10,4,1)  
$!  P6* : Parameters:                        (*0.001,0.5,5)
$!        format: tolerance,minimum_correlation,orientation
$!  P7* : Interpolate ?                      (*true/false)
$!
$! EXAMPLE:
$!   
$!
$! VERSION HISTORY:
$!  2012.08.13 V. Stadelmann
$!  2018.01.17 Vector format
$!  2018.01.17 Test inputs
$!  2019.03.18 EZ format
$!  2023.03.18 Added option "NONE" for P4
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! REGISTER.COM:  "
$ say "=========================================================="
$!*
$
$! Check inputs
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then goto terminate
$  if (p3 .eqs. "") then goto terminate
$  if (p4 .eqs. "") then goto terminate
$  if (p5 .eqs. "") then p5 = "10,4,1"
$  if (p6 .eqs. "") then p6 = "0.001,0.5,5"
$  if (p7 .eqs. "0") then p7 = "FALSE"
$  if (p7 .nes. "FALSE") then p7 = "TRUE"
$
$  ! Interpolate is 0, 1 or 2, here we use only 0 and 1. 
$  if (p7 .eqs. "TRUE") then __t_interpol_opt := 1
$  if (p7 .nes. "TRUE") then __t_interpol_opt := 0

$
$  __r_reg_verif = p1 - ".AIM" + "__reg__verif.aim"
$
$! Parsing
$   @ez:vector__parse 'p5' __r_reg_scale
$   if (__r_reg_scale__h .nes. "V") 
$ 	then 
$       say "!! WARNING: reg_scale (p5) wrongly defined: ''p5'"
$       say "!! Using ""10,4,1"" instead... "
$       @ez:vector__parse "10,4,1"  __r_reg_scale
$   endif
$
$   @ez:vector__parse 'p6' __r_params
$   if (__r_params__h .nes. "V") 
$ 	then 
$       say "!! Warning: reg_params (p6) wrongly defined: ''p6'"
$       say "!! Using ""0.001,0.5,5"" instead... "
$       @ez:vector__parse "0.001,0.5,5"  __r_params
$   endif
$
$! Write transform image or not?
$  if (p4 .nes. "NONE")
$    then 
$      __r_write_reg = "/write reg ''p4' "
$    else 
$      __r_write_reg = "!! do not write reg file"
$  endif
$
$  show symbol p1
$  show symbol p2
$  show symbol p3
$  show symbol p4
$  show symbol p5
$  show symbol p6
$  show symbol p7
$  show symbol __r_*
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
  -Tmat_file_name            "p3
  -orientation_search        "__r_params__3
  -initial_rotation          0.000 0.000 0.000
  -initial_translation       0.000 0.000 0.000
  -delta_rotation            0.100 0.100 0.500
  -delta_translation         0.100 0.100 0.500
  -resolution_scaling        "__r_reg_scale__ipl
  -delta_scaling             1.000 0.100 0.100
  -tolerance                 "__r_params__1
  -min_corr_coef             "__r_params__2
  -min_method                1
  -object_func               1
  -max_nr_iter               3000
  -output_option             2 
  
/transform
  -in                        org
  -out                       reg
  -Tmat_file_name            "p3
  -img_interpol_option       "__t_interpol_opt
  -el_size_mm_out            -1.000 -1.000 -1.000

/add_aims
  -input1                    ref
  -input2                    reg
  -output                    out

/header_geo_set
  -input                     out
  -off_new                   0 0 0
  -pos_new                   0 0 0

/write
  -name                    	 out
  -filename                	 "__r_reg_verif
  -compress_type           	 bin
  -version_020             	 true

!! Write reg 
"__r_write_reg 

 ..
$
$
$ say "!! REGISTER.COM: Completed	"
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper register.com
$ exit