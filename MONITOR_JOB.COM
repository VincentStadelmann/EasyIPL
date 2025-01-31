$! MONITOR_JOB.COM
$! 2018.06.18 V Stadelmann
$! Background backup task
$!
$ say == "write sys$output "
$ on error then continue
$ set output_rate=00:00:01
$
$ say " "
$ say "============================================================================="
$ say " MONITOR_JOB.COM "
$   
$
$   if (p1 .eqs. "") then goto terminate
$
$   show_output    := sys$scratch:mj_show_output_'p1'.txt
$
$   sh entry 'p1' /full /output='show_output'
$   say "!! show_output:"
$   type 'show_output' 
$
$
$   pipe search 'show_output' "/LOG" | (read sys$input line ; define/job/nolog pipe_message &line)
$   pipe_message == f$edit(f$trnlnm("pipe_message"), "trim,compress")
$  	if (pipe_message .eqs. "%SEARCH-I-NOMATCHES, no strings matched") 
$     then 
$        say "!! No jobs found with ID ''p1' "
$        goto complete
$   endif
$
$  	pipe search 'show_output' "/LOG=" | (read sys$input line ; define/job/nolog pipe_line &line)
$  	pipe_line == f$edit(f$trnlnm("pipe_message"), "trim,compress")
$   !sh sym pipe_line
$   drop_indice = 4+f$locate(".LOG",pipe_line)
$   !sh sym drop_indice
$   pipe_line_0 = f$extract(0,drop_indice,pipe_line)
$   !sh sym pipe_line_0
$ 
$   drop_indice = f$locate("/LOG=",pipe_line_0)
$   !sh sym drop_indice
$   pipe_line_1 = f$extract(0,drop_indice,pipe_line_0)
$   !sh sym pipe_line_1
$
$   res_line = pipe_line_0 - pipe_line_1      
$   !sh sym res_line
$   log_filename = res_line - "/LOG="
$   !show sym log_filename
$   del 'show_output';*
$
$   type 'log_filename'/cont/int=1
$   exit  
$
$ complete:
$  del 'show_output';*
$ exit
$ terminate:
$  say " P1: job number "
$ say "============================================================================="
$ exit
