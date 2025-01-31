$!*************************************** Easy_IPL *****************************************           
$!
$! CHECK_DCM_SERIES.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2019.09.01
$!  Copyright (c) 2019 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Check the completeness of a DICOMs series.  
$! 
$! USAGE:
$!  $ @ez:check_dcm_series 	'dcm_file' complete_sym series_props_sym list_missing_sym 
$! 
$! PARAMETERS:
$!  P1  : One DCM file of the series
$!  P2* : Output sym complete (*dcm_complete)
$!  P3* : Output properties of series (*dcm_props)
$!  P4* : Output list of missing files (*dcm_missing_files)
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
$ say "!! CHECK_DCM_SERIES.COM:  "
$ say "=========================================================="
$!*
$  	if (p1 .eqs. "") then goto terminate
$  	if (p2 .eqs. "") then p2 := dcm_complete
$  	if (p3 .eqs. "") then p3 := dcm_props
$  	if (p4 .eqs. "") then p4 := dcm_missing_files
$
$   if (f$search(p1) .eqs. "") 
$     then 
$        say "!!ERROR: DCM file ''p1' not found!"
$        goto terminate
$   endif
$
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
$  say "!! Testing DCM series completeness..."
$  if (f$locate(";", p1) .ne. f$length(p1)) then p1 = F$EXTRACT(0,f$locate(";", p1),p1)
$
$  dcm_fname = p1 - ".DCM"
$  !sh sym dcm_fname
$
$  ! Locate last _ in name and extract tail
$  call f_loc_last 'dcm_fname' "_" pos_
$  !sh sym pos_
$  !TO DO : check that pos_ != -1
$  dcm_base = F$EXTRACT(0,pos_,dcm_fname)
$  sh sym dcm_base
$
$  ! list all dcm_base_*.dcm files
$  call create__timestamp f_uid
$  out_file := sys$scratch:cds_search_'f_uid'.txt
$  !sh sym out_file
$  dir 'dcm_base'_*.dcm /col=1 /output='out_file'
$
$  ! loop through files one by one to detect missing files
$  open/read search_file 'out_file'
$
$! skip first three lines (empty, header, empty)
$  read/end_of_file=exit_loop_i search_file header_line 
$  read/end_of_file=exit_loop_i search_file header_line 
$  read/end_of_file=exit_loop_i search_file header_line 
$
$! init indexes
$  i = 0
$  n_slices = 0
$  slice_min = "na"
$  slice_max = 0
$
$! Read line by line through all files found in directory
$  read_loop_i:
$    read/end_of_file=exit_loop_i search_file res_line 
$
$    if (res_line .nes. "") 
$      then 
$        fnm     = f$parse(res_line,,,"name")
$        loc     = f$parse(res_line,,,"device") + f$parse(res_line,,,"directory")
$
$        ! get slice no 
$        slice_i = fnm - "''dcm_base'_"
$        
$        ! update indexes
$        if (slice_min .eqs. "na") then slice_min = slice_i
$        if ('slice_i' .gt. 'slice_max') then slice_max = slice_i
$        i = i+1
$       goto read_loop_i
$   endif
$
$  exit_loop_i:
$   close search_file 
$   ic_nolog
$   icalc 1 + 'slice_max' - 'slice_min'
$   n_slices = icalc_out
$   sh sym slice_min
$   sh sym slice_max
$   !sh sym n_slices
$   !sh sym i
$
$ ! test i=n_slices -> complete 
$  say " "
$  if('i' .eq. 'n_slices') 
$    then 
$      dcm_complete := T
$      say "!! All slices found between ''slice_min' and ''slice_max'. "
$   
$!-------------------------------------------------------------
$! Not complete:  -> find missing files
$!-------------------------------------------------------------
$    else 
$      say "!! Some files are missing..."
$      dcm_complete := F
$      say "!! Expected ''n_slices' files, but found only ''i' files."
$      say "!! Now identifying the missing files..."
$         ! loop through all files and test if exist
$         j = 0
$         ! init list of missing files
$         __cds_missing_files_list == ""
$         ! length of string containing slice index
$         slice_no_length = f$length(slice_min)
$         !sh sym slice_no_length
$    
$         ! test each slice from slice_min to slice_max
$         loop_j:
$           ic_nolog
$           icalc 'slice_min' + 'j'
$           slice_j = icalc_out
$           ! convert slice no to string of length slice_no_length
$           slice_j = F$FAO("!''slice_no_length'ZL",F$INTEGER(slice_j))
$           ! build slice filename and search for it
$           j_slice_fname := 'dcm_base'_'slice_j'.dcm
$           if(f$search(j_slice_fname) .eqs. "") 
$             then 
$               ! slice not found -> append to missing list
$               call list_append __cds_missing_files_list 'j_slice_fname' '__cds_missing_files_list'
$           endif
$           j = j+1
$           if(j .lt. n_slices) then goto loop_j
$
$    call get_list_length __cds_missing_files_list_length '__cds_missing_files_list'
$    say " "
$    say "!! The following ''__cds_missing_files_list_length' files are missing:"
$    call list_printout '__cds_missing_files_list' 
$    say " "
$
$!-------------------------------------------------------------
$! Assign values to global output variables
$!-------------------------------------------------------------
$    'p2' == dcm_complete 
$    'p3' == "''slice_min',''slice_max',''n_slices',''__cds_missing_files_list_length'"
$    'p4' == __cds_missing_files_list
$
$  endif
$  
$  del 'out_file';*
$
$!#
$ say "!! CHECK_DCM_SERIES.COM:	Completed "
$ say "=========================================================="
$ exit
$!
$ terminate:
$  @ez:helper CHECK_DCM_SERIES.com
$ exit
$
$!-------------------------------------------------------------
$! F_LOC_LAST: SUBROUTINE
$!-------------------------------------------------------------
$ F_LOC_LAST: SUBROUTINE
$! Locate last char in string
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
