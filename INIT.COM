$!************************* EZ_IPL *****************************************           
$! INIT.COM
$!
$!  Written by: Vincent Stadelmann 2018.10.16
$!  Copyright (c) 2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! 
$! USAGE:
$!   @ez:ez__init 
$!
$! DESCRIPTION:
$!  Initializes common EZ parameters
$!
$!***************************************************************************            
$!*
$ on error then exit
$
$! Define shortcut for user messages
$ say      == "write sys$output "
$
$! Define icalc for maths with float
$ icalc    ==  "$ut:icalc.exe"
$
$! Silence icalc
$ ic_nolog ==  "define/user/nolog sys$output nla0: "    
$
$! Define some numeric constants
$   vec_0 :== 0,0,0
$
$! Obsolete
$! coms    ==  "adisk1:[vincent.eval]"
$
$! Define flow rate to log file
$ set output_rate=00:00:01
$
$! Use uppercase filenames
$ set process/parse=traditional 
$
$! Wait a millisecond to let start log file
$ wait 00:00:01
$!#
$ exit