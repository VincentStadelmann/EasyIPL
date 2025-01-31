$!****************************************************************************************            
$! SOBEL_GRADIENT.COM
$! 2018.01.15 V. Stadelmann
$! 
$! USAGE:
$!  @ue:sobel_gradient.com	'ipl_input' 'ipl_output' 
$!
$! P1 : input aim file
$! P2 : output aim file
$!****************************************************************************************            
$!
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! SOBEL_GRADIENT.COM:  "
$ say "=========================================================="
$!*
$!
$   show symbol p1
$   show symbol p2
$   show symbol p3
$   show symbol p4
$!
$!
$ IPL_BATCH

/read
  -name                      in
  -filename                  "P1
  
/sobel_grad
  -input                     in
  -output                    out
 
/write
  -name                      out
  -filename                  "P2
  -compress_type             bin
  -version_020               true    

..
$!
$ say "!! SOBEL_GRADIENT.COM: Completed "
$ say "=========================================================="
$ exit
