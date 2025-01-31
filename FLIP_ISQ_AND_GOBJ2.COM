$!      
$!         _/_/_/  _/_/_/    _/        
$!          _/    _/    _/  _/           Image Processing Language  
$!         _/    _/_/_/    _/ 
$!        _/    _/        _/             (c)  Nicolas Vilayphiou
$!     _/_/_/  _/        _/_/_/_/             Scanco Medical
$!        
$!  IPL Batch Scanco
$!
$!  Steven Boyd, June 1 2016
$!  Update, Vincent Stadelmann June 14 2016
$!
$!==========================================================================
$!
$! Script Breakdown
$!
$! STEP 1: Flip ISQ file
$! STEP 2: Flip TRAB MASK and output GOBJ equivalent
$!
$!==========================================================================
$!
$! EVAL_FNAME     :== D0004882
$! EVAL_FNAME1    :== DK0:[XTREMECT2.DATA.00001005.00004892]D0004882_F_TRAB_MASK.GOBJ
$! EVAL_FNAME3    :== DK0:[XTREMECT2.DATA.00001005.00004892]D0004882_F_TRAB_MASK.AIM
$! EVAL_GOBJ0     :== DK0:[XTREMECT2.DATA.00001005.00004892]D0004882_F.GOBJ
$! IPL_ORIG_ISQ   :== DK0:[XTREMECT2.DATA.00001005.00004892]D0004882.ISQ
$!
$! I give ISQ_FLIP and GOBJ_FLIP equivalent names so they load automatically in VOI:
$ ISQ_FLIP   == EVAL_DIR + "F0000000.ISQ"
$ GOBJ_FLIP  == EVAL_DIR + "F0000000.GOBJ"
$ BG_FLIP  == EVAL_DIR + "F0000000_BG.AIM"
$!
$ ISQ_CROPPED   == EVAL_DIR + "N0000000.ISQ"
$ BG_CROPPED   == EVAL_DIR + "N0000000_BG.AIM"
$!
$ SHOW SYMBOL ISQ_FLIP
$ SHOW SYMBOL GOBJ_FLIP
$ SHOW SYMBOL ISQ_CROPPED
$!
$ STEP_1:
$!==========================================================================
$!
$! STEP 1: Flip ISQ file
$!
$!==========================================================================
$!
$ IPL_BATCH

/isq_gobjfit_to_aim
  -aim_name                  in
  -isq_filename              "EVAL_ISQ
  -gobj_filename             "EVAL_GOBJ0
  -border                    "EVAL_MISC1_0
  
! Make a cropped ISQ for later
/copy in tmp
/toisq_from_aim
  -aim_name                  tmp
  -isq_filename              "ISQ_CROPPED
  -square_flag               false
  -original_position         false
 
! generate background image to position GOBJ in space 
/copy in tmp
/convert_to_type
  -input                     tmp
  -output                    bg
  -out_type                  char
  
/set_value
  -input                     bg
  -value_object              0
  -value_background          0

/write_v020
  -name                      bg
  -filename                  "BG_CROPPED
  -compress_type             bin
  -version_020               true

! flip ISQ around Y  axis
/turn3d
  -input                     in
  -output                    tmp
  -turnaxis_angles           90.000 0.000 90.000
  -turnangle                 90.000000
  -img_interpol_option       0

/toisq_from_aim
  -aim_name                  tmp
  -isq_filename              "ISQ_FLIP
  -square_flag               false
  -original_position         false
 
.. 
! 
!==========================================================================
!
! STEP 2: Flip TRAB MASK and output GOBJ equivalent
!
!==========================================================================
!
$ IPL_BATCH

/read
  -name                      mask
  -filename                  "EVAL_FNAME3

/read
  -name                      bg
  -filename                  "BG_CROPPED

/add_aims
  -input1                    mask
  -input2                    bg
  -output                    newmask
 
/turn3d
  -input                     newmask
  -output                    flip
  -turnaxis_angles           90.000 0.000 90.000
  -turnangle                 90.000000
  -img_interpol_option       0
 
! set header to 0 otherwise mismatch between ISQ and GOBJ
/header_geo_set
  -input                     flip
  -off_new                   0 0 0
  -pos_new                   0 0 0
  -el_size_mm_new            -1

/togobj_from_aim
  -input                     flip
  -gobj_filename             "GOBJ_FLIP
 
! flipped background
/set_value
  -input                     flip
  -value_object              0
  -value_background          0
  
/write_v020
  -name                      flip
  -filename                  "BG_FLIP
  -compress_type             bin
  -version_020               true


..
$ EXIT
