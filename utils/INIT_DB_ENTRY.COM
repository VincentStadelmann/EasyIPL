$!************************* EZ_IPL *****************************************           
$!
$! INIT_DB_ENTRY.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.06.12
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Inititialize (reset) database entry for AIM
$! 
$! USAGE:
$!   @ez:init_db_entry.com 'input_filename' 
$!
$! PARAMETERS:
$!  P1 : Filename
$!
$! EXAMPLE:
$!  
$!
$! VERSION HISTORY:
$!  2019.03.20 EZ format
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! INIT_DB_ENTRY.COM: "
$ say "=========================================================="
$!*
$
$   if (p1 .eqs. "") then goto terminate
$   show symbol p1
$
$ 	ipl_batch

/read
  -name                      org
  -filename                  "p1

/db_scanco_activate true
/db_clear_eval org

..
$!#
$
$ 	say "!! INIT_DB_ENTRY.COM: Completed "
$ 	say "=========================================================="
$ 	exit
$
$ terminate:
$   @ez:helper INIT_DB_ENTRY.COM
$ exit
