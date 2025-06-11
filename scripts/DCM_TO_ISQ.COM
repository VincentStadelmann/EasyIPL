$!*************************************** Easy_IPL *****************************************           
$!
$! DCM_TO_ISQ.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2019.09.01
$!  Copyright (c) 2019 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Converts DICOM series into an ISQ
$! 
$! USAGE:
$!  $ @ez:dcm_to_isq 	'dcm_filename' 'isq_filename' 'multifile?' 'force_convert?'
$! 
$! PARAMETERS:
$!  P1  : Input DCM file
$!  P2  : Output ISQ file 
$!  P3* : Multifile? (T*/F)
$!  P4* : Force convert if files are missing? (T/F*)
$!
$! EXAMPLE:
$!  
$!
$! VERSION HISTORY:
$! 
$!
$!******************************************************************************************           
$
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! DCM_TO_ISQ.COM:  "
$ say "=========================================================="
$!*
$  	if (p1 .eqs. "") then goto terminate 
$  	if (p2 .eqs. "") then p2 = f$extract(0,8,p1)+".ISQ"
$  	if (p3 .eqs. "") then p3 := true
$  	if (p3 .nes. "F" .or. p3 .nes. "FALSE" .or. p3 .nes. "0") then p3 := true
$  	if (p4 .eqs. "") then p4 := F
$  	if (p4 .eqs. "TRUE" .or. p4 .eqs. "1") then p4 := T
$  	if (p4 .nes. "T") then p4 := F
$
$   dcm_exist = f$search(p1)  ! Test if Dicoms exist
$   if (dcm_exist .eqs. "") then goto terminate
$   sh sym p1
$   sh sym p2
$   sh sym p3
$   sh sym p4
$
$   ic_nolog =  "define/user/nolog sys$output nla0: "    
$
$!-------------------------------------------------------------
$! Test completeness of DCM series
$!-------------------------------------------------------------
$  say " "
$  @ez:check_dcm_series 'p1' dcm_comp dcm_props dcm_missing
$  sh sym dcm_*
$  
$  if (dcm_comp .eqs. "F") 
$    then 
$      if (p4 .nes. "T") 
$        then 
$          say "!! Missing DICOMs. Will convert in ISQ only if p4 = T"
$          goto complete
$      endif
$  endif
$
$!-------------------------------------------------------------
$! Conversion
$!-------------------------------------------------------------
$  say "!! Converting DCM to ISQ..."
$
$ IPL_BATCH

/dicom_to_aim
  -aim_name                  tmp
  -dicom_filename            "p1
  -multifiles                "p3
  
/toisq_from_aim
  -aim_name                  tmp
  -isq_filename              "p2
  -square_flag               true
  -original_position         true
  
..
$!#
$ complete:
$ say "!! DCM_TO_ISQ.COM:	Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper DCM_TO_ISQ.com
$ exit
$
$!-------------------------------------------------------------
$! F_LOC_LAST: SUBROUTINE
$!-------------------------------------------------------------
$ F_LOC_LAST: SUBROUTINE
$! usage:
$! 	call f_loc_last 'string' 'char' pos_out_symbol
$!
$ if (p1 .eqs. "")  then __fll_return = "ERROR"
$ if (p2 .eqs. "")  then __fll_return = "ERROR"
$ !sh sym p1
$ !sh sym p2
$ !sh sym p3
$
$ __fll_str = p1
$ __fll_return = 0                                                         ! will return -1, if no char found
$ __fll_n = 0                                                              ! track loop nb to correct __fll_return value
$
$ __flr_loop:                                                              ! loop as long as char in remaining string
$   !sh sym __fll_n  
$   !sh sym __fll_str
$   __fll_pos_char = f$locate(p2,__fll_str)                                ! look for char in remaining string
$   !sh sym __fll_pos_char
$
$   __fll_str_length = f$length(__fll_str)                                 ! length of remaining string
$   !sh sym __fll_str_length
$
$   if (__fll_pos_char .eq. __fll_str_length)                              ! found char in string?
$     then 
$       __fll_return = __fll_return + __fll_n - 1                          ! correct position index because char is removed from remaining string at next step. 
$       !sh sym __fll_return
$     else
$       __fll_n = __fll_n+1                                                ! increase loop index
$       __fll_return = __fll_return + __fll_pos_char                       ! update return pos with last found char pos
$       __fll_str = f$extract(1+__fll_pos_char,__fll_str_length,__fll_str) ! extract remaining string
$       !sh sym __fll_str
$       goto __flr_loop
$   endif
$
$ !sh sym __fll_return
$ if (p3 .eqs. "") then write sys$output "''__fll_return'"
$ if (p3 .nes. "") then 'p3' == __fll_return
$
$ endsubroutine
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