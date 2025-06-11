$!************************* EZ_IPL *****************************************           
$!
$! ADD_GOBJS.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2025.02.02
$!  Copyright (c) 2025 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Add two up to seven GOBJs into one
$! 
$! USAGE:
$!  $ @ez:add_gobjs  'gobj1' 'gobj2' ... '*gobj7' 'sum_gobj_filename'
$! 
$! PARAMETERS:
$!  P1  : Input GOBJ 1
$!  P2  : Input GOBJ 2
$!  ...
$!  Pj  : Input GOBJ j (max 7)
$!  Pj+1: sum of GOBJs
$!
$! EXAMPLE:
$!   Add three GOBJs into 'total_gobj'
$!   $ @ez:add_gobjs  'gobj1_file' 'gobj2_file' 'gobj3_file' 'total_gobj'
$!
$! VERSION HISTORY:
$!  2025.02.02 Created (for ThermOA)
$!
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! ADD_GOBJs.COM: "
$ say "=========================================================="
$!*
$
$! requires minimum two input GOBJs and one output GOBJ
$  if (p1 .eqs. "") then goto terminate
$  if (p2 .eqs. "") then goto terminate
$  if (p3 .eqs. "") then goto terminate
$  
$  j = 1
$  pj_loop:
$    if (j .eq. 8) then goto exit_pj_loop 
$    k = j + 1
$    sh sym p'j'
$    if (p'k' .eqs. "") then goto exit_pj_loop
$    j = k
$    goto pj_loop
$
$  exit_pj_loop:
$   nb_inputs    = j - 1
$   index_output = j
$   say "!! Number of input GOBJs: ''nb_inputs' "
$   say "!! Index of output GOBJ: ''index_output' "
$
$   ipl_tmp_file = p1 - ".GOBJ" + "_ADDGOBJS_TMP.COM"
$   open/write comfile 'ipl_tmp_file' 
$   write comfile "$ ipl_batch"
$   write comfile "/gobj_to_aim ''p1' in 0"
$   i = 1
$   write_loop: 
$     i = i+1
$     gobj_file = p'i'
$     write comfile "/gobj_to_aim ''gobj_file' in2 0"
$     write comfile "/add in in2 out"
$     write comfile "/rename out in"
$     if (i .lt. nb_inputs) then goto write_loop
$   gobj_out_file = p'index_output'
$   write comfile "/togobj_from_aim in ''gobj_out_file'" 
$   write comfile ".."
$   write comfile "$ exit"
$   close comfile
$
$   ! type 'ipl_tmp_file'
$   @'ipl_tmp_file'
$   delete 'ipl_tmp_file';*
$
$ exit
$!#
$ say "!! ADD_GOBJs.COM: completed."
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper ADD_GOBJS.COM
$ exit