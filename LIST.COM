$!****************************************************************************************            
$! LIST.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.11.08
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! VERSION HISTORY:
$!  2019.02.28 Created
$!  2021.03.05 Renamed list.com (was helper_LIST_SCRIPTS.COM)
$!  2021.03.06 Added "/nosize/nodate" in Option 3: search string 
$! 
$! DESCRIPTION:
$!  List available EasyIPL scripts
$! 
$! USAGE:
$!  @ez:list 'keyword'
$!
$! PARAMETERS:
$!  P1* : query 
$!
$!****************************************************************************************            
$!
$ say = "write sys$output"
$!*
$
$ say " "
$ @ez:header
$ say " "
$
$!-------------------------------------------------------------
$! Display help intro
$!-------------------------------------------------------------
$ type sys$input
 
==============================================================================
  
  AVAILABLE SCRIPTS:
 
$
$!-------------------------------------------------------------
$! Test inputs 
$!-------------------------------------------------------------
$ ! init local vars
$  p1_is_one_letter :== FALSE
$  alphabet = "A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z"
$
$ ! Option 1: no search string -> show full list
$ ! Option 2: search string is single letter 
$ !  -> show all scripts starting with this letter 
$ ! Option 3: search string is more than 1 letter 
$ !  -> search directory for string in filenames.  
$
$  if (p1 .eqs. "") then goto simple_list
$
$  call is_in_list 'p1' 'alphabet' p1_is_one_letter
$  if (p1_is_one_letter .eqs. "TRUE") 
$     then 
$        goto simple_list
$     else
$        goto query_keyword
$  endif
$
$!-------------------------------------------------------------
$! Option 3: search string
$!-------------------------------------------------------------
$
$  query_keyword:
$   ! create tmp file
$    call create__timestamp f_uid
$    out_file := sys$scratch:ezh_search_'f_uid'.txt
$   ! search string in files in EZ directory -> write in out_file
$   ! to do: clean up the output of dir
$    dir ez:*'p1'*.com; /exclude=(test*, ez*) /col=1 /output='out_file' /nosize/nodate
$
$   ! now read out_file
$    open/read search_file 'out_file'
$   ! skip first three lines (empty, header, empty)
$    read/end_of_file=query_keyword_exit_loop search_file header_line 
$    read/end_of_file=query_keyword_exit_loop search_file header_line 
$    read/end_of_file=query_keyword_exit_loop search_file header_line 
$
$   ! Read line by line through all files found in directory
$    query_keyword_read_loop:
$      read/end_of_file=query_keyword_exit_loop search_file res_line 
$      if (f$locate(".COM", res_line) .ne. f$length(res_line)) then  res_line = f$parse(res_line,,,"name")
$      say "''res_line'"
$      goto query_keyword_read_loop
$    query_keyword_exit_loop:
$      close search_file 
$      del 'out_file';* /nolog
$      goto terminate
$
$
$!-------------------------------------------------------------
$! Option 1&2: List scripts in alphabetic order 
$!             all or single letter only
$!  (List is generated from EASY_IPL_HELP_LIST.XLSX)
$!-------------------------------------------------------------
$ simple_list:
$
$ if (p1_is_one_letter .eqs. "TRUE") then goto 'p1'
$ A:  
$ type sys$input
ABS_THRESHOLD		Threshold an image with absolute value threshold
ADD_AIMS		Add two up to seven AIMs into one
ADD_GOBJS		Add from two up to seven GOBJs into one
AIM_TO_3DTIF		Makes 3D rendering of a binary AIM with preset file
AIM_TO_DCM		Convert an AIM into a series of DCM dicom files
AIM_TO_GOBJ		Convert a binary AIM into a GOBJ mask
AIM_TO_ISQ		Convert an AIM file into an ISQ file
AIM_TO_TIF		Convert an AIM into a series of TIF files
ALIGN_IN_Z		Align AIM according to input coordinates 
APPLY_GOBJ		Apply a GOBJ mask to an AIM image

$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ B:  
$ type sys$input
BOUNDBOX_Z_FILL_OFFSET	Crop an AIM in Z, add a border and fills with slices
BOUNDBOX		Crops out empty regions, with an optional border

$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ C:  
$ type sys$input
CHANGE_VALUE		Assign new_value to voxels with old_value in a seg image
CHECK_DCM_SERIES	Check completeness of multifiles DCM series
CLEAN			Clean off debris with erosion, labelling, dilation
CLOSE_SLW		Close an object slicewise in XY 
CLOSE			Close an object by dilation, labeling and erosion
COMPLAB_SLW		Slice by slice component selection in % total volume
COMPLAB_VOL		Component selection based on volume or nb voxel 
COMPLAB			Component selection based on label rank
COMPUTE_BONE		Compute BV, BV/TV, Density & write into UCT_LIST DB
COMPUTE_DIFFERENCE	Computes the differences between two binary AIMs
COMPUTE_DT_TH		Compute thickness map & write into UCT_LIST DB
CONCAT_AIMS		Concat/overlay two up to seven AIMs into one
CONTOUR			Contour Nth or Nth to Mth largest object(s) within image
CONVERT			Converts image to char or short type
CREATE_AIM		Create an AIM with a constant value
CREATE_SAMPLE		Create an entry in main database
CROP			Crops an image to specified dimensions

