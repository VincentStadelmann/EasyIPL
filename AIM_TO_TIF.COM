$!************************* EZ_IPL *****************************************           
$! AIM_TO_TIF.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2011.09.20
$!  Adapted from UCT_EVALUATION_V6_CONVERT by A. Laib
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$!
$!
$! DESCRIPTION:
$!  Convert to image type (Only TIF for the moment)
$! 
$! USAGE:
$!  @ez:aim_to_tif.com	'aim_filename' 'export_filename' 'from_slice' 'to_slice' 'n_slices' 'scale' 'global_pos (1/0*)' 'max (32000)'
$! 
$! DEPENDENCIES:
$!  UT:SEQ_TO_IMAGE.EXE
$! 
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2* : Output TIF file
$!  P3* : From slice nb (*0) 
$!  P4* : To slice nb (*all)
$!  P5* : Number of slices (*all)
$!  P6* : Scale factor (*1)
$!  P7* : Global position of slices? (true/*false)
$!  P8* : Norm max (32000*)
$!
$! EXAMPLE:
$!  Transform image.aim into a series of tif files in scratch directory
$!  @ez:aim_to_tif.com image.aim sys$scratch:image.tif 
$!
$! VERSION HISTORY:
$!  2018.10.18 EZ format
$!
$!***************************************************************************            
$
$ say " "
$ say "=========================================================="
$ say "!! AIM_TO_TIF.COM:	Converts to image type "
$ say "=========================================================="
$!*
$
$ say "!! Testing inputs"
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 = p1 - ".AIM"
$ if (p3 .eqs. "") then p3 = " " ! from slice
$ if (p4 .eqs. "") then p4 = " " ! to slice
$ if (p4 .eqs. "ALL") then p4 = " " ! to slice
$ if (p5 .eqs. "") then p5 = " " ! nslice
$ if (p5 .eqs. "ALL") then p5 = " " ! nslice
$ if (p6 .eqs. "") then p6 = " " ! scale
$ if (p7 .eqs. "") then p7 = " " ! global
$ if (p7 .eqs. "FALSE") then p7 = 0 ! global
$ if (p7 .eqs. "TRUE") then p7 = 1 ! global
$ if (p8 .eqs. "") then p8 = " " ! norm max
$
$ p2 = p2 - ".TIF" ! extension added by UT:SEQ_TO_IMAGE.EXE
$
$ show symbol p1 
$ show symbol p2 
$ show symbol p3 
$ show symbol p4
$ show symbol p5 
$ show symbol p6 
$ show symbol p7 
$ show symbol p8
$
$! create tmp comfile with conversion procedure
$ command_file = p1 - ".AIM" + "_TMP_TIF.COM"
$ sh sym command_file
$
$ open/write comfile 'command_file'
$ write comfile "$!"
$ write comfile "$! Starting Conversion"
$ write comfile "$!"
$ write comfile "$ RUN UT:SEQ_TO_IMAGE.EXE"
$ write/symbol comfile P1
$ write/symbol comfile "TIF"
$ write/symbol comfile P2
$ write/symbol comfile P3
$ write/symbol comfile P4
$ write/symbol comfile P5
$ write/symbol comfile P6
$ write/symbol comfile P7
$ write/symbol comfile P8
$ close comfile 
$ @'command_file'
$ del 'command_file';*
$
$ say "!! AIM_TO_TIF.COM:	Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper AIM_TO_TIF.com
$ exit