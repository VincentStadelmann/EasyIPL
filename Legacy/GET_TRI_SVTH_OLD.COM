$!****************************************************************           
$! GET_TRI_SVTH.COM
$! 2017.04.12
$! 
$! USAGE:
$!  @'scripts_dir'get_tri_svth.com	'aim_filename' 'log_filename' 'borders' 'skip'
$!****************************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! GET_TRI_SVTH.COM:	"
$ say "=========================================================="
$!*
$!
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$!
$ if p3 .eqs. "" then p3 = "0.0.0"
$ border_1 = f$element(0,".",p3)
$ border_2 = f$element(1,".",p3)
$ border_3 = f$element(2,".",p3)
$!
$ if p4 .eqs. "" then p4 = "0"
$ if p4 .eqs. "0" then skip := ""
$ if p4 .nes. "0" then skip := "/skip=''p4'"
$!
$ sh sym border_*
$ sh sym skip
$!
$! goto search
$!
$ IPL_BATCH

/db_scanco_activate
  -write                     false

/read
  -name                      seg
  -filename                  "p1

!! add space around in xy to keep full surface
!! no space in z to remove cutting planes

/bounding_box_cut
  -input                     seg
  -output                    obj
  -z_only                    false
  -border                    "border_1 "border_2 "border_3

/tri_da_metric_db
  -input                     obj
  -output                    tri
  -gobj_filename             none
  -peel_iter                 0
  -ip_sigma                  0.000000
  -ip_support                0
  -ip_threshold              50
  -nr_ave_iter               2
  -t_dir_radius              2
  -epsilon                   1.200000
  -size_image                512 512
  -scale_image               0.700000
  -edges                     false
  -nr_views                  0
	
..	
$! Extract TRI dimensions from logfile
$ search:
$ set output_rate=00:00:01
$ wait 00:00:02 
$!
$! Search for S
$ pipe search 'p2' "!> S         =" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimsurf = line_sym - "!> S         ="
$ aimsurf = f$edit(aimsurf,"trim,compress")  
$ aim_surf == f$element(0," ",aimsurf)
$ say "!! AIM surface: ''aim_surf' "
$!
$! Search for V
$ pipe search 'p2' "!> V         =" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimvol = line_sym - "!> V         ="
$ aimvol = f$edit(aimvol,"trim,compress")  
$ aim_vol == f$element(0," ",aimvol)
$ say "!! AIM volume: ''aim_vol' "
$!
$! Search for Tb.Th
$ pipe search 'p2' "!> Tb.Th(pl) =" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimTh = line_sym - "!> Tb.Th(pl) ="
$ aimTh = f$edit(aimTh,"trim,compress")  
$ aim_Th == f$element(0," ",aimTh)
$ say "!! AIM thickness: ''aim_Th' "
$ say "!! "
$ say "!! GET_TRI_SVTH.COM: completed "   
$ say "=========================================================="
$ exit
