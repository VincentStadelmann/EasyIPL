$!************************* EZ_IPL *****************************************           
$! VECTOR__INIT.COM
$!
$!  Written by: Vincent Stadelmann 2018.11.21
$!  Copyright (c) 2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! 
$! USAGE:
$!   @ez:vector__init.com 
$!
$! DESCRIPTION:
$!  Initializes common parameters for vector__ 
$!
$!***************************************************************************            
$
$ say      ==  "write sys$output "
$
$! maths with float
$ icalc    ==  "$ut:icalc.exe"
$
$! silence icalc
$ ic_nolog ==  "define/user/nolog sys$output nla0: "    
$
$ exit