$!*************************************** Easy_IPL *****************************************           
$!
$! AIM_TO_STL.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2023.09.20
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Exports STL file (.STL) from AIM file
$! 
$! USAGE:
$!   @ez:aim_to_stl	'aim_filename' 'dcm_filename'
$! 
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2* : Output STL file (*filename+.STL)
$!  P3* : GOBJ filename   (*none)
$!
$! EXAMPLE:
$!  Transform image.aim into a image.stl in scratch directory
$!  @ez:aim_to_stl image.aim sys$scratch:image.stl 
$!
$! VERSION HISTORY:
$!  2023.09.20 Created
$!
$!******************************************************************************************           
$
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! AIM_TO_STL.COM:  "
$ say "=========================================================="
$!*
$  	if (p1 .eqs. "") then goto terminate
$  	if (p2 .eqs. "") then p2  = p1 - ".AIM" + ".STL"
$  	if (p3 .eqs. "") then p3 := none
$
$! Update get__tri_skip for compatibility with get_tri, get_tri_svth, ...
$   if ("''get__tri_skip'" .eqs. "") then get__tri_skip == 0
$   get__tri_skip == get__tri_skip + 1
$
$!
$ IPL_BATCH

/read
  -name                      in
  -filename                  "p1

/stl_tri
  -input                     in
  -output                    tri
  -stl_output_file           "p2
  -binary_file               true
  -stl_dre_tet_mode          0
  -gobj_filename             "p3
  
..
$!#
$ say "!! AIM_TO_STL.COM:	Completed "
$ say "=========================================================="
$ exit
$!
$ terminate:
$  @ez:helper AIM_TO_STL.com
$ exit