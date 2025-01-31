$!************************* EZ_IPL *****************************************           
$!
$! GET_GEOMETRY.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2015.04.05
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Get AIM geometry into a symbol 
$!
$! OUTPUTS:
$!  aim__dim: vector dx,dy,dz
$!  aim__pos: vector px,py,pz
$!  aim__off: vector offset_x, _y, _z
$!  aim__els: vector elsize_x, _y, _z
$!  aim__datasize: file size
$!  aim__datatype: image type
$! 
$! USAGE:
$!  @ez:get_geometry.com 'in_file' 'variable_out' 'log_file' 
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2* : Variable out         (*aim)   
$!  P3* : Log filename         (*eval_logfile2)
$!
$! EXAMPLE:
$!  
$!
$! 
$! VERSION HISTORY:
$!  2016.11.29 init
$!  2017.07.17 offset
$!  2017.07.17 Output global variable
$!  2018.10.28 EZ format
$!  2022.11.18 Added _max property
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ set output_rate=00:00:01
$ say " "
$ say "=========================================================="
$ say "!! GET_GEOMETRY.COM:	"
$ say "=========================================================="
$!*
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 := aim
$ if (p3 .eqs. "") then p3 = eval_logfile2
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$
$! Setup output variable
$ variable_name = "''p2'__"
$ show symbol variable_name
$!
$! Init or update skip tags
$ if ("''get__geometry_skip'" .eqs. "") then get__geometry_skip == 0
$ if (get__geometry_skip .nes. "") then skip := "/skip=''get__geometry_skip'"
$ if (get__geometry_skip .eq. 0) then skip := ""
$ get__geometry_skip == get__geometry_skip + 1
$ 
$ IPL_BATCH

/read
  -name                      in
  -filename                  "p1

/examine
  	-input                   in
  	-item                    geometry    
	
..	
$
$ ! for interactive use, stop here.
$ if (p3 .eqs. "") 
$   then 
$     say "!! No logfile. Exit. "
$     goto __getgeo_complete 
$ endif
$
$! Extract dimensions from logfile
$ wait 00:00:02 
$
$! Search for dim
$ pipe search 'p3' "!> dim  " 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimdim = line_sym - "!> dim   "
$ aimdim = f$edit(aimdim,"trim,compress")
$ @ez:vector__make 'variable_name'dim 'aimdim'
$ @ez:vector__make aim_dim_vec 'aimdim'
$
$! Search for offset
$ pipe search 'p3' "!> off  " 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimoffset = line_sym - "!> off  "
$ aimoffset = f$edit(aimoffset,"trim,compress")  
$ @ez:vector__make 'variable_name'off 'aimoffset'
$
$! Search for pos
$ pipe search 'p3' "!> pos  " 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimpos = line_sym - "!> pos   "
$ aimpos = f$edit(aimpos,"trim,compress")  
$ @ez:vector__make 'variable_name'pos 'aimpos'
$ @ez:vector__make aim_pos_vec 'aimpos'
$
$! Search for el size
$ pipe search 'p3' "!> element size in mm" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimelsize = line_sym - "!> element size in mm "
$ aimelsize = f$edit(aimelsize,"trim,compress")  
$ @ez:vector__make 'variable_name'els 'aimelsize'
$
$! Search for data type
$ pipe search 'p3' "!> Type of data" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimtype = line_sym - "!> Type of data "
$ aimtype = f$edit(aimtype,"trim,compress")  
$ 'variable_name'datatype == aimtype
$
$! Search for data size
$ pipe search 'p3' "!> Total memory size" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimdatasize = line_sym - "!> Total memory size "
$ aimdatasize = f$edit(aimdatasize,"trim,compress")  
$ 'variable_name'datasize == aimdatasize
$
$! Max position of aim box
$ @ez:vector__add  'aim_pos_vec' 'aim_dim_vec' 'variable_name'max
$
$! Legacy 
$ 'variable_name'pos_x == 'variable_name'pos__1
$ 'variable_name'pos_y == 'variable_name'pos__2
$ 'variable_name'pos_z == 'variable_name'pos__3
$ 'variable_name'dim_x == 'variable_name'dim__1
$ 'variable_name'dim_y == 'variable_name'dim__2
$ 'variable_name'dim_z == 'variable_name'dim__3
$ 'variable_name'els_x == 'variable_name'els__1
$ 'variable_name'els_y == 'variable_name'els__2
$ 'variable_name'els_z == 'variable_name'els__3
$ 'variable_name'off_x == 'variable_name'off__1
$ 'variable_name'off_y == 'variable_name'off__2
$ 'variable_name'off_z == 'variable_name'off__3
$ 'variable_name'max_x == 'variable_name'max__1
$ 'variable_name'max_y == 'variable_name'max__2
$ 'variable_name'max_z == 'variable_name'max__3
$
$  sh sym 'variable_name'*
$
$ __getgeo_complete:
$
$!#
$ say " "
$ say "!! GET_GEOMETRY.COM: completed"
$ say "=========================================================="
$ exit
$!
$ terminate:
$    @ez:helper GET_GEOMETRY.com
$   exit