$!************************* EZ_IPL *****************************************           
$!
$! LIST_OUTPUT_PARAMETERS.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.07.10
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Searches output parameters tags in template file
$! 
$! USAGE:
$!  @ez:list_output_parameters.com	'input_template' 'symbol_list'
$!
$! PARAMETERS:
$!  P1  : Template name
$!  P2* : Name of list symbol  (*VAR__LIST)
$!
$! EXAMPLE:
$!  
$!
$! VERSION HISTORY:
$!  2018.10.29 EZ format
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! LIST_OUTPUT_PARAMETERS.COM: "
$ say "=========================================================="
$!*
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 = "VAR__LIST"
$
$ say "Template file: ''p1' "
$
$! Local parameters
$  par_delim = "||"
$  delim_length = f$length(par_delim)
$  call create__timestamp f_uid
$  search_output := sys$scratch:list_p_out_'f_uid'.txt
$  !sh sym par_delim
$  !sh sym delim_length
$  !sh sym f_uid
$  !sh sym search_output
$
$! Test input parameters
$ if (f$search("''p1'") .eqs. "")
$  then
$    say "!! Error:  template file does not exist."
$    goto terminate
$ endif
$
$! Test if there is at least one occurence of par_delim
$  pipe search 'p1' "''par_delim'" | (read sys$input line ; define/job/nolog pipe_message &line)
$  pipe_message == f$edit(f$trnlnm("pipe_message"), "trim,compress")
$  if (pipe_message .eqs. "%SEARCH-I-NOMATCHES, no strings matched") then goto no_match
$
$! Search script for string (remove headers)
$  pipe search 'p1' "''par_delim'" /output = 'search_output' 
$  !type 'search_output'
$  say " "
$
$
$! Search string positions in search result
$  p_list == ""
$  p_i    =  0
$  open/read search_file 'search_output'
$
$  read_loop:
$   read/end_of_file=exit_read_loop search_file res_line 
$   res_line = f$edit(res_line,"trim,compress")  
$
$    locate_loop:
$       !say "!! Loop: ''p_i'"
$       !sh sym res_line
$       if (res_line .eqs. "") then goto exit_locate_loop
$       loc_str1 = f$locate(par_delim,res_line)
$       !sh sym loc_str1
$       if (loc_str1 .eq. f$length(res_line)) then goto exit_locate_loop
$       !say " "
$       res_line = res_line - f$extract(0,loc_str1,res_line)
$       res_line = res_line - par_delim
$       !sh sym res_line
$       !say " "
$       loc_str2 = f$locate(par_delim,res_line)
$       !sh sym loc_str2
$       if (loc_str2 .eq. f$length(res_line)) then goto exit_locate_loop
$       if (loc_str2 .eq. 0) then goto exit_locate_loop
$       !say " "
$       param = f$extract(0,loc_str2,res_line)
$       !sh sym param
$       res_line = f$extract(loc_str2+delim_length,f$length(res_line),res_line)
$       !sh sym res_line
$
$       param = param - par_delim
$       !sh sym param
$       !say " "
$       call list_append p_list 'param' 'p_list'
$       !sh sym p_list
$       p_i = p_i + 1
$       goto locate_loop
$
$    exit_locate_loop:
$    goto read_loop
$
$  exit_read_loop:
$  close search_file 
$  !sh sym p_list
$
$  !remove duplicate and printout
$  call list_remove_duplicate 'p_list' p_list_clean
$  call get_list_length p_list_clean_length 'p_list_clean'
$  say " "
$  'p2' == p_list_clean
$
$  say "!! Found ''p_list_clean_length' parameters in ''p1': "
$  call list_printout 'p_list_clean' 
$  say " "
$  say "''p2' =  ''p_list_clean' "
$
$
$!#
$
$ complete:
$  delete 'search_output';*
$  say " "
$  say "!! LIST_OUTPUT_PARAMETERS.COM: Completed"
$  say "=========================================================="
$  say " "
$  exit
$
$ no_match:
$  say " "
$  say "!!  No match found. "
$  say " "
$  goto complete
$
$ terminate:
$    @ez:helper LIST_OUTPUT_PARAMETERS.com
$  exit
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
$! 	call is_in_list 'item_symbol' 'list_symbol' boolean_out_symbol
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
$      !sh sym __el_j
$       if (p1 .eqs. __el_j) then __return = "TRUE" 
$       !sh sym __return
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
$
$ if (__l_length .eq. 1) 
$   then 
$     __return = p1
$ endif
$ 
$ if (__l_length .gt. 1) 
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
$ MINIMUM: SUBROUTINE
$! Usage:
$! 	call minimum min_out 'number1' 'number2'
$   if (p1 .eqs. "") then exit
$   if (p2 .eqs. "") then exit
$   if (p3 .eqs. "") then exit
$
$   __min_return = "NaN"
$
$! check that p2 and p3 are numbers
$   __check_numeric = 1
$   icalc 'p2'
$   if (icalc_out .nes. "''p2'") then __check_numeric = 0
$   icalc 'p3'
$   if (icalc_out .nes. "''p3'") then __check_numeric = 0
$   !sh sym __check_numeric
$
$ if (__check_numeric .eq. 1)
$   then 
$     !compute difference between numbers
$     icalc 'p2'-'p3'
$     __diff = icalc_out
$     !sh sym __diff
$
$     !search for "-" in difference string.
$     if (f$locate("-", __diff) .lt. f$length(__diff)) 
$       then 
$         __min_return = p2
$       else
$         __min_return = p3
$     endif
$ endif
$
$ !write sys$output "''__min_return'"
$ 'p1' == __min_return
$ endsubroutine
$
$!===========================