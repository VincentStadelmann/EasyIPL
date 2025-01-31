$!************************* EZ_IPL *****************************************           
$! INIT.COM
$!
$!  Written by: Vincent Stadelmann 2018.10.16
$!  Copyright (c) 2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! 
$! USAGE:
$!   @ez:init.com 
$!
$! DESCRIPTION:
$!  Initializes common EZ parameters
$!
$!***************************************************************************            
$
$ say   ==  "write sys$output "
$ icalc ==  "$ut:icalc.exe"
$
$ on error then exit
$ set output_rate=00:00:01
$ wait 00:00:01
$
$ exit