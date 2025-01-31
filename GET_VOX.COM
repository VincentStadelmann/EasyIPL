$!************************* EZ_IPL *****************************************           
$!
$! GET_VOX.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2015.04.05
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Computes volume, volume fraction, densities of image within GOBJ roi.
$! 
$! USAGE:
$!  @ez:get_vox.com 'in_file' 'seg_file' 'gobj_file' 'variable_out' 'log_file' 
$!
$! PARAMETERS:
$!  P1  : Input grayscale AIM file
$!  P2  : Input binary AIM file   
$!  P3* : Input GOBJ mask      (*none)
$!  P4* : Variable out         (*aim)
$!  P5* : Log filename         (*eval_logfile2)
$!
$! EXAMPLE:
$!  
$!
$! VERSION HISTORY:
$!  2017.07.03 Fixed mean2 with seg_gobj_filename mask
$!  2017.07.20 /voxgobj instead of vox
$!  2017.11.02 GET_VOX copied from GET_VOX with db_activate as param
$!  2018.06.12 Added obj_nr as output
$!  2018.10.26 EZ format
$!  2018.10.28 logfile optional + reorder p4,p5
$!  2018.10.28 gobj optional 
$!  2022.06.21 remove second vox it made /skip trick fail.  
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ set output_rate=00:00:01
$ say " "
$ say "=========================================================="
$ say "!! GET_VOX.COM: computes ov/tv, mean1, mean2 "
$ say "=========================================================="
$!*
$
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then goto terminate
$ if (p3 .eqs. "") then p3 := none
$ if (p4 .eqs. "") then p4 := aim
$ if (p5 .eqs. "") then p5 = eval_logfile2
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$ show symbol p5
$
$! Optional GOBJ masking
$ __gv_gobj_string := /gobj seg 'p3' 1
$ if (p3 .eqs. "NONE") then __gv_gobj_string := !! 
$
$! Setup output variable
$ variable_name = "''p4'__"
$
$! Init or update skip tags
$ if ("''get__volume_skip'" .eqs. "") then get__volume_skip == 0
$ if (get__volume_skip .nes. "") then skip := "/skip=''get__volume_skip'"
$ if (get__volume_skip .eq. 0) then skip := ""
$ get__volume_skip == get__volume_skip + 1
$
$ ipl_batch

/db_scanco_activate false

/read
  -name                      org
  -filename    				 "p1

/read 
  -name                      seg
  -filename                  "p2

"__gv_gobj_string

! Volume, volume fraction
/vox_scanco_param
  -input                     seg

! Skip this part: double outputs makes the /skip=get__volume_skip trick fail. 
! Apparent density 
!/voxgobj_scanco_param
!  -input                     org
!  -gobj_filename             "p3
!  -peel_iter                 1
!  -region_number 	     	 0

..
$! wait to let ipl finish write log
$ wait 00:00:02  
$
$! Extract results from logfile
$! Search for "!% ov     ="
$ pipe search 'p5' "!% ov     =" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ ov = line_sym - "!% ov     ="
$ ov = f$edit(ov,"trim,compress")  
$ ov = f$element(0," ",ov)
$ 'variable_name'ov == ov
$
$! Search for "!% tv     ="
$ pipe search 'p5' "!% tv     =" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ tv = line_sym - "!% tv     ="
$ tv = f$edit(tv,"trim,compress")  
$ tv = f$element(0," ",tv)
$ 'variable_name'tv == tv
$
$ say "!! Compute OV/TV:"
$ icalc 'ov'/'tv'
$ 'variable_name'ovtv == icalc_out
$
$! Search for "!% obj_nr ="
$ pipe search 'p5' "!% obj_nr =" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ obj_nr = line_sym - "!% obj_nr ="
$ obj_nr = f$edit(obj_nr,"trim,compress")  
$ obj_nr = f$element(0," ",obj_nr)
$ 'variable_name'obj_nr == obj_nr
$
$! Search for "!% tot_nr ="
$ pipe search 'p5' "!% tot_nr =" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ tot_nr = line_sym - "!% tot_nr ="
$ tot_nr = f$edit(tot_nr,"trim,compress")  
$ tot_nr = f$element(0," ",tot_nr)
$ 'variable_name'tot_nr == tot_nr  
$
$! Search for "!% mean   ="
$ pipe search 'p5' "!% mean   =" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ mean1 = line_sym - "!% mean   ="
$ mean1 = f$edit(mean1,"trim,compress")  
$ mean1 = f$element(0," ",mean1)
$ 'variable_name'mean1 == mean1     
$
$! Search for "!% mean_unit ="
$ pipe search 'p5' "!% mean_unit =" 'skip'| (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ dens0 = line_sym - "!% mean_unit ="
$ dens0 = f$edit(dens0,"trim,compress")  
$ dens1 = f$element(0," ",dens0)
$ dens2 = dens0 - dens1
$ dens2 = f$edit(dens2,"trim,compress") 
$ 'variable_name'density == dens1                 
$ 'variable_name'density_unit == dens2                 
$
$ sh sym 'variable_name'*
$!#
$ say "!! GET_VOX.COM: Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$    @ez:helper GET_VOX.com
$   exit