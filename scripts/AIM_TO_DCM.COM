$!*************************************** Easy_IPL *****************************************           
$!
$! AIM_TO_DCM.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2011.09.20
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Exports dicoms (.DCM) from AIM file
$! 
$! USAGE:
$!   @ez:aim_to_dcm.com	'aim_filename' 'dcm_filename'
$! 
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2* : Output dicom file (*filename+.DCM)
$!  P3* : Global slice nb in name (true/*false)
$!
$! EXAMPLE:
$!  Transform image.aim into a series of dicoms files in scratch directory
$!  @ez:aim_to_dcm.com image.aim sys$scratch:image.dcm 
$!
$! VERSION HISTORY:
$!  2016.11.03 Checking inputs
$!  2018.10.17 EZ format
$!  2018.10.18 Added global slice nb
$!
$!******************************************************************************************           
$
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! AIM_TO_DCM.COM:  "
$ say "=========================================================="
$!*
$  	if (p1 .eqs. "") then goto terminate
$  	if (p2 .eqs. "") then p2  = p1 - ".AIM"
$  	if (p3 .eqs. "") then p3 := false
$
$!
$ IPL_BATCH

/read
  -name                      in
  -filename                  "p1

/todicom_from_aim
  -aim_name                  in
  -dicom_filename            "p2
  -multifiles                true
  -global_slicename          "p3
  
..
$!#
$ say "!! AIM_TO_DCM.COM:	Completed "
$ say "=========================================================="
$ exit
$!
$ terminate:
$  @ez:helper AIM_TO_DCM.com
$ exit