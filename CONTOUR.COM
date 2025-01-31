$!************************* EZ_IPL *****************************************           
$! 
$! CONTOUR.COM
$! 
$!  Written by: Vincent Stadelmann 2017.11.01
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! 
$! DESCRIPTION:
$!  Contours Nth or Nth to Mth largest object(s) within image using 
$!  thresholding and component labelling. 
$!  Adapted from IPLV6_CONTOUR.COM by Nicolas Vilayphiou
$! 
$! USAGE:
$!  @ue:contour 'in_file' 'out_file' 'lower' 'upper' 'sigma' 'support' 'rank' 'dilation'
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2  : Output AIM file         (*_CONT.AIM)
$!  P3* : Lower threshold         (*100)
$!  P4* : Upper threshold         (*1000)
$!  P5* : Gauss sigma             (*0.5)
$!  P6* : Gauss support           (*1)
$!  P7* : Rank object (n or n,m)  (*1)
$!  P8* : Dilation                (*10)
$!
$! VERSION HISTORY:
$!  2017.11.01 Created
$!
$!***************************************************************************            
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! CONTOUR.COM:	"
$ say "=========================================================="
$!*
$!
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_CONT.AIM"
$  if (p3 .eqs. "") then p3 = 100 
$  if (p4 .eqs. "") then p4 = 1000
$  if (p5 .eqs. "") then p5 := 0.5
$  if (p6 .eqs. "") then p6 = 1
$  if (p7 .eqs. "") then p7 = 1 
$  if (p8 .eqs. "") then p8 = 10 
$
$ sh sym p1
$ sh sym p2
$ sh sym p3
$ sh sym p4
$ sh sym p5
$ sh sym p6
$ sh sym p7
$ sh sym p8
$
$!
$  __cont_output_gobj = p2 - ".AIM" + ".GOBJ"
$
$  icalc 2 * 'p6'
$  __cont_border = icalc_out
$  icalc -2 * ('p6'-1)
$  __cont_border_neg = icalc_out
$
$  icalc floor('p8' / 2)
$  __cont_open_dist = icalc_out
$
$  if (f$locate(",", p7) .lt. f$length(p7))
$ 	then 
$		say "!! Parsing objects limits from p7 list"
$   	__cont_clnr1 = f$element(0,",",p7)
$   	__cont_clnr2 = f$element(1,",",p7)
$ 	else	
$		__cont_clnr1 =  p7
$		__cont_clnr2 =  p7
$  endif
$
$ ! show symbol __cont_clnr* 
$
$ IPL_BATCH

/read
  -name                      in
  -filename                  "p1
 
!/sup_divide
!  -input                     in
!  -supdim_numbers            4 4 1
!  -testoff_pixels            "p6
!  -suppos_pixels_local       -1 -1 -1
!  -subdim_pixels             -1 -1 -1

!Extension to prevent boundary slices being cut by SEG_GAUSS
/border_change
  -input                     in
  -output                    aim
  -border                    "__cont_border  ! 8 8 8 ! 

/offset_add
  -input                     aim
  -add_offset                "__cont_border ! 8 8 8 ! 

/fill_offset_duplicate 
  -input                     aim

/seg_gauss
  -input                     aim
  -output                    seg
  -sigma                     "p5
  -support                   "p6
  -lower_in_perm_aut_al      "p3
  -upper_in_perm_aut_al      "p4
  -value_in_range            127

! Select n to mth objects
/cl_ow_rank_extract
  -input_output              seg
  -first_rank		     	 "__cont_clnr1
  -last_rank		     	 "__cont_clnr2
  -connect_boundary          false
  -value_in_range            127
  -topology                  6

/bounding_box_cut
  -input                     seg
  -output                    seg_bbc
  -z_only                    false
  -border                    0 0 0

/copy
  -in                        seg_bbc
  -out                       seg

! Making a plain box
/set_value
  -input                     seg_bbc
  -value_object              1
  -value_background          1

! Setting Box size to original Z-Dim
/bounding_box_cut
  -input                     seg_bbc
  -output                    box
  -z_only                    false
  -border                    "__cont_border_neg  !-6

! Ensuring closing outer boundaries
/dilation
   -input                    seg
   -output                   dilate
   -dilate_distance          "p8
   -continuous_at_boundary   0 0 1
   -metric                   11

/set_value
  -input                     dilate
  -value_object              0
  -value_background          127

/cl_rank_extract
  -input                     dilate
  -output                    outside
  -first_rank		     	 1
  -last_rank		     	 1
  -connect_boundary          false
  -value_in_range            127
  -topology                  6
  
/delete
  -name                      dilate
  
/set_value
  -input                     outside
  -value_object              0
  -value_background          127

/rename
  -old_name                  outside
  -new_name                  inside
  -name                      outside
  
/erosion
   -input                    inside
   -output                   voi
   -erode_distance           "p8
   -use_previous_margin      true
   -metric                   11

/delete
  -name                      inside

! smoothen voi
/open
  -input                     voi
  -output                    voi_smooth
  -open_distance             "__cont_open_dist
  -metric                    11

! Crop to original dimensions
/multiply_volumes
  -input1                    voi_smooth
  -input2                    box
  -output                    contour
  -common_region_only        true
  -multiply_zero_pixels      true

/delete
  -name                      voi

/delete
  -name                      voi_smooth

/delete
  -name                      box

/write_v020
  -name                      contour
  -filename                  "p2
  -compress_type             bin
  -version_020               true

/togobj_from_aim
  -input                     contour
  -gobj_filename             "__cont_output_gobj
  -min_elements              5
  -max_elements              0
  -curvature_smooth          1

..
$ say "!! CONTOUR.COM:	Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper CONTOUR.com
$ exit