$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ D:  
$ type sys$input
DCM_TO_ISQ		Convert a DICOMs series into ISQ file
DILATION		Dilation by n voxels and optionally adds n+1 offset
DIVIDE.AIMS		Divide AIM by AIM, voxel by voxel value

$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ E:  
$ type sys$input
EROSION			Erosion of binary AIM by n voxels
EXTRUDE_AIM		Extrude binary AIM along an axis
EXTRUDE_GOBJ		Extrude GOBJ along an axis
EXTRUDE_XRAY		Extrude single slice AIM (x-ray) along an axis

$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ F:  
$ type sys$input
FILL_OFFSET		Fill offset slices with replicates of boundary slices
FIND_SAMPNO_MAX		Get the latest sample number from database

$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ G:  
$ type sys$input
GAUSS			Gaussian filter of an image
GET_AIM_HEADER		Get AIM file properties into a variable
GET_GEOMETRY		Get AIM geometry elements into a variable 
GET_ISQ_HEADER		Get ISQ file properties into a variable
GET_REG_CORR		Get registration correlation coefficients into a symbol 
GET_RESULTS		Write results in file (from DB and active variables)
GET_TH_MIN_MAX		Get max and min thickness from histogram file
GET_TRI			Gets triangulated surface, volume, etc. into symbol
GET_VOX			Compute object V, V/TV & densities within GOBJ 
GOBJ_TO_AIM		Create binary AIM from GOBJ mask

$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ H:  
$ type sys$input
HELP			Display help of a function

$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ I:  
$ type sys$input
IMPORT_ISQ		Import an ISQ file into file system
ISQ_TO_AIM_GOBJFIT	Cut out AIM from ISQ based on the position of a GOBJ
ISQ_TO_AIM		Cuts out AIM from ISQ based on dimensions vectors

$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ J:  
$ type sys$input
$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ K:  
$ type sys$input
$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ L:  
$ type sys$input
LIST                    List all EasyIPL functions
LIST_OUTPUT_PARAMETERS	List output parameters from a results template file

$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ M:  
$ type sys$input
MAKE_CYLINDER		Create a plain cylinder AIM
MAKE_TMAT		Create transformation matrix from transformations list
MAKE_SURFACE		Create the surface of an object
MAKE_XRAY		Xray projection of an AIM
MASK_OFF		Mask an off a region of an AIM with a binary AIM mask
MEDIAN			Apply median filter of support S to an image

$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ N:  
$ type sys$input
$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ O:  
$ type sys$input
OPEN			Clean off objects with erosion, labelling, dilation

$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ P:  
$ type sys$input
$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ Q:  
$ type sys$input
$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ R:  
$ type sys$input
REQUEUE_ALL		Requeue running jobs with matching name into new queue
ROTATION		Rotation of angle alpha around specified axis
REGISTER		Register an AIM to a reference AIM.

$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ S:  
$ type sys$input
SCALE			Scale AIM or GOBJ file down, up or both
SEG_GAUSS		First gauss filter AIM then threshold 
SET_HEADER		Change position, offset and element size of AIM
SET_VALUE_GOBJ		Define new values within and outside gobj of binary AIM
SET_VALUE		Define new values of binary AIM

$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ T:  
$ type sys$input
$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ U:  
$ type sys$input
$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ V:  
$ type sys$input
VECTOR__ADD			Computes sum of two vectors
VECTOR__ANGLES		Get the angles of a vector against X Y Z axes
VECTOR__CROSS_PRODUCT	Computes the cross product  u X v  
VECTOR__DIVIDE		Division of vector by a vector or a factor
VECTOR__DOT_PRODUCT	Computes the cross product  u . v 
VECTOR__FLOOR		Floor each coordinate of a vector
VECTOR__GET_ANGLE	Get the angle between two vectors
VECTOR__GET_NORM	Get the norm of a vector
VECTOR__INIT		Initialize vectorial algrebra
VECTOR__MAKE		Makes a vector v from coordinates 'vx vy vz'
VECTOR__MULTIPLY	Multiply a vector by a factor or vector 
VECTOR__NORM		Adjust vector norm to given value 
VECTOR__PARSE		Parse vector u coordinates from string 'ux,uy,uz'
VECTOR__SUBTRACT	Subtract a vector from another vector 

