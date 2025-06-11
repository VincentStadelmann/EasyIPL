$!**************************************************************************************************                        
$! ALIGN_IN_Z_COORD.COM
$! 2011.09.20 V. Stadelmann 
$! Mod 2014.04.02 HEADER, usage
$! Mod 2017.07.10 Accept "." or " " for coordinates separator (compatibility with uct_evaluation)
$! 
$! USAGE:
$! Aligns image based on coordinate matrix
$!  P1 : input AIM
$!  P2: output AIM
$!  P3 : Origin points
$!  P4 : OZ points
$!  P5 : OXZ points
$!  P6 : interpolation
$!
$! USAGE:
$!   @'scripts_dir'align_in_z_coord.com	'input_filename' 'out_filename' 'org1.org2.org3' 'oz1.oz2.oz3' 'oxz1.oxz2.oxz3' 'interpol'
$!**************************************************************************************************                        
$!*
$!
$ say = "write sys$output"
$ say ">>> "
$ say "=========================================================="
$ say "!! ALIGN_IN_Z_COORD.COM:  "
$ say "=========================================================="
$!
$! Test inputs
$   j = 0
$   pj_loop:
$    j = j + 1
$    show symbol p'j'
$    if (p'j' .eqs. "") then goto terminate
$    if (j .lt. 5) then goto pj_loop
$!
$  if (p6 .eqs. "") then p6 = 0
$!
$! Find out coordinates separator
$   if (f$locate(" ", "''p3'") .lt. f$length("''p3'")) then coord_sep = " "
$   if (f$locate(".", "''p3'") .lt. f$length("''p3'")) then coord_sep = "."
$   say "Coordinates separator:  ""''coord_sep'"" "
$   org1 = F$ELEMENT(0,"''coord_sep'",P3)
$   org2 = F$ELEMENT(1,"''coord_sep'",P3)
$   org3 = F$ELEMENT(2,"''coord_sep'",P3)
$   oz1  = F$ELEMENT(0,"''coord_sep'",P4)
$   oz2  = F$ELEMENT(1,"''coord_sep'",P4)
$   oz3  = F$ELEMENT(2,"''coord_sep'",P4)
$   oxz1 = F$ELEMENT(0,"''coord_sep'",P5)
$   oxz2 = F$ELEMENT(1,"''coord_sep'",P5)
$   oxz3 = F$ELEMENT(2,"''coord_sep'",P5)
$   say "Coordinates: "
$   sh sym org*
$   sh sym oz*
$   sh sym oxz*
$!
$ IPL_BATCH

/read
  -name                     in
  -filename                 "P1
  
/align_z
  -input					in
  -output					out
  -origin_point				"org1 "org2 "org3
  -z-axis_point				"oz1 "oz2 "oz3
  -xz-plane					"oxz1 "oxz2 "oxz3
  -img_interpol_option      "p6

/header_geo_set
  -input                     out
  -off_new                   0 0 0 
  -pos_new                   0 0 0 
  -el_size_mm_new            -1
  
/write
  -name                      out
  -filename                  "P2
  -compress_type             bin
  -version_020               true

..
$ say "!! ALIGN_IN_Z_COORD.COM:	Completed "
$ say "==========================================================" 
$ exit 
$!
$ terminate:
$ say "!!  P1 : input AIM  "
$ say "!!  P2 : output AIM  "
$ say "!!  P3 : Origin point (Px.Py.Pz or Px Py Pz) "
$ say "!!  P4 : OZ point coordinates "
$ say "!!  P5 : XZ point coordinates "
$ say "!!  P6 : interpolation (0*,1,2) "
$ exit
