$!****************************************************************************************            
$! EZ_CONVERT.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.10.20
$!  Copyright (c) 2019 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! VERSION HISTORY:
$!  2017.11.07 V.Stadelmann
$!  2018.04.05 VS if no match -> skip to complete
$!  2018.09.24 VS copy from  $!* to $!#
$! 
$! DESCRIPTION:
$!  Convert a script from EZV6 to EVALV6 conventions
$!  Replaces calls to EZ modules by hard-coded copy of modules.
$! 
$! USAGE:
$!   @ue:ez_convert	'input_script' 'output_script' 'search_string'  'lib_dir' 'debug'
$!
$! PARAMETERS:
$!  P1 : Scripts name
$!  P3 : Output script
$!  P2 : String to call scripts (e.g. "@ue:")
$!  P4 : Library loc (where p2 points to)
$!  P5 : Debug ? TRUE/FALSE
$!
$!****************************************************************************************            
$
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! EZ_CONVERT.COM: "
$ say "=========================================================="
$
$ if (p1 .eqs. "") then goto terminate
$
$!-------------------------------------------------------------
$! Test inputs 
$!-------------------------------------------------------------
$
$ say " "
$ say "-------------------------------------------------------"
$ say " STEP 1:  Check inputs "
$ say "-------------------------------------------------------"
$ say " "
$
$ if (p2 .eqs. "") then p2 = p1 - ".COM" + "__CONVERTED.COM"
$ if (p3 .eqs. "") then p3 = "@ez:"
$ if (p4 .eqs. "") then p4 = "EZ:"
$ if (p5 .nes. "TRUE") then p5 := FALSE
$
$ source_script = p1
$ output_script = p2
$ call_cmd      = p3
$ lib_dir       = p4
$ debug_bool    = p5
$
$ sh sym source_script
$ sh sym output_script
$ sh sym call_cmd
$ sh sym lib_dir
$ sh sym debug_bool
$
$ if_debug = "if (debug_bool .eqs. ""TRUE"") then "
$ if_debug sh sym if_debug
$
$ if (f$search("''source_script'") .eqs. "")
$  then
$    say "!! Error:  script file does not exist."
$    goto terminate
$ endif
$
$ source_script = source_script - f$parse(source_script,,,"version")
$ file_extension = f$extract(f$length(source_script)-3,3,source_script)       
$ if (file_extension .nes. "COM" .and. file_extension .nes. "TXT")
$  then
$    say "!! Error:  input file not a COM or TXT file"
$    goto terminate
$ endif
$
$!-------------------------------------------------------------
$! Init temp filenames 
$!-------------------------------------------------------------
$
$ call unique_id uids
$ tmp_module_file   := sys$scratch:tmp_module_'uids'.txt
$ tmp_edt_file      := sys$scratch:tmp_edt'uids'.edt
$ tmp_search_output := sys$scratch:tmp_search'uids'.txt
$ if_debug sh sym tmp_*
$
$
$!-------------------------------------------------------------
$! Start conversion
$!-------------------------------------------------------------
$
$ say " "
$ say "-------------------------------------------------------"
$ say " STEP 2:  Convert script line by line, import modules  "
$ say "-------------------------------------------------------"
$ say " "
$
$  open/read  input_script_file  'source_script'
$  open/write output_script_file 'output_script'
$
$! read input_script_file line by line
$  line_no = 0
$  read_loop_2:
$   line_no = 1 + line_no
$   if_debug sh sym line_no
$   read/end_of_file=exit_loop_2 input_script_file script_line 
$   if_debug sh sym script_line
$
$   if (script_line .nes. "") 
$     then 
$       script_line = f$edit(script_line,"trim,compress") 
$       script_line_nocomment = f$edit(script_line,"trim,compress,uncomment")
$
$       ! test if line calls an EZ module
$       if (f$locate(call_cmd,script_line_nocomment) .eqs. f$length(script_line_nocomment))
$         then  
$           ! if line calls a script but is commented - skip it
$           ! otherwise line is just copied to output
$           if (f$locate(call_cmd,script_line) .eqs. f$length(script_line)) 
$             then 
$               write/symbol output_script_file script_line
$           endif
$         else
$           ! line calls an EZ module: 
$           ! module will be copied in converted script
$           ! parsing script name and parameters from line
$           script_line_head = f$extract(0,f$locate(call_cmd,script_line),script_line)
$           script_line = script_line - script_line_head
$           module_file = f$element(0," ",script_line) - call_cmd
$           if_debug sh sym module_file
$
$           param_list = script_line - module_file - call_cmd
$           param_list = f$edit(param_list,"trim,compress")  
$           if_debug sh sym param_list
$
$           if (module_file .nes. "!") 
$              then
$                ! adding .com extension if needed
$                if (f$locate(".COM",f$edit(module_file, "upcase")) .eqs. f$length(module_file))
$                  then 
$                      module_file = module_file+".com"
$                endif
$                if_debug sh sym module_file
$                ! copy module body in tmp module file 
$                say " Line ''line_no': Copying ''module_file' to converted script."
$                open/read  current_module  'lib_dir''module_file'
$                open/write tmp_module_body 'tmp_module_file'
$                write tmp_module_body "$!--"
$
$                ! read module line by line
$                do_copy_line = "FALSE"
$                read_loop_3:
$                  read/end_of_file=exit_loop_3 current_module current_module_line 
$                  curr_mod_line = f$edit(current_module_line,"trim,compress,lowercase")  
$
$                  ! find beginning=$!*/end=$!# of script body 
$                  if (curr_mod_line .eqs. "$!*") then do_copy_line = "TRUE"
$                  if (curr_mod_line .eqs. "$!#") then do_copy_line = "FALSE"
$                  if (curr_mod_line .eqs. "$ exit") then goto exit_loop_3
$                  if (curr_mod_line .eqs. "$ terminate:") then goto exit_loop_3
$                  if_debug sh sym curr_mod_line
$                  if_debug sh sym do_copy_line
$
$                  if (do_copy_line .eqs. "TRUE") then write/symbol tmp_module_body current_module_line
$                  goto read_loop_3
$                exit_loop_3:
$                close current_module 
$                close tmp_module_body 
$
$                ! Search tmp_module_body for goto string 
$                pipe search 'tmp_module_file' "goto" | (read sys$input line ; define/job/nolog pipe_message &line)
$                pipe_message = f$edit(f$trnlnm("pipe_message"), "trim,compress")
$                if_debug sh sym pipe_message
$                if (pipe_message .eqs. "%SEARCH-I-NOMATCHES, no strings matched") then goto no_goto
$
$                pipe search 'tmp_module_file' "goto" /output = 'tmp_search_output' 
$                open/read search_file 'tmp_search_output'
$                open/write edtfile 'tmp_edt_file' 
$                goto_targets_list == ""
$
$                read_loop_goto:
$                  read/end_of_file=exit_loop_goto search_file s_res_line 
$                  s_res_line = f$edit(s_res_line, "trim,compress,uncomment")
$                  if_debug sh sym s_res_line
$
$                  goto_target = f$extract(f$locate("goto",s_res_line)+5,f$length(s_res_line),s_res_line)
$                  goto_target = f$edit(goto_target,"trim,compress") 
$                  if_debug say "!! GOTO target: ''goto_target'" 
$    	           if (goto_target .nes. "terminate") then call list_append goto_targets_list 'goto_target' 'goto_targets_list'
$                  goto read_loop_goto
$                exit_loop_goto:
$                close search_file 
$                close edtfile
$
$                ! remove duplicates and get length of goto list
$                sh sym goto_targets_list
$                if (goto_targets_list .nes. "") then call list_remove_duplicate 'goto_targets_list' goto_targets_list
$                sh sym goto_targets_list
$                call get_list_length goto_targets_list_length 'goto_targets_list'
$                
$                if (goto_targets_list_length .gt. 0) 
$                  then 
$                    say "  > Detected goto commands in ''module_file' "
$                    say " "
$                    call list_printout 'goto_targets_list' 
$
$                    ! Loop through goto_targets_list to create an EDT replacements list
$                    t_i = 0
$                    open/write edtfile 'tmp_edt_file' 
$                    loop_edt:
$                      target_i = f$element(t_i,",",goto_targets_list)
$                      target_i_new := 'target_i'_'line_no'
$                      edt_i := substitute/'target_i'/'target_i_new'/whole "
$                      write/symbol edtfile edt_i
$ 	                   t_i = t_i + 1
$ 	                   if (t_i .lt. goto_targets_list_length) then goto loop_edt
$                    exit_loop_edt:
$                    write edtfile "exit/save" 
$                    close edtfile 
$                    if_debug type 'tmp_edt_file'
$
$                    ! now apply changes to tmp_module_file with EDIT/EDT
$                    say " "
$                    say "  > Converting goto targets to targets with unique ids: "
$                    say " "
$                    edit/edt/nojournal/command='tmp_edt_file' 'tmp_module_file' 
$                    say " "
$                 endif
$
$                 no_goto:
$                 ! init parameters from param list
$                 write output_script_file "$!-------------------------------"
$                 write output_script_file "$! Initiating parameters "
$                 write output_script_file "$!-------------------------------"
$                 k = 0
$                 loop_p_k:
$                   m = k + 1
$                   ! record original params into org_pm
$                   org_pm_string := $ org_p'm' = p'm'
$                   if_debug sh sym org_pm_string
$                   write/symbol output_script_file org_pm_string
$					! new params
$                   pm_val = f$element(k," ",param_list)
$                   if_debug sh sym pm_val
$                   if (pm_val .nes. "" .and. pm_val .nes. " ")
$                     then 
$                       pm_string := $ p'm' := "''pm_val'"
$                       if_debug sh sym pm_string
$                       write/symbol output_script_file pm_string
$					  else
$                       pm_string := $ p'm' := 
$                       if_debug sh sym pm_string
$                       write/symbol output_script_file pm_string
$                   endif
$                   k = m
$                   if (k .lt. 8) then goto loop_p_k
$                 write output_script_file "$!-------------------------------"
$
$                ! Flush tmp_module_file into output_script_file
$                open/read  tmp_module_body1 'tmp_module_file'
$                read_loop_4:
$                  read/end_of_file=exit_loop_4 tmp_module_body1 tmp_module_line 
$                  if_debug sh sym tmp_module_line
$                  write/symbol output_script_file tmp_module_line
$                  goto read_loop_4
$                exit_loop_4:
$                close tmp_module_body1
$
$                ! reset original Parameters
$                write output_script_file "$!-------------------------------"
$                write output_script_file "$! Resetting parameters          "
$                write output_script_file "$!-------------------------------"
$                n = 0
$                loop_p_n:
$                   m = n + 1
$                   ! record original params into org_pm
$                   pm_string := $ p'm' = org_p'm'
$                   if_debug sh sym pm_string
$                   write/symbol output_script_file pm_string
$                   n = m
$                   if (n .lt. 8) then goto loop_p_n
$                 write output_script_file "$!-------------------------------"
$                   
$             endif
$          endif           
$       endif
$       goto read_loop_2
$  exit_loop_2:
$  close input_script_file 
$  write output_script_file "$ terminate:"
$  write output_script_file "$ say "" > An error occured, please check .log file"" "
$  close output_script_file 
$ 
$  say " "
$  say "-------------------------------------------------------"
$  say " Script exported to ''output_script' "
$  say "-------------------------------------------------------"
$  say " "
$
$  if(f$search(tmp_module_file) .nes. "") then del 'tmp_module_file';*
$  if(f$search(tmp_edt_file) .nes. "") then del 'tmp_edt_file';*
$  if(f$search(tmp_search_output) .nes. "") then del 'tmp_search_output';*
$
$
$!-------------------------------------------------------------
$
$ complete:
$ say " "
$ say "!! CONVERT_EZ.COM: Completed"
$ say "=========================================================="
$ exit
$
$ no_match:
$  say " "
$  say "!!  No match found. "
$  say " "
$ goto complete
$
$ terminate:
$  @ez:helper EZ_CONVERT.COM
$  exit
$
$!===========================
$ LIST_PRINTOUT: SUBROUTINE
$! usage:
$! 	call LIST_PRINTOUT 'list_symbol' 'print_file'
$!
$ if (p1 .eqs. "")  then exit
$ if (p2 .eqs. "")  then p2 = "sys$scratch:list_printout_tmp.txt"
$ __lpout_filename = p2
$ call get_list_length __lp_length 'p1'
$ !sh sym __lp_length
$ if (__lp_length .gt. 0) 
$   then 
$     open/write lpoutfile '__lpout_filename'
$     __j = 0
$     lp_j_loop:
$       __el_j = f$element(__j,",",p1)
$       write/symbol lpoutfile __el_j
$       __j = __j + 1
$       if (__j .lt. __lp_length) then goto lp_j_loop
$     close lpoutfile
$     type 'p2'
$ endif
$ if (__lpout_filename .eqs. "sys$scratch:list_printout_tmp.txt") then delete '__lpout_filename';*
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
$! 	call list_remove_duplicate 'input_list' output_list_symbol
$!
$ if (p1 .eqs. "") then exit
$ if (p2 .eqs. "") then exit
$
$ __return = ""
$ call get_list_length __l_length 'p1'
$ !sh sym __l_length
$
$ if (__l_length .le. 1) then __return = p1
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
$ UNIQUE_ID: SUBROUTINE
$! usage:
$! 	call UNIQUE_ID unique_id_symbol
$!
$ if (p1 .eqs. "") then exit
$
$ __uid_time_stamp = f$edit(f$time(),"trim,compress")
$ __uid_ts_date    = f$element(0," ",__uid_time_stamp)
$ __uid_ts_time    = f$element(1," ",__uid_time_stamp)
$ __uid_ts_hr      = f$element(0,":",__uid_ts_time)
$ __uid_ts_min     = f$element(1,":",__uid_ts_time)
$ __uid_ts_sec     = f$element(2,":",__uid_ts_time)
$ __uid_ts_msec    = f$element(1,".",__uid_ts_sec)
$ __uid_ts_sec     = f$element(0,".",__uid_ts_sec)
$
$ __uid_return := '__uid_ts_hr'_'__uid_ts_min'_'__uid_ts_sec'_'__uid_ts_sec'
$ 'p1' ==  __uid_return
$ endsubroutine
