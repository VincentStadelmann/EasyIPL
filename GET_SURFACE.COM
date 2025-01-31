$!****************************************************************           
$! GET_SURFACE.COM
$! 2017.04.12
$! 
$! USAGE:
$!  @'scripts_dir'get_surface.com	'aim_filename' 'log_filename' 'skip'
$!****************************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! GET_SURFACE.COM:	"
$ say "=========================================================="
$!
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$!
$ if p3 .eqs. "" then p3 = "0"
$ if p3 .eqs. "0" then skip := ""
$ if p3 .nes. "0" then skip := "/skip=''p3'"
$!
$ sh sym skip
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
  -border                    1 1 0

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
$! Extract dimensions from logfile
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
$ say "!! GET_SURFACE.COM: completed "   
$ say "=========================================================="
$ exit
