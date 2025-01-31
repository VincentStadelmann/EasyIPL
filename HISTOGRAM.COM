$!************************* EZ_IPL *****************************************           
$!
$! HISTOGRAM.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.02.02
$!  Copyright (c) 2011-2019 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Compute image histogram within ROI
$! 
$! USAGE:
$!  @ez:histogram 'aim_file' 'histo_file' 'gobj*' 'zeros*' 'bins*' 'unit*'
$!
$! PARAMETERS:
$!  P1 : Aim file
$!  P2 : Histogram file
$!  P3*: GOBJ file                      (*NONE)
$!  P4*: Count zeros? TRUE/FALSE T/F    (*TRUE)
$!  P5*: Bins (min_val,max_val,n_bins)  (*auto)
$!  P6*: Units                          (*0)
$!       0: default
$!       1: mu
$!       2: Dens (mg HA/ccm)
$!       3: HU
$!       5: Native
$!       6: 1/1000
$!       7: mm (thickness maps, note:min & max_val in voxels)
$!
$! EXAMPLE:
$!   
$!
$! VERSION HISTORY:
$!  2015.04.05 V Stadelmann
$!  2017.07.03 VS fixed mean2 with __tmp_seg_gobj_file mask
$!  2017.07.20 VS voxgobj instead of vox
$!  2018.12.09 EZ format
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! HISTOGRAM.COM: "
$ say "=========================================================="
$!*
$
$  	if (p1 .eqs. "") then goto terminate
$  	if (p2 .eqs. "") then goto terminate
$  	if (p3 .eqs. "") then p3 = "NONE"
$  	if (p3 .eqs. "0") then p3 = "NONE"
$  	if (p4 .eqs. "") then p4 = "TRUE"
$  	if (p4 .eqs. "1") then p4 = "TRUE"
$  	if (p4 .eqs. "T") then p4 = "TRUE"
$  	if (p4 .eqs. "0") then p4 = "FALSE"
$  	if (p4 .eqs. "F") then p4 = "FALSE"
$  	if (p4 .nes. "TRUE" .and. p4 .nes. "FALSE") then p4 = "TRUE"
$  	if (p5 .eqs. "") then p5 = "-1.0,-1.0,-1"
$  	if (p6 .eqs. "") then p6 = "0"
$ 	call is_in_list 'p6' 0,1,2,3,4,5,6,7 __h_unit_check
$  	if (__h_unit_check .eqs. "FALSE") then p6 = "0"
$
$   show symbol p1 
$   show symbol p2 
$   show symbol p3 
$   show symbol p4
$   show symbol p5
$   show symbol p6
$
$! Check if p5 is a vector
$   @ez:vector__parse 'p5' __h_bins
$   if (__h_bins__h .nes. "V") then goto terminate 
$
$   if p3 .eqs. "NONE" then goto __h_nogobj
$
$!===========================
$ GET_LIST_LENGTH: SUBROUTINE
$! usage:
$! 	call get_list_length list_length_symbol "e1,e2,e3,..."
$! or
$! 	call get_list_length list_length_symbol 'list_symbol'
$!
$ if (p2 .eqs. "")  then len = 0
$ if (p2 .nes. "")  then len = f$length(p2)
$ if (p2 .eqs. ",") then len = 0
$
$ j = 0
$ if (len .gt. 0) 
$   then 
$     get_list_length_j_loop_start:
$       el_j = f$element(j,",","''p2'")
$       if ("''el_j'" .eqs. ",") then goto get_list_length_j_loop_exit 
$       j = j + 1
$       if (j .le. len) then goto get_list_length_j_loop_start
$ endif
$
$ get_list_length_j_loop_exit:
$  'p1' == j
$
$ endsubroutine
$!===========================
$ IS_IN_LIST: SUBROUTINE
$! usage:
$! 	call is_in_list 'item_symbol' 'list_symbol' 'boolean_out_symbol'
$!
$ if (p1 .eqs. "")  then __return = "FALSE"
$ if (p2 .eqs. "")  then __return = "FALSE"
$ !sh sym p1
$ !sh sym p2
$
$
$ __return = "FALSE"
$ call get_list_length __list_length 'p2'
$ !sh sym __list_length
$ if (__list_length .gt. 0) 
$   then 
$     __j = 0
$     is_in_list_j_loop_start:
$       __el_j = f$element(__j,",",p2)
$      ! sh sym __el_j
$       if (p1 .eqs. __el_j) then __return = "TRUE" 
$       ! sh sym __return
$       __j = __j + 1
$       if (__j .le. __list_length) then goto is_in_list_j_loop_start
$ endif
$
$ if (p3 .eqs. "") then write sys$output "''__return'"
$ if (p3 .nes. "") then 'p3' == __return
$
$ endsubroutine
$!===========================
$
$
$
$!
$ IPL_BATCH

/read
  -name                      in
  -filename                  "P1

/gobj_maskaimpeel_ow
  -input_output              in
  -gobj_filename             "P3
  -peel_iter                 0
  
/bounding_box_cut
  -input                     in
  -output                    out
  -z_only                    false
  -border                    0 0 0

/histo
  -input                     in
  -fileout_or_screentab      "P2
  -from_val                  "__h_bins__1
  -to_val                    "__h_bins__2
  -nr_bins_in_tab            "__h_bins__3
  -dt_type                   auto
  -count_zeros               "p4
  -unit                      "p6

  
..
$ goto __h_completed
$
$ __h_nogobj:
$ say "!! No GOBJ: "
$ IPL_BATCH

/read
  -name                      in
  -filename                  "P1

/histo
  -input                     in
  -fileout_or_screentab      "P2
  -from_val                  "__h_bins__1
  -to_val                    "__h_bins__2
  -nr_bins_in_tab            "__h_bins__3
  -dt_type                   auto
  -count_zeros               "p4
  -unit                      "p6
  
..
$
$ __h_completed:
$ say "!! Histogram:"
$ type 'p2'
$
$!#
$ say "!! HISTOGRAM.COM:	Completed "
$ say "=========================================================="
$
$ exit
$
$ terminate:
$  @ez:helper HISTOGRAM.com
$ exit