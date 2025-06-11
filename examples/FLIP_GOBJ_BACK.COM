$!      
$!         _/_/_/  _/_/_/    _/        
$!          _/    _/    _/  _/           Image Processing Language  
$!         _/    _/_/_/    _/ 
$!        _/    _/        _/             (c)  Scanco Medical
$!     _/_/_/  _/        _/_/_/_/             
$!        
$!  IPL Batch Scanco
$!
$!  Vincent Stadelmann June 17 2016
$!
$!==========================================================================
$!
$! Script Breakdown
$!
$! STEP 0: Generate file names
$! STEP 1: Read original file dimensions from background file
$! STEP 2: Flip back mask and correct dimensions
$!
$!==========================================================================
$!
$!
$!==========================================================================
$! STEP 0: Generate file names
$!==========================================================================
$! I give ISQ_FLIP and GOBJ_FLIP equivalent names so they load automatically in VOI:
$! Files in the Y orientation:
$ GOBJ_FLIP  == EVAL_DIR + EVAL_FNAME + ".GOBJ"
$ BG_FLIP  == EVAL_DIR + EVAL_FNAME + "_BG.AIM"
$ SH SYM *FLIP
$!
$! Read original prefix letter from flip.dat and generate new file name
$ FLIP_PREFIX_FNAME == EVAL_DIR + "FLIP.DAT"
$ OPEN/READ TMP_FILE 'FLIP_PREFIX_FNAME'
$ READ TMP_FILE PREFIX_LETTER
$ CLOSE TMP_FILE
$ SH SYM PREFIX_LETTER
$ TAIL_FNAME = F$ELEMENT(1, "Y", EVAL_FNAME)
$ NEW_FNAME == PREFIX_LETTER + TAIL_FNAME
$ SH SYM NEW_FNAME
$!
$! Files in the original orientation:
$ MASK_CORR ==  EVAL_DIR + NEW_FNAME + EVAL_MISC1_0 + ".AIM"
$ GOBJ_CORR ==  EVAL_DIR + NEW_FNAME + EVAL_MISC1_0 + ".GOBJ"
$ BG_TMP   == EVAL_DIR + NEW_FNAME + "_BG_TMP.AIM"
$!
$ SH SYM BG_TMP
$ SH SYM *CORR
$!
$!
$!==========================================================================
$! STEP 1: Read original file dimensions from background file
$!==========================================================================

$! Get dimensions of BG file
$ IPL_BATCH

/read
  -name                      ref
  -filename                  "BG_TMP

/examine
  	-input                    ref
  	-item                     geometry  

..
$! search in /examine output for aim dimensions
$ set output_rate=00:00:02
$ wait 00:00:05  
$!
$! search for pos
$ pipe search 'EVAL_LOGFILE2' "!> pos  " | (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimpos = line_sym - "!> pos   "
$ aimpos = f$edit(aimpos,"trim,compress")   
$!
$! search for dim
$ pipe search 'EVAL_LOGFILE2' "!> dim  " | (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ aimdim = line_sym - "!> dim   "
$ aimdim = f$edit(aimdim,"trim,compress")
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
$! STEP 2: Flip back mask and correct dimensions
$!==========================================================================
$!
$ IPL_BATCH

! flip back modified GOBJ
/gobj_to_aim
  -gobj_filename             "GOBJ_FLIP
  -output                    tmp
  -peel_iter                 0

/read
  -name                      bg
  -filename                  "BG_FLIP 
 
/add_aims
  -input1                    tmp
  -input2                    bg
  -output                    mask

/turn3d
  -input                     mask
  -output                    tmp
  -turnaxis_angles           90.000 0.000 90.000
  -turnangle                 -90.000000
  -img_interpol_option       0

/sub_get
  -input                     tmp
  -output                    newmask
  -pos                       -1 -1 -1
  -dim                       "dim_x "dim_y "dim_z
  -global_pos_flag           false  

/header_geo_set
  -input                     newmask
  -off_new                   -1
  -pos_new                   "pos_x "pos_y "pos_z
  -el_size_mm_new            -1
    
/write_v020
  -name                      newmask
  -filename                  "MASK_CORR
  -compress_type             bin
  -version_020               true

/togobj_from_aim
  -input                     newmask
  -gobj_filename             "GOBJ_CORR
	
..
$ EXIT
