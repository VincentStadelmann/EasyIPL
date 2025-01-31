$!*************************************************            
$! CONVERT_TO_TIF.COM
$!  2017.11.06 V. Stadelmann, 
$!    based on UCT_EVALUATION_V6_CONVERT by A. Laib
$! 
$! USAGE:
$!  Convert to image type
$!  @ue:convert_to_tif.com	'aim_filename' 'export_filename' 'from_slice' 'to_slice' 'n_slices' 'scale' 'global_pos (1/0*)' 'max (32000)'
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! CONVERT_TO_TIF.COM:	Converts to image type "
$ say "=========================================================="
$!*
$!
$
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 = p1 - ".AIM"
$ if (p3 .eqs. "") then p3 = 0 ! from slice
$ if (p4 .eqs. "") then p4 = 1 ! to slice
$ if (p5 .eqs. "") then p5 = 1 ! nslice
$ if (p6 .eqs. "") then p6 = 1 ! scale
$ if (p7 .eqs. "") then p7 = 0 ! global
$ if (p8 .eqs. "") then p8 = " "
$
$ p2 = p2 - ".TIF"
$
$ show symbol p1 
$ show symbol p2 
$ show symbol p3 
$ show symbol p4
$ show symbol p5 
$ show symbol p6 
$ show symbol p7 
$ show symbol p8
$!
$ tmp_convert_filename = p1 - ".AIM" + "_TMP_CONVERT.COM"
$ sh sym tmp_convert_filename
$
$ open/write outfile 'tmp_convert_filename'
$
$ write outfile "$!"
$ write outfile "$! Starting Conversion"
$ write outfile "$!"
$ write outfile "$ RUN UT:SEQ_TO_IMAGE.EXE"
$ write/symbol outfile P1
$ write/symbol outfile "TIF"
$ write/symbol outfile P2
$ write/symbol outfile P3
$ write/symbol outfile P4
$ write/symbol outfile P5
$ write/symbol outfile P6
$ write/symbol outfile P7
$ write/symbol outfile P8
$ close outfile 
$ @'tmp_convert_filename'
$! del 'tmp_convert_filename';*
$!
$!
$ say "!! CONVERT_TO_TIF.COM:	Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  say "!! P1 : name of input file"
$  say "!! P2 : name of output file"
$  say "!! P3 : slice min "
$  say "!! P4 : slice max"
$  say "!! P5 : n slices"
$  say "!! P6 : scale"
$  say "!! P7 : global_pos (1/0*)"
$  say "!! P8 : norm max (32000*)"
$
$ exit
