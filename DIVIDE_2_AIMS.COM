$!***************************************************************************           
$! DIVIDE_2_AIMS.COM
$! 2018.06.18 V. Stadelmann
$! 
$! USAGE:
$!   @ue:DIVIDE_2_AIMS.com	'aim1_filename' 'aim2_filename' 'div_filename' common?*'
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! DIVIDE_2_AIMS.COM: "
$ say "=========================================================="
$!*
$
$  	if p1 .eqs. "" then goto terminate
$  	if p2 .eqs. "" then goto terminate
$  	if p3 .eqs. "" then goto terminate
$  	if p4 .eqs. "0" then p4 = "FALSE"
$  	if p4 .nes. "FALSE" then p4 = "TRUE"
$
$   SHOW SYMBOL P1
$   SHOW SYMBOL P2
$   SHOW SYMBOL P3
$   SHOW SYMBOL P4
$!
$ IPL_BATCH

/read
  -name                      aim1
  -filename                  "P1

/read
  -name                      aim2
  -filename                  "P2
  
/divide_volumes
  -input1                    aim1
  -input2                    aim2
  -output                    div
  -common_region_only        "p4

  	
/write
  -name                      div
  -filename                  "P3
  -compress_type             bin
  -version_020               true

..
$ say "!! DIVIDE_2_AIMS.COM: completed."
$ say "=========================================================="
$ exit
$ terminate:
$ say "  P1 : AIM1 NAME"
$ say "  P2 : AIM2 NAME"
$ say "  P3 : AIM1/AIM2 NAME"
$ say "  P4 : Common only? (1*/0)"
$ exit
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
