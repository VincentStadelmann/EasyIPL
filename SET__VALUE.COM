$!****************************************************************************************            
$! SET__VALUE.COM
$! 2012.06.07 V. Stadelmann
$! 
$! USAGE:
$!  @ue:set__value.com	'ipl_input' 'ipl_output' 'ipl_value_obj' 'ipl_value_bg'
$!
$! P1 : input aim file
$! P2 : output aim file
$! P3 : values object
$! P4 : value background
$!****************************************************************************************            
$!
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! SET__VALUE.COM:  "
$ say "=========================================================="
$!*
$!
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then goto terminate
$ if (p3 .eqs. "") then p3 = 127
$ if (p4 .eqs. "") then p4 = 0
$
$   show symbol p1
$   show symbol p2
$   show symbol p3
$   show symbol p4
$!
$!
$ IPL_BATCH

/read
  -name                      tmp
  -filename                  "P1
  
/set_value
  -input                     tmp
  -value_object              "P3
  -value_background          "P4

     
/write
  -name                      tmp
  -filename                  "P2
  -compress_type             bin
  -version_020               true    

..
$!
$ say "!! SET_VALUE.COM: Completed "
$ say "=========================================================="
$ exit
$ terminate:
$   say "!! P1 : input file"
$   say "!! P2 : output file"
$   say "!! P3 : object value (127*)"
$   say "!! P4 : background value (0*)"
$ exit
