$!************************* EZ_IPL *****************************************    
$!       
$! EZ_TEMPLATE.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2017.08.24
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! USAGE:
$!  Describe function here
$!
$! PARAMETERS:
$!  P1 : parameter 1 description
$!  P2*: parameter 2 description (*default value)
$!
$! USAGE:
$!  @ez:ez_template.com  p1 p2   
$!
$! VERSION HISTORY:
$!  2018.10.22 Describe changes
$!
$!***************************************************************************            
$!
$! say = "write sys$output"
$! say "  "
$! say "=========================================================="
$! say "!! EZ_TEMPLATE.COM:  "
$! say "=========================================================="
$
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_EZ.AIM"
$
$ show symbol p1
$ show symbol p2
$!
$! Do something
$!
$!#
$ say "!! EZ_TEMPLATE.COM: Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper EZ_TEMPLATE.com
$ exit