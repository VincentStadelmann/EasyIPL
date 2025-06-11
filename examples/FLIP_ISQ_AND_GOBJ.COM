$!      
$!         _/_/_/  _/_/_/    _/        
$!          _/    _/    _/  _/           Image Processing Language  
$!         _/    _/_/_/    _/ 
$!        _/    _/        _/             (c)  Scanco Medical
$!     _/_/_/  _/        _/_/_/_/             
$!        
$!  IPL Batch Scanco
$!
$!  Vincent Stadelmann June 16 2016
$!
$!==========================================================================
$! Script Breakdown
$! STEP 0: Filenames
$! STEP 1: Crop ISQ, Generate background, extract dimensions
$! STEP 2: flip ISQ, correct dimensions
$! STEP 3: flip mask, correct dimensions
$!==========================================================================
$!
$!==========================================================================
$! STEP 0: Create filenames
$!==========================================================================
$! Define filenames in original orientation and find first symbol in names:
$ AIM_TMP   == EVAL_DIR + EVAL_FNAME + "_TMP.AIM"
$ BG_TMP   == EVAL_DIR + EVAL_FNAME + "_BG_TMP.AIM"
$ MASK_NAME == EVAL_DIR + EVAL_FNAME + EVAL_MISC1_0 + ".AIM"
$ SHOW SYMBOL *TMP
$ SH SYM MASK_NAME
$!
$ PREFIX_LETTER = F$ELEMENT(0,"0", EVAL_FNAME)
$ SHOW SYMBOL PREFIX_LETTER
$!
$! Now I save this into a file for the flip back script
$ FLIP_PREFIX_FNAME == EVAL_DIR + "FLIP.DAT"
$ OPEN/WRITE TMP_FILE 'FLIP_PREFIX_FNAME'
$ WRITE TMP_FILE "''PREFIX_LETTER'"
$ CLOSE TMP_FILE
$! 
$! Define filenames in Y orientation
$! Replace prefix letter by Y to reflect orientation
$ TAIL_FNAME = F$ELEMENT(1, PREFIX_LETTER, EVAL_FNAME)
$ NEW_FNAME == "Y" + TAIL_FNAME
$ ISQ_FLIP   == EVAL_DIR + NEW_FNAME + ".ISQ"
$ GOBJ_FLIP  == EVAL_DIR + NEW_FNAME + ".GOBJ"
$ BG_FLIP  == EVAL_DIR + NEW_FNAME + "_BG.AIM"
$!
$ SHOW SYMBOL *FLIP
$! EXIT 
$!
$!==========================================================================
$! STEP 1: 
$!	- Crop ISQ file, convert to AIM
$!	- Extract background (MASK will be overlapped to BG to keep constant dimensions)
$!==========================================================================
$!
$ IPL_BATCH

/isq_gobjfit_to_aim
  -aim_name                  in
  -isq_filename              "EVAL_ISQ
  -gobj_filename             "EVAL_GOBJ0
  -border                    0
  
/write_v020
  -name                      in
  -filename                  "AIM_TMP
  -compress_type             bin
  -version_020               true

!/toisq_from_aim
!  -aim_name                  in
!  -isq_filename              "ISQ_CROPPED
!  -square_flag               false
!  -original_position         true
 
! Generate background to position GOBJ in image with constant dimensions

/convert_to_type
  -input                     in
  -output                    bg
  -out_type                  char
  
/set_value
  -input                     bg
  -value_object              0
  -value_background          0

/write_v020
  -name                      bg
  -filename                  "BG_TMP
  -compress_type             bin
  -version_020               true

/examine
  	-input                    bg
  	-item                     geometry    
	
..	
$! Extract background dimensions from logfile
$ set output_rate=00:00:02
$ wait 00:00:05  
$!
$! Search for dim
$ pipe search 'EVAL_LOGFILE2' "!> dim  " | (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimdim = line_sym - "!> dim   "
$ aimdim = f$edit(aimdim,"trim,compress")
$!
$! Search for pos
$ pipe search 'EVAL_LOGFILE2' "!> pos  " | (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimpos = line_sym - "!> pos   "
$ aimpos = f$edit(aimpos,"trim,compress")   
$!
$  pos_x = f$element(0," ",aimpos)
$  pos_y = f$element(1," ",aimpos)
$  pos_z = f$element(2," ",aimpos)
$  dim_x = f$element(0," ",aimdim)
$  dim_y = f$element(1," ",aimdim)
$  dim_z = f$element(2," ",aimdim)
$!
$  sh sym pos*
$  sh sym dim* 
$!
$!==========================================================================
$! STEP 2: 
$!	- Flip AIM 90deg around Y axis
$!	- Correct dimensions (bug in IPL adds 1 voxel after turn3D)
$!  - Save as ISQ
$!==========================================================================
$!
$ IPL_BATCH

/read
  -name                      in
  -filename                  "AIM_TMP
  
/turn3d
  -input                     in
  -output                    tmp
  -turnaxis_angles           90.000 0.000 90.000
  -turnangle                 90.000000
  -img_interpol_option       0
  
/sub_get
  -input                     tmp
  -output                    flip
  -pos                       -1 -1 -1
  -dim                       "dim_z "dim_y "dim_x
  -global_pos_flag           true  

/toisq_from_aim
  -aim_name                  tmp
  -isq_filename              "ISQ_FLIP
  -square_flag               false
  -original_position         false
 
.. 
$! 
$!==========================================================================
$! STEP 3: 
$!  - Add Trab Mask to background to have matching dimensions with ISQ
$!  - Flip 90 around Y and adapt size (extra voxels) set pos to 0,0,0 like the ISQ, save as GOBJ
$!  - Create flipped background
$!==========================================================================
$!
$ IPL_BATCH

/read
  -name                      tmp
  -filename                  "MASK_NAME

/read
  -name                      bg
  -filename                  "BG_TMP

/add_aims
  -input1                    tmp
  -input2                    bg
  -output                    mask
 
/turn3d
  -input                     mask
  -output                    tmp
  -turnaxis_angles           90.000 0.000 90.000
  -turnangle                 90.000000
  -img_interpol_option       0

/sub_get
  -input                     tmp
  -output                    flip
  -pos                       -1 -1 -1
  -dim                       "dim_z "dim_y "dim_x
  -global_pos_flag           false  
  
/header_geo_set
  -input                     flip
  -off_new                   0 0 0
  -pos_new                   0 0 0
  -el_size_mm_new            -1

/togobj_from_aim
  -input                     flip
  -gobj_filename             "GOBJ_FLIP
 
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
$! 
$!==========================================================================
$! Next: 
$!  - Open F0000000.ISQ in uct_evaluation and correct F0000000.GOBJ if necessary 
$!  - Run flip GOBJ back script
$!==========================================================================
$!
$ EXIT
