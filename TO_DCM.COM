$!*************************************************            
$! TO_DCM.COM
$! 2011.06.03 V. Stadelmann 
$! Mod 2015.02.16
$! 
$! Description
$!  exports dicoms from aim
$!
$! USAGE:
$!   @'scripts_dir'to_dcm.com	'aim_filename' 'dcm_filename'
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! TO_DCM.COM:  "
$ say "=========================================================="
$!*
$!
$ IPL_BATCH

/read
  -name                      in
  -filename                  "P1

/todicom_from_aim
  -aim_name                  in
  -dicom_filename            "P2
  -multifiles                true
  -global_slicename          false
  
..
$ exit
