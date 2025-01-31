$!*************************************** Easy_IPL *****************************************           
$!
$! IMPORT_ISQ.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2019.09.02
$!  Copyright (c) 2019 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Import an ISQ file into DB
$! 
$! USAGE:
$!  $ @ez:import_isq 	'isq_filename' 'sample_nb'  'output_var' 'log_file'
$! 
$! PARAMETERS:
$!  P1  : ISQ file
$!  P2* : Sample number or N(=new) (*N)
$!  P3* : Output var               (*imported)
$!  P4* : Output var               (*eval_logfile2)
$!
$! EXAMPLE:
$!  
$!
$! VERSION HISTORY:
$!  2023.11.26 Added output var
$!
$!******************************************************************************************           
$
$ on error then exit
$ set output_rate=00:00:01
$
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! IMPORT_ISQ.COM:  "
$ say "=========================================================="
$!*
$  	if (p1 .eqs. "") then goto terminate
$  	if (p2 .eqs. "") then p2 = "N"
$   if (p3 .eqs. "") then p3 = "imported"
$   if (p4 .eqs. "") then p4 = eval_logfile2
$
$! Init variables
$   __ii_sym     = p3
$   __ii_logfile = p4
$   sh sym __ii_sym
$   sh sym __ii_logfile
$
$! Init skip variables if needed
$ if (f$type(__import_isq_skip) .eqs. "") then __import_isq_skip == 0
$
$! Prepare skip strings
$! /skip=0 is invalid -> must split in two ifs
$ if (__import_isq_skip .eq. 0) then import_skip := ""
$ if (__import_isq_skip .gt. 0) then import_skip := "/skip=''__import_isq_skip'"
$
$! Increment skip
$ __import_isq_skip == __import_isq_skip + 1 
$
$ sh sym *skip*
$
$! If P2 = New -> get ISQ name from header, create sample and determine nb
$  if (p2 .eqs. "N" )
$    then 
$      say "!! OPTION NOT VAVAILABLE YET !!"
$!    ! Get name from ISQ header
$!    ! in progress!!
$!    call create__timestamp f_uid
$!    command_file := sys$scratch:uct_define_cmd_'f_uid'.txt
$!    res_file := sys$scratch:uct_define_'f_uid'.txt
$!    
$!    ! Use write_info to get sample list
$!    open/write cmdfile 'command_file'
$!    write cmdfile "r um:uct_define_samples"
$!    write cmdfile "0"
$!    write cmdfile "0"
$!    write cmdfile " " 
$!    write cmdfile " " 
$!    write cmdfile "F"
$!    close cmdfile
$!    @'command_file'
$!
$!    ! Read write_info output to get sample_no max
$!    open/read res_file 'res_file'
$!    sample_no_max = 0
$!    read_loop:
$!      read/end_of_file=exit_loop res_file res_line 
$!      !sh sym res_line
$!
$!      res_line = f$edit(res_line, "trim,compress") 
$!      !sh sym res_line
$!      sample_nb = f$element(1," ",res_line)
$!      !sh sym sample_nb
$!      if (sample_nb .gt. sample_no_max) then sample_no_max = sample_nb
$!      goto read_loop
$!    exit_loop:
$!    close res_file 
$!    sh sym sample_no_max
$!    p2 = sample_no_max + 1
$!    say "!! New sample number ''p2'"
$  endif
$
$   ! Import ISQ
$    call create__timestamp f_uid
$    command_file := sys$scratch:uct_import_isq_'f_uid'.com
$    open/write cmdfile 'command_file'
$    write cmdfile "$!"
$    write cmdfile "$! Starting Re-Import of the reformatted ISQ"
$    write cmdfile "$   RUN UM:UCT_IMPORT.EXE"
$    write cmdfile "''p1'" ! ISQ file
$    write cmdfile "''p2'" ! Sample number
$    write cmdfile "Y" ! change name in header
$    write cmdfile "0" ! operator
$    write cmdfile "0" ! ctrlfile
$    write cmdfile "Y" ! rename file
$    close cmdfile
$    type 'command_file'
$    say "  "
$    say "Starting Re-Import of the reformatted ISQ"
$    @'command_file'
$    wait 00:00:01
$    say "Re-Import completed"
$
$
$ ! Extract imported measurement number / directory
$    say "  "
$    say "Search for new measurement number"
$    search_str = "IMPORT: New Measurement Directory:" ! Do not sh sym search_str otherwise it will mess with skips !!
$    pipe search '__ii_logfile' "''search_str'" 'import_skip' | (read sys$input line ; define/job/nolog line_tot &line)
$    new_dir = f$edit(f$trnlnm("line_tot"), "trim,compress") - search_str
$    sh sym new_dir
$
$ 	 new_meas_no = f$element(3,".",new_dir)
$    new_meas_no = f$integer(f$edit(new_meas_no - "]","trim,compress"))
$    sh sym new_meas_no
$
$   '__ii_sym'__new_meas_no == new_meas_no
$   sh sym '__ii_sym'*
$
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
$!#
$ say "!! IMPORT_ISQ.COM:	Completed "
$ say "=========================================================="
$ exit
$!
$ terminate:
$  @ez:helper IMPORT_ISQ.COM
$ exit
