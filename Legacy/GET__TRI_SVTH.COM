$!****************************************************************************************            
$! GET__TRI_SVTH.COM
$! 
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! VERSION HISTORY:
$!  2017.04.12
$!  2018.03.08 vec format
$! 
$! DESCRIPTION:
$!  Gets triangulated surface, volume, etc. into a variable
$! 
$! USAGE:
$!  @'scripts_dir'get__tri_svth.com	'aim_filename' 'log_filename' 'borders_vec' 'var_name'
$!
$! PARAMETERS:
$!  P1 : input aim file
$!  P2 : log
$!  P3 : borders vector
$!  P4 : variable name
$!
$!****************************************************************************************            
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
$ if p3 .eqs. "" then p3 = "0,0,0"
$ if (f$locate(".", p3) .lt. f$length(p3))
$ 	  then 
$       border_1 = f$element(0,".",p3)
$       border_2 = f$element(1,".",p3)
$       border_3 = f$element(2,".",p3)
$ else	
$   if (f$locate(",", p3) .lt. f$length(p3))
$ 	    then 
$         border_1 = f$element(0,",",p3)
$         border_2 = f$element(1,",",p3)
$         border_3 = f$element(2,",",p3)
$   else	
$         border_1 = 0
$         border_2 = 0
$         border_3 = 0
$   endif
$ endif
$
$!
$ if (p4 .eqs. "")
$   then 
$     variable_name = ""
$   else
$     variable_name := 'p4'__
$ endif
$
$ if ("''get__tri_skip'" .eqs. "") then get__tri_skip == 0
$ if (get__tri_skip .nes. "") then skip := "/skip=''get__tri_skip'"
$ if (get__tri_skip .eq. 0) then skip := ""
$ get__tri_skip == get__tri_skip + 1
$
$ sh sym skip
$ sh sym get__tri_skip
$ show symbol border_*
$ show symbol variable_name
$
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
$ aim_surf = f$element(0," ",aimsurf)
$ 'variable_name'surf == aim_surf
$  sh sym 'variable_name'surf
$!
$! Search for V
$ pipe search 'p2' "!> V         =" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimvol = line_sym - "!> V         ="
$ aimvol = f$edit(aimvol,"trim,compress")  
$ aim_vol = f$element(0," ",aimvol)
$ 'variable_name'vol == aim_vol
$  sh sym 'variable_name'vol
$!
$! Search for Tb.Th
$ pipe search 'p2' "!> Tb.Th(pl) =" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimTh = line_sym - "!> Tb.Th(pl) ="
$ aimTh = f$edit(aimTh,"trim,compress")  
$ aim_Th = f$element(0," ",aimTh)
$ 'variable_name'th == aim_th
$  sh sym 'variable_name'th
$!#
$ say "!! "
$ say "!! GET__TRI_SVTH.COM: completed "   
$ say "=========================================================="
$ exit
