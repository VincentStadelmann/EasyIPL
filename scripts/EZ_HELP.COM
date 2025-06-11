$!****************************************************************************************            
$! helper.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.10.20
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! VERSION HISTORY:
$!  2018.10.20 Created
$!  2018.12.03 Header_line and Print_line to skip COPYRIGHTS and VERSION HISTORY
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
$ !sh sym p1
$
$!-------------------------------------------------------------
$! Test inputs 
$!-------------------------------------------------------------
$
$ if (p1 .eqs. "") then goto terminate
$ if (f$locate(".COM", p1) .eq. f$length(p1)) then p1 = p1 + ".COM"
$ __ez_script := ez:'p1'
$ !sh sym __ez_script
$ if (f$search(__ez_script) .eqs. "")
$  then
$    say "!! Error:  script file does not exist."
$    exit
$ endif
$
$!-------------------------------------------------------------
$! Init variables and files for search
$!-------------------------------------------------------------
$ ! tmp help file
$ __ez_tmp_help = "SYS$SCRATCH:" + p1 - ".COM" + "_TMP_HELP.TXT"
$
$ ! booleans for detecting relevant info
$  header_line = "FALSE"
$  print_line = "TRUE"
$
$  ! open files for read/write
$  open/read script_file '__ez_script'
$  open/write tmp_help '__ez_tmp_help'
$
$  ! search for tmp help file to get version nb
$  __ez_tmp_help = f$search("''__ez_tmp_help'")
$  !sh sym __ez_tmp_help
$
$!-------------------------------------------------------------
$! Select relevant help from script header 
$!-------------------------------------------------------------
$  ! read script line by line  
$  ! and copy relevant data to tmp file
$  i = 0
$  read_loop:
$    read/end_of_file=exit_read_loop script_file script_line 
$    ! sym script_line
$
$    ! check for beginning/end of header
$    __floc1 = f$locate("$!*************************", script_line)
$    __flen = f$length(script_line)
$    ! sh sym __floc1
$    ! sh sym __flen1
$
$    if (__floc1 .lt. __flen) 
$     then 
$       if (header_line .eqs. "TRUE")  
$         then 
$           header_line = "FALSE"
$         else
$           header_line = "TRUE"
$       endif
$     goto read_loop
$    endif
$
$    ! skip copyrights and version history
$    __floc2 = f$locate("COPYRIGHTS", script_line)
$    __floc3 = f$locate("VERSION HISTORY", script_line)
$    __floc4 = f$locate("DESCRIPTION", script_line)
$    __floc5 = f$locate("USAGE", script_line)
$    __floc6 = f$locate("PARAMETERS", script_line)
$    __floc7 = f$locate("EXAMPLE", script_line)
$    if (__floc2 .lt. __flen .or. __floc3 .lt. __flen) then print_line = "FALSE"
$    if (__floc4 .lt. __flen .or. __floc5 .lt. __flen) then print_line = "TRUE"
$    if (__floc6 .lt. __flen .or. __floc6 .lt. __flen) then print_line = "TRUE"
$
$    ! Print lines of help to temp file
$    if (print_line .eqs. "TRUE" .and. header_line .eqs. "TRUE") 
$      then
$        script_line = script_line - "$!"
$        write/symbol tmp_help script_line
$    endif
$    goto read_loop
$
$  exit_read_loop:
$  close tmp_help
$  close script_file
$ 
$!-------------------------------------------------------------
$! Show tmp file 
$!-------------------------------------------------------------
$
$  type '__ez_tmp_help'
$  delete '__ez_tmp_help'
$
$ !say "!! helper.COM: Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  say "!! P1  : name of script"
$ exit