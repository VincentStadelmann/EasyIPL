$! If P2 = New -> determine the latest sample nb
$  if (p2 .eqs. "NEW")
$    then 
$    call create__timestamp f_uid
$    command_file := sys$scratch:uct_write_cmd_'f_uid'.txt
$    res_file := sys$scratch:uct_write_'f_uid'.txt
$    
$    ! Use write_info to get sample list
$    open/write cmdfile 'command_file'
$    write cmdfile "DEFINE/PROCESS uct_db_info ''res_file'"
$    write cmdfile "$   RUN UM:UCT_WRITE_INFO.EXE"
$    write cmdfile "0"
$    write cmdfile "0"
$    write cmdfile " " 
$    write cmdfile " " 
$    write cmdfile "F"
$    close cmdfile
$    @'command_file'
$
$    ! Read write_info output to get sample_no max
$    open/read res_file 'res_file'
$    sample_no_max = 0
$    read_loop:
$      read/end_of_file=exit_loop res_file res_line 
$      !sh sym res_line
$
$      res_line = f$edit(res_line, "trim,compress") 
$      !sh sym res_line
$      sample_nb = f$element(1," ",res_line)
$      !sh sym sample_nb
$      if (sample_nb .gt. sample_no_max) then sample_no_max = sample_nb
$      goto read_loop
$    exit_loop:
$    close res_file 
$    sh sym sample_no_max
$    p2 = sample_no_max + 1
$    say "!! New sample number ''p2'"
$  endif