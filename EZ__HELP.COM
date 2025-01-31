$!****************************************************************************************            
$! EZ__HELP.COM
$! 
$!  Written by: Vincent Stadelmann 2018.10.20
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! VERSION HISTORY:
$!  2018.10.20 Created
$! 
$! DESCRIPTION:
$!  Displays the header of an EasyIPL file
$! 
$! USAGE:
$!  @ez:helper 'ez_file'
$!
$! PARAMETERS:
$!  P1 : ez_file
$!
$!****************************************************************************************            
$!
$ say = "write sys$output"
$
$ !say "=========================================================="
$ !say "!! EZ__HELP.COM:  "
$ !say "=========================================================="
$!*
$! Test input 
$ if (p1 .eqs. "") then goto terminate
$ if (f$locate(".COM", p1) .eq. f$length(p1)) then p1 = p1 + ".COM"
$ ez_script := ez:'p1'
$ !sh sym ez_script
$ ez_tmp_help = "SYS$SCRATCH:" + p1 - ".COM" + "_TMP_HELP.TXT"
$ !sym ez_tmp_help
$
$ if (f$search(ez_script) .eqs. "")
$  then
$    say "!! Error:  script file does not exist."
$    goto terminate
$ endif
$
$  print_line = "FALSE"
$  open/read script_file 'ez_script'
$  open/write tmp_help 'ez_tmp_help'
$  i = 0
$  read_loop:
$    read/end_of_file=exit_read_loop script_file script_line 
$    ! sym script_line
$    __floc = f$locate("$!*************************", script_line)
$    __flen = f$length(script_line)
$    ! sh sym __floc
$    ! sh sym __flen
$
$    if (__floc .lt. __flen) 
$     then 
$       if (print_line .eqs. "TRUE")  
$         then 
$           print_line = "FALSE"
$         else
$           print_line = "TRUE"
$       endif
$     goto read_loop
$    endif
$    if (print_line .eqs. "TRUE") 
$      then
$        script_line = script_line - "$!"
$        write/symbol tmp_help script_line
$    endif
$    goto read_loop
$  exit_read_loop:
$  close tmp_help
$  close script_file
$ 
$  type 'ez_tmp_help'
$
$ !say "!! EZ__HELP.COM: Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  say "!! P1  : name of script"
$ exit
