$!****************************************************************************************            
$! GET_GEOMETRY.COM
$! 
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! VERSION HISTORY:
$!  2016.11.29 Created
$! 
$! DESCRIPTION:
$!  Gets AIM geometry data 
$! 
$! USAGE:
$!  @'scripts_dir'get_geometry.com	'aim_filename' 'log_filename' 'skip'
$!
$! PARAMETERS:
$!
$!****************************************************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! GET_GEOMETRY.COM:	"
$ say "=========================================================="
$!*
$!
$ show symbol p1
$ show symbol p2
$ show symbol p3
$!
$ if p3 .eqs. "" then skip := ""
$ if p3 .nes. "" then skip := "/skip=''p3'"
$ if p3 .eqs. "0" then skip := ""
$ sh sym skip
$!
$ IPL_BATCH

/read
  -name                      in
  -filename                  "p1

/examine
  	-input                   in
  	-item                    geometry    
	
..	
$! Extract dimensions from logfile
$ set output_rate=00:00:01
$ wait 00:00:02 
$!
$! Search for dim
$ pipe search 'p2' "!> dim  " 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimdim = line_sym - "!> dim   "
$ aimdim = f$edit(aimdim,"trim,compress")
$!
$! Search for pos
$ pipe search 'p2' "!> pos  " 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimpos = line_sym - "!> pos   "
$ aimpos = f$edit(aimpos,"trim,compress")  
$!
$! Search for el size
$ pipe search 'p2' "!> element size in mm" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimelsize = line_sym - "!> element size in mm "
$ aimelsize = f$edit(aimelsize,"trim,compress")  
$!
$  pos_x == f$element(0," ",aimpos)
$  pos_y == f$element(1," ",aimpos)
$  pos_z == f$element(2," ",aimpos)
$  dim_x == f$element(0," ",aimdim)
$  dim_y == f$element(1," ",aimdim)
$  dim_z == f$element(2," ",aimdim)
$  elsize_x == f$element(0," ",aimelsize)
$  elsize_y == f$element(1," ",aimelsize)
$  elsize_z == f$element(2," ",aimelsize)
$!
$  sh sym pos*
$  sh sym dim* 
$  sh sym elsize* 
$!
$ say " "
$ say "!! GET_GEOMETRY.COM: completed"
$ say "=========================================================="
$ exit
