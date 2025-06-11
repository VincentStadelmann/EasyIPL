$!*************************************** Easy_IPL *****************************************           
$!
$! CREATE_SAMPLE.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2019.09.02
$!  Copyright (c) 2019 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Creates an entry in DB
$! 
$! USAGE:
$!  $ @ez:create_sample 	'sample_name' var_out
$! 
$! PARAMETERS:
$!  P1  : Sample name
$!  P2* : Variable name that will contain sampname and sampno (*newsample)
$!
$! EXAMPLE:
$!  
$!
$! VERSION HISTORY:
$! 
$!
$!******************************************************************************************           
$
$ on error then exit
$ set output_rate=00:00:01
$
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! CREATE_SAMPLE.COM:  "
$ say "=========================================================="
$!*
$  	if (p1 .eqs. "") then goto terminate
$  	if (p2 .eqs. "") then p2 := newsample
$
$   ! Create sample
$    call create__timestamp f_uid
$    create_cmd_file := sys$scratch:create_sample_'f_uid'.com
$    create_log_file := sys$scratch:create_sample_'f_uid'.log
$    open/write createcmdfile 'create_cmd_file'
$    write createcmdfile "$! Create sample"
$    write createcmdfile "$ r um:uct_define_samples"
$    write createcmdfile "''p1'"
$    write createcmdfile "0" !
$    write createcmdfile "0" ! 
$    write createcmdfile "Y" ! 
$    close createcmdfile
$    type 'create_cmd_file'
$    say "Starting Re-Import of the reformatted ISQ"
$    @'create_cmd_file' /output='create_log_file'
$
$!  ! search log file to determine sampno
$   pipe search 'create_log_file' "Created" | (read sys$pipe line ; define/job/nolog line_log &line)
$   line_sym = f$trnlnm("line_log")- "Created"
$   line_sym = f$edit(line_sym,"trim,compress")  
$   sampno = f$edit(f$element(0,":",line_sym),"trim,compress") 
$   sampname = f$edit(f$element(1,":",line_sym),"trim,compress") 
$   'p2'__sampno == sampno
$   'p2'__sampname == sampname
$   sh sym 'p2'*
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
$ say "!! CREATE_SAMPLE.COM:	Completed "
$ say "=========================================================="
$ exit
$!
$ terminate:
$  @ez:helper CREATE_SAMPLE.COM
$ exit
