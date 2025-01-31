$!      
$!         _/_/_/  _/_/_/    _/        
$!          _/    _/    _/  _/           Image Processing Language  
$!         _/    _/_/_/    _/ 
$!        _/    _/        _/             
$!     _/_/_/  _/        _/_/_/_/        Lisa Falco, Scanco Medical
$!        
$!  IPL Batch Scanco
$!
$!  Segmentation with gauss filter and thresholding.
$!  Inverses a segmented image, uses cl_nr to remove unwanted pores 
$!  and then a cl_image to get the pore size distribution.
$ ON ERROR THEN EXIT
$ IPL_BATCH

!/db_scanco_activate true

! 
! extract VOI from ISQ
!

/isq_to_aim
  -aim_name                  org
  -isq_filename              "ipl_isq
  -pos                       "ipl_voix "ipl_voiy "ipl_voiz
  -dim                       "ipl_voidx "ipl_voidy "ipl_voidz

!
! write VOI to disk (as AIM)
!

/write
  -name                      org
  -filename                  "ipl_aim

!
!   Segmentation
!

/sup org
  -supdim_numbers            4 4 1
  -testoff_pixels            "ipl_support0
  -suppos_pixels_local       -1 -1 -1
  -subdim_pixels             -1 -1 -1

/seg_gauss org seg
  -sigma       "ipl_sigma0
  -support     "ipl_support0
  -low         "ipl_lower0  
  -upp	       "ipl_upper0
  -unit	       "ipl_unit0
  -value       127

/gobj
  -input_output              seg
  -gobj_filename             "ipl_gobj0
  -peel_iter                 "ipl_peel0

! Write the segmented image

/write  seg    "ipl_segaim
  -compress  bin


! Invert the segmented image, voids now become solid objects

/invert_ow
  -in_out                    seg
  -gobj_filename             gobj_from_log
  -peel_iter                 -1

! Select only solid objects between an upper and lower threshold using 
! component labelling

/cl_nr_extract
  -input                     seg
  -output                    cl
  -min_number                "ipl_misc1_0
  -max_number                "ipl_misc1_1
  -value_in_range            "ipl_misc1_2

! Use component labelling to create a histogram of the sizes of the remaining 
! object and an image where the objects  are colored according to their size

/cl_image
  -input                     cl
  -output                    cli
  -histofile_or_screentab    "ipl_fname0


! Write the colorcoded image 

/write  cli    "ipl_fname1
  -compress  bin


..
$ EXIT
