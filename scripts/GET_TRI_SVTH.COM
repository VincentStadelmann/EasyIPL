$!****************************************************************************************            
$!
$! GET_TRI_SVTH.COM
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
$!  @'scripts_dir'get_tri_svth 'aim_file' 'var_name' 'borders_vec' 'log_file' 
$!
$! PARAMETERS:
$!  P1 : AIM filename
$!  P2*: Variable name    (*aim)
$!  P3*: Borders vector   (*0,0,0)
$!  P4*: Log filename     (*eval_logfile2)
$!
$!****************************************************************************************            
$!
$ say = "write sys$output"
$ set output_rate=00:00:01
$
$ say "=========================================================="
$ say "!! GET_TRI_SVTH.COM:	"
$ say "=========================================================="
$!*
$
$! Test inputs
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 := aim
$ if (p3 .eqs. "") then p3 = "0,0,0"
$ if (p3 .eqs. "0") then p3 = "0,0,0"
$ if (p4 .eqs. "") then p4 = eval_logfile2
$
$! Parse p3
$   @ez:vector__parse 'p3' __gt_border
$   if (__gt_border__h .nes. "V") then goto terminate 
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$
$! Update skips
$ if ("''get__tri_skip'" .eqs. "") then get__tri_skip == 0
$ if (get__tri_skip .nes. "") then skip := "/skip=''get__tri_skip'"
$ if (get__tri_skip .eq. 0) then skip := ""
$ get__tri_skip == get__tri_skip + 1
$
$ sh sym skip
$ sh sym get__tri_skip
$
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
  -border                    "__gt_border__1 "__gt_border__2 "__gt_border__3

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
$ wait 00:00:02
$!
$! Search for S
$ pipe search 'p4' "!> S         =" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimsurf = line_sym - "!> S         ="
$ aimsurf = f$edit(aimsurf,"trim,compress")  
$ aim_surf = f$element(0," ",aimsurf)
$ 'p2'__surf == aim_surf
$  sh sym 'p2'__surf
$!
$! Search for V
$ pipe search 'p4' "!> V         =" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimvol = line_sym - "!> V         ="
$ aimvol = f$edit(aimvol,"trim,compress")  
$ aim_vol = f$element(0," ",aimvol)
$ 'p2'__vol == aim_vol
$  sh sym 'p2'__vol
$!
$! Search for Tb.Th
$ pipe search 'p4' "!> Tb.Th(pl) =" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimTh = line_sym - "!> Tb.Th(pl) ="
$ aimTh = f$edit(aimTh,"trim,compress")  
$ aim_Th = f$element(0," ",aimTh)
$ 'p2'__th == aim_th
$  sh sym 'p2'__th
$!#
$ say "!! "
$ say "!! GET_TRI_SVTH.COM: completed "   
$ say "=========================================================="
$ exit
$
$ terminate:
$    @ez:helper GET_TRI_SVTH.com
$ exit