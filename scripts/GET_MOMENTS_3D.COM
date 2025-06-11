$!****************************************************************************************            
$!
$! GET_MOMENTS_3D.COM
$! 
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2022 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! VERSION HISTORY:
$!  2022.11.04 VS
$! 
$! DESCRIPTION:
$!  Gets center of gravity & moments of inertia into a variable
$! 
$! USAGE:
$!  @ez:get_moments_3d 'aim_file' var_name
$!
$! PARAMETERS:
$!  P1 : AIM filename
$!  P2*: Variable name    (*aim)
$!
$!****************************************************************************************            
$!
$ say = "write sys$output"
$ set output_rate=00:00:01
$
$ say "=========================================================="
$ say "!! GET_MOMENTS_3D.COM:	"
$ say "=========================================================="
$!*
$
$! Test inputs
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 := aim
$
$ show symbol p1
$ show symbol p2
$
$! Create temporary output file
$  call create__timestamp f_uid
$  gm3d_output = P1 - ".AIM" + "__gm3d_''f_uid'.txt"
$
$ sh sym gm3d_output
$
$!
$ IPL_BATCH

/db_scanco_activate
  -write                     false

/read
  -name                      seg
  -filename                  "p1

/moment3d_of_inertia
  -input                     seg
  -fileout_or_screentab      "gm3d_output
	
..	
$
$! View output
$!  say "TYPE ''gm3d_output':"
$!  say "************************************************"
$!  type 'gm3d_output'
$!  say "************************************************"
$
$! Extract center of mass from gm3d_output
$ 
$ wait 00:00:01
$ 
$ search_string1 = "ctr of mass in px in global coord."
$ search_string2 = "ctr of mass in mm in global coord."
$!
$! Search 1
$ say "Searching for center of mass"
$ pipe search 'gm3d_output' "''search_string1'" | (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ search_result1 = line_sym - "''search_string1'"
$ search_result1 = f$edit(search_result1,"trim,compress")  
$ @ez:vector__make 'p2'__g_vx 'search_result1'
$
$! Search 2
$ pipe search 'gm3d_output' "''search_string2'" | (read sys$pipe line ; define/job/nolog line_log &line)
$ line_sym = f$trnlnm("line_log")
$ search_result2 = line_sym - "''search_string2'"
$ search_result2 = f$edit(search_result2,"trim,compress")  
$ @ez:vector__make 'p2'__g_mm 'search_result2'
$
$ say "Searching for MOIs"
$ i = 0
$ moi_loop:
$   search_string_i = "moi[''i']"
$   !sh sym search_string_i
$   pipe search 'gm3d_output' "''search_string_i'" | (read sys$pipe line ; define/job/nolog line_log &line)
$   line_sym = f$trnlnm("line_log")
$   search_result_i = line_sym - "''search_string_i'"
$   search_result_i = f$edit(search_result_i,"trim,compress")  
$   @ez:vector__make 'p2'__moi_'i' 'search_result_i'
$   i = i+1
$   if (i .le. 2) then goto  moi_loop
$
$ exit
$
$
$  sh sym 'p2'__*
$
$!#
$ say "!! "
$ say "!! GET_MOMENTS_3D.COM: completed "   
$ say "=========================================================="
$ exit
$
$ terminate:
$    @ez:helper GET_MOMENTS_3D.com
$ exit
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
$