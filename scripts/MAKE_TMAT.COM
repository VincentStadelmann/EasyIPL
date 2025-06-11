$!************************* EZ_IPL *****************************************           
$!
$! MAKE_TMAT.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.02.26
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Creates a transformation data file (V10) from a list of transformations
$!  ROT_X:a         Rotation a degrees around the x‐axis*,** 
$!  ROT_XR:r        Rotation r radians around the x‐axis*,** 
$!  SCALE:a,b,c     Scaling by a in x‐, b in y‐ and c in z‐direction
$!  TRANSLATE:a,b,c Translation of a mm in x‐, b mm in y‐n, c mm in z‐direction
$!                  * in global coordinates
$!                  ** also for Y and Z
$! 
$! USAGE:
$!   @ez:make_tmat.com 'tmat_file' "transformations_list_semicol"
$!
$! PARAMETERS:
$!   P1 : Transformation matrix filename 
$!   P2*: List of transformations  (separated by semicolon ;)                      
$!
$! EXAMPLE:
$!   Create transform matrix tmat.dat for translating by 10,10,5mm then 
$!   45° rotation around the y axis then translate back. 
$!   @ez:make_tmat tmat.dat "TRANSLATE:10,10,5;ROT_Y:45;TRANSLATE:-10,-10,-5"
$!
$!   Apply tmat.dat to image.aim
$!   @ez:transform	image.aim tmat.dat image_t.aim.aim
$!
$! VERSION HISTORY:
$!  2018.04.24 vec format + input testing
$!  2018.11.20 EZ format, new params order
$!  2018.11.20 New name
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! MAKE_TMAT.COM: "
$ say "=========================================================="
$!*
$!
$  tab = f$fao("!_")
$  __mt_list_rotations       = "ROT_X,ROT_Z,ROT_Y,ROT_XR,ROT_YR,ROT_ZR"
$  __mt_list_transformations = "SCALE,TRANSLATE"
$
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then goto terminate
$  sh sym p1
$  sh sym p2
$  !sh sym __mt_list_rotations
$
$  ! Create transform matrix file
$  open/write output_file 'p1'
$  write output_file "SCANCO TRANSFORMATION DATA VERSION: 10"
$
$  call get_list_length __mt_tlist_length "''p2'" ";"
$ ! sh sym __mt_tlist_length
$
$  if (__mt_tlist_length .gt. 0) 
$   then 
$     k = 0
$     ! Loop through each transformation
$     k_loop:
$       __mt_tlist__'k'  = f$element(k,";",p2)
$       __mt_ttype__'k'  = f$element(0,":",__mt_tlist__'k')
$       __mt_tvalue_'k'  = f$element(1,":",__mt_tlist__'k')
$ !      sh sym __mt_tlist__'k'
$ !      sh sym __mt_ttype__'k'
$ !      sh sym __mt_tvalue_'k'
$
$       __mt_ttype_k = __mt_ttype__'k'
$       __mt_tvalue_k = __mt_tvalue_'k'
$
$      ! Rotation input is numeric value -> write directly
$       call is_in_list '__mt_ttype_k' '__mt_list_rotations' __mt_ttype_k_in_list
$ !      sh sym __mt_ttype_k_in_list
$       if (__mt_ttype_k_in_list .eqs. "TRUE") 
$         then 
$           __mt_tmat_line_k := '__mt_ttype_k':'tab''__mt_tvalue_k'
$  !         sh sym __mt_tmat_line_k
$  		    write/symbol output_file __mt_tmat_line_k 
$       endif
$
$      ! Translation/scale input is vector
$       call is_in_list '__mt_ttype_k' '__mt_list_transformations' __mt_ttype_k_in_list
$  !     sh sym __mt_ttype_k_in_list
$       if (__mt_ttype_k_in_list .eqs. "TRUE") 
$         then 
$           @ez:vector__parse '__mt_tvalue_k' __mt_tvec_k
$           __mt_tmat_line_k := '__mt_ttype_k':'tab''__mt_tvec_k__ipl'
$  		    write/symbol output_file __mt_tmat_line_k 
$       endif
$
$       k = k + 1
$       if (k .lt. __mt_tlist_length) then goto k_loop
$  endif
$!
$  close output_file
$  Say " "
$  type 'p1'
$  Say " "
$
$
$!===========================
$ GET_LIST_LENGTH: SUBROUTINE
$! usage:
$! 	call get_list_length list_length_symbol "e1,e2,e3,..." "separator"
$! or
$! 	call get_list_length list_length_symbol 'list_symbol' 'sep'
$!
$ if (p2 .eqs. "")  then len = 0
$ if (p2 .nes. "")  then len = f$length(p2)
$ if (p2 .eqs. ",") then len = 0
$ if (p3 .eqs. "")  then p3 = ","
$
$ j = 0
$ if (len .gt. 0) 
$   then 
$     get_list_length_j_loop_start:
$       el_j = f$element(j,"''p3'","''p2'")
$       if ("''el_j'" .eqs. "''p3'") then goto get_list_length_j_loop_exit 
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
$ !     sh sym __el_j
$       if (p1 .eqs. __el_j) then __return = "TRUE" 
$ !      sh sym __return
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
$ say "!! MAKE_TMAT.com completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$   @ez:helper.com MAKE_TMAT.COM
$ exit
$