$ if (p1_is_one_letter .eqs. "TRUE") then goto terminate
$ W:  
$ X:  
$ Y:  
$ Z:  
$
$!-------------------------------------------------------------
$! Display help outro
$!-------------------------------------------------------------
$ terminate:
$ type sys$input
 
  NEXT:
  To get help for a specific script, type:
    @ez:script_name 
 
==============================================================================

$ exit
$
$!-------------------------------------------------------------
$! Subroutines:
$!-------------------------------------------------------------
$
$!===========================
$ LIST_PRINTOUT: SUBROUTINE
$! usage:
$! 	call LIST_PRINTOUT 'list_symbol' 'print_file'
$!
$ if (p1 .eqs. "")  then exit
$ if (p2 .eqs. "")  then p2 := sys$scratch:list_printout_tmp.txt
$
$ call get_list_length __lp_length 'p1'
$ !sh sym __lp_length
$ if (__lp_length .gt. 0) 
$   then 
$     open/write lpoutfile 'p2'
$     __j = 0
$     lp_j_loop:
$       __el_j = f$element(__j,",",p1)
$       write/symbol lpoutfile __el_j
$       __j = __j + 1
$       if (__j .lt. __lp_length) then goto lp_j_loop
$     close lpoutfile
$     type 'p2'
$ endif
$ if (p2 .eqs. "")  then delete/log sys$scratch:list_printout_tmp.txt;*
$ endsubroutine
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
$
$ __return = "FALSE"
$ call get_list_length __list_length 'p2'
$ if (__list_length .gt. 0) 
$   then 
$     __j = 0
$     is_in_list_j_loop_start:
$       __el_j = f$element(__j,",",p2)
$       if (p1 .eqs. __el_j) then __return = "TRUE" 
$       __j = __j + 1
$       if (__j .le. __list_length) then goto is_in_list_j_loop_start
$ endif
$
$ if (p3 .eqs. "") then write sys$output "''__return'"
$ if (p3 .nes. "") then 'p3' == __return
$
$ endsubroutine
$!===========================
$ LIST_REMOVE_DUPLICATE: SUBROUTINE
$! usage:
$! 	call list_remove_duplicate 'input_list_symbol' 'output_list_symbol'
$!
$ if (p1 .eqs. "") then exit
$ if (p2 .eqs. "") then p2 = p1
$
$ __return = ""
$ call get_list_length __l_length 'p1'
$ !sh sym __l_length
$ if (__l_length .gt. 0) 
$   then 
$     __el_0 = f$element(0,",",p1)
$     __return = __el_0
$     !sh sym __return
$     __j = 1
$     rmdupl_j_loop:
$       !sh sym __j
$       __el_j = f$element(__j,",",p1)
$       !sh sym __el_j
$  	    call is_in_list '__el_j' '__return' __test_j
$       !sh sym __test_j
$       if (__test_j .eqs. "FALSE") then __return = __return + ",''__el_j'"
$       !sh sym __return
$       __j = __j + 1
$       !sh sym __j
$       if (__j .lt. __l_length) then goto rmdupl_j_loop
$ endif
$
$ 'p2' == __return
$
$ endsubroutine
$!===========================
$ LIST_APPEND: SUBROUTINE
$! usage:
$! 	call list_append output_list_symbol 'item' 'input_list'
$ if (p1 .eqs. "") then exit
$ if (p2 .eqs. "") 
$   then 
$     __lap_return = ""
$     goto lap_end
$ endif
$
$ call get_list_length __lap_length 'p3'
$ !sh sym __lap_length
$ if (__lap_length .gt. 0) 
$   then 
$     __lap_return = p3 + ",''p2'"
$   else
$    __lap_return = p2
$ endif
$ !sh sym __lap_return
$
$ lap_end:
$ 'p1' == __lap_return
$ endsubroutine
$
$!===========================
$ CREATE__TIMESTAMP: SUBROUTINE
$! usage:
$! 	call CREATE__TIMESTAMP time_stamp_symbol
$
$  if (p1 .eqs. "") then exit
$
$ 	__time_stamp  = f$edit(f$time(),"trim,compress")
$ 	__ts_date     = f$element(0," ",__time_stamp)
$ 	__ts_time     = f$element(1," ",__time_stamp)
$ 	__ts_hr       = f$element(0,":",__ts_time)
$ 	__ts_min      = f$element(1,":",__ts_time)
$ 	__ts_sec      = f$element(2,":",__ts_time)
$ 	__ts_msec     = f$element(1,".",__ts_sec)
$ 	__ts_sec      = f$element(0,".",__ts_sec)
$   __time_stamp := '__ts_date'_'__ts_hr'-'__ts_min'-'__ts_sec'-'__ts_msec'
$
$   !sh sym time_stamp
$   'p1' == __time_stamp   
$ endsubroutine
$!===========================
