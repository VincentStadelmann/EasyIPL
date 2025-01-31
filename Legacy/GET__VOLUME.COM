$!****************************************************************************************            
$! GET__VOLUME.COM
$! 
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! VERSION HISTORY:
$!  2017.07.20
$! 
$! DESCRIPTION:
$!  Gets VOX volume, etc. into a variable
$! 
$! USAGE:
$!  @'scripts_dir'get__volume.com	'aim_filename' 'log_filename' 'variable_name' 
$!
$! PARAMETERS:
$!  P1 : input aim file
$!  P2 : log
$!  P3 : variable name
$!
$!****************************************************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! GET__VOLUME.COM:	"
$ say "=========================================================="
$!*
$!
$!
$ if p1 .eqs. "" then goto terminate
$ if p2 .eqs. "" then goto terminate
$ if (p3 .eqs. "")
$   then 
$     variable_name = ""
$   else
$     variable_name := 'p3'__
$ endif
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol variable_name
$
$ if ("''get__volume_skip'" .eqs. "") then get__volume_skip == 0
$ if (get__volume_skip .nes. "") then skip := "/skip=''get__volume_skip'"
$ if (get__volume_skip .eq. 0) then skip := ""
$ get__volume_skip == get__volume_skip + 1
$ sh sym skip
$ sh sym get__volume_skip

$!
$ IPL_BATCH

/db_scanco_activate
  -write                     false

/read
  -name                      seg
  -filename                  "p1

/vox_scanco_param
  -input                     seg
  -region_number             0
	
..	
$! Extract dimensions from logfile
$ search:
$ set output_rate=00:00:01
$ wait 00:00:02 
$!
$! Search for "!% ov     ="
$ pipe search 'p2' "!% ov     =" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ ov = line_sym - "!% ov     ="
$ ov = f$edit(ov,"trim,compress")  
$ ov = f$element(0," ",ov)
$ 'variable_name'ov == ov
$  sh sym 'variable_name'ov
$!#
$ say "!! SEG volume: ''ov' "
$ say "!! Variable: ''variable_name'ov "
$ say "!! GET__VOLUME.COM: completed "   
$ say "=========================================================="
$ exit
$!
$ terminate:
$   say "!! P1: AIM input""
$   say "!! P2: LOG input""
$   say "!! P3: variable name output""
$   exit
