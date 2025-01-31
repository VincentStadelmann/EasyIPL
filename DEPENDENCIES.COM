$!************************* EZ_IPL *****************************************    
$!       
$! DEPENDENCIES.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2017.11.07
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Searches dependencies to other EZ files within an EZ file
$!
$! PARAMETERS:
$!  P1 : Scripts name
$!  P2 : String to call scripts                (* "@ez:")
$!  P3 : Library location (where p2 points to) (*EZ:)
$!  P4 : Debug?                                (true/*false)
$!
$! USAGE:
$!  @ez:dependencies 'script' 'search_string' 'lib_dir' 'debug?' 
$!
$! VERSION HISTORY:
$!  2017.11.07 Minor fix
$!  2018.04.05 If no match -> skip to complete
$!  2018.10.22 EZ Format
$!
$!***************************************************************************            
$!    
$ say = "write sys$output"
$! say "  "
$ say "=========================================================="
$ say "!! DEPENDENCIES.COM: "
$ say "=========================================================="
$!
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 = "@ez:"     ! call_string
$ if (p3 .eqs. "") then p3 = p2 - "@"   ! library
$ if (p4 .nes. "TRUE") then p4 := FALSE ! debug
$
$ sh sym p1
$ sh sym p2
$ sh sym p3
$ sh sym p4
$
$ if (f$search("''p1'") .eqs. "")
$  then
$    say "!! Error:  script file does not exist."
$    goto terminate
$ endif
$
$ p1 = p1 - f$parse(p1,,,"version")
$ file_extension = f$extract(f$length(p1)-3,3,p1)       
$ if (file_extension .nes. "COM" .and. file_extension .nes. "TXT")
$  then
$    say "!! Error:  input file not a COM or TXT file"
$    goto terminate
$ endif
$
$!
$  say " "
$
$! Test if there is at least one occurence of "@ue:"
$  pipe search 'p1' "''p2'" | (read sys$input line ; define/job/nolog pipe_message &line)
$  pipe_message == f$edit(f$trnlnm("pipe_message"), "trim,compress")
$  if (pipe_message .eqs. "%SEARCH-I-NOMATCHES, no strings matched") then goto no_match
$
$! Search script for call_string 
$  search_output := sys$scratch:search_output.txt
$  pipe search 'p1' "''p2'" /output = 'search_output' 
$
$  if (p4 .eqs. "TRUE") then type 'search_output'
$  say " "
$
$  open/read search_file 'search_output'
$  i = 0
$  scripts_list == ""
$  read_loop:
$   read/end_of_file=exit_loop search_file res_line 
$   if (p4 .eqs. "TRUE") then sh sym res_line
$
$   if (res_line .nes. "") 
$     then 
$!       res_line = res_line - "$"
$       res_line = f$edit(res_line,"trim,compress")  
$       if (p4 .eqs. "TRUE") then sh sym res_line
$       line_drop = f$extract(0,f$locate(p2,res_line),res_line)
$       if (p4 .eqs. "TRUE") then sh sym line_drop
$       res_line = res_line - line_drop      
$       if (p4 .eqs. "TRUE") then sh sym res_line
$       script = f$element(0," ",res_line) - p2
$       if (p4 .eqs. "TRUE") then sh sym script
$       if (script .nes. "!") 
$         then
$    	    call list_append scripts_list 'script' 'scripts_list'
$           if (p4 .eqs. "TRUE") then sh sym scripts_list
$       endif
$       i = i+1
$       goto read_loop
$   endif
$ exit_loop:
$ close search_file 
$
$ ! remove duplicate and printout
$  call list_remove_duplicate 'scripts_list' scripts_list_clean
$  call get_list_length scripts_list_clean_length 'scripts_list_clean'
$  say "!! Found ''scripts_list_clean_length' script dependencies: "
$  call list_printout 'scripts_list_clean' 
$  say " "
$
$ ! test if all scripts are in lib_dir
$  missing_scripts_list == ""
$  if (scripts_list_clean_length .gt. 0) 
$   then 
$     s = 0
$     n = 0
$     s_loop:
$       el_s = f$element(s,",",scripts_list_clean)
$       el_s_filename = "''p3'''el_s'"
$ 		if (f$search("''el_s_filename'") .eqs. "" .and. f$search("''el_s_filename'.COM") .eqs. "") 
$          then 
$    	      call list_append missing_scripts_list 'el_s' 'missing_scripts_list'
$             n = n + 1
$          endif
$       s = s + 1
$       if (s .lt. scripts_list_clean_length) then goto s_loop
$    say " "
$    call get_list_length missing_scripts_list_length 'missing_scripts_list'
$
$    if (missing_scripts_list_length .eq. 0) then say "!! All scripts already in ''p3'"
$    if (missing_scripts_list_length .gt. 0) 
$      then 
$        say "!! Found ''missing_scripts_list_length' missing scripts in ''p3':"
$        call list_printout 'missing_scripts_list' 
$        say " "
$        say "!! Writing commands to copy missing dependencies from UE: to ''P3' "
$        s4 = 0
$        copy_com_file := sys$scratch:copy_dependencies.com
$        open/write copycom 'copy_com_file'
$        s4_loop:
$           el_s = f$element(s4,",",missing_scripts_list)
$ 		    write copycom "$ copy ue:''el_s' ''p3'"
$           s4 = s4 + 1
$           if (s4 .lt. missing_scripts_list_length) then goto s4_loop
$        close copycom
$        say "!! Commands written to ''copy_com_file'"
$    endif
$  endif
$ if (p4 .nes. "TRUE") then delete 'search_output';*
$ complete:
$ say " "
$ say "!! DEPENDENCIES.COM: Completed"
$ say "=========================================================="
$ exit
$
$ no_match:
$  say " "
$  say "!!  No match found. "
$  say " "
$  goto complete
$
$
$ terminate:
$  @ez:helper dependencies.com
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
