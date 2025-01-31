$!*************************************************            
$! CREATES 3 COLORS IMAGE FOR KNOTUS
$! 2016.07.11
$! 
$! Description:
$!  Applies the _LEFT and _RIGHT mask to a segmented AIM
$!  Changes values and merge them for 3D viewing.
$!  P1 : name of segmented aim file
$!
$! USAGE:
$!   @UE:THREECOLORS.COM	'input_filename' 
$!*************************************************            
$!
$   WRITE SYS$OUTPUT "THREECOLORS.COM"
$    IF P1 .EQS. ""
$     THEN
$ 		 WRITE SYS$OUTPUT "Assigns _LEFT and _RIGHT ROIs with different colors."
$ 		 WRITE SYS$OUTPUT "Requirements:" 
$ 		 WRITE SYS$OUTPUT "  - a segmented file (_SEG.AIM)"
$ 		 WRITE SYS$OUTPUT "  - two contours (_LEFT.GOBJ and _RIGHT.GOBJ)"
$ 		 WRITE SYS$OUTPUT "Usage:"
$ 		 WRITE SYS$OUTPUT " @UE:THREECOLORS.COM 'seg_filename' "
$ 		 WRITE SYS$OUTPUT "Output:" 
$ 		 WRITE SYS$OUTPUT "  - a multicolor segmented file (_3COLORS.AIM)"
$		 EXIT
$    ENDIF
$!
$! Generate filenames:
$ 	 WRITE SYS$OUTPUT "FILENAME:"
$    LEFT_GOBJ_FILENAME = P1 - "_SEG.AIM" + "_LEFT.GOBJ"
$    RIGHT_GOBJ_FILENAME = P1 - "_SEG.AIM" + "_RIGHT.GOBJ"
$    THREECOLORS_FILENAME = P1 - "_SEG.AIM" + "_3COLORS.AIM"
$    SH SYM *FILENAME
$!
$! Check presence of files:
$    IF F$SEARCH("''LEFT_GOBJ_FILENAME'") .EQS. ""
$     THEN
$ 		 WRITE SYS$OUTPUT "ERROR: CONTOUR ''LEFT_GOBJ_FILENAME' MISSING. EXIT"
$		 EXIT
$    ENDIF
$    IF F$SEARCH("''RIGHT_GOBJ_FILENAME'") .EQS. ""
$     THEN
$ 		 WRITE SYS$OUTPUT "ERROR: CONTOUR ''RIGHT_GOBJ_FILENAME' MISSING. EXIT"
$		 EXIT
$    ENDIF
$!
$ IPL_BATCH

/read
  -name                      seg
  -filename                  "P1
  
/cl_ow_rank_extract
  -input_output              seg
  -first_rank                1
  -last_rank                 1
  -connect_boundary          false
  -value_in_range            127
  -topology                  6

/copy
  -in                        seg
  -out                       left

/copy
  -in                        seg
  -out                       right

/gobj_maskaimpeel_ow
  -input_output              left
  -gobj_filename             "LEFT_GOBJ_FILENAME
  -peel_iter                 0
  
/gobj_maskaimpeel_ow
  -input_output              right
  -gobj_filename             "RIGHT_GOBJ_FILENAME
  -peel_iter                 0
  
/set_value
  -input                     seg
  -value_object              -1
  -value_background          0
  
/set_value
  -input                     left
  -value_object              127
  -value_background          0

/set_value
  -input                     right
  -value_object              126
  -value_background          0

/add_aims
  -input1                    left
  -input2                    right
  -output                    tmp

/add_aims
  -input1                    tmp
  -input2                    seg
  -output                    out


/write_v020
  -name                      out
  -filename                  "THREECOLORS_FILENAME
  -compress_type             bin
  -version_020               true
  
..
$ exit
