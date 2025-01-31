$!************************* EZ_IPL *****************************************           
$!
$! ADD_AIMS.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.10.18
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Add two up to seven AIMs into one
$! 
$! USAGE:
$!  @ez:add_aims.com 'aim1_filename' 'aim2_filename' ... (min 2 - max 7) 'sum_filename'
$! 
$! PARAMETERS:
$!  P1  : Input AIM 1
$!  P2  : Input AIM 2
$!  ...
$!  Pj  : Input AIM j (max 7)
$!  Pj+1: sum of AIMs
$!
$! EXAMPLE:
$!   Add four AIMS (aim1_file...aim4_file) into 'sum_file'
$!   @ez:add_aims	'aim1_file' 'aim2_file' 'aim3_file' 'aim4_file' 'sum_file'
$!
$! VERSION HISTORY:
$!  2018.10.18 EZ format, multiple AIMs inputs
$!
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! ADD_AIMS.COM: "
$ say "=========================================================="
$!*
$
$! requires minimum two input AIMS and one output AIM
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
$   say "!! Number of input AIMS: ''nb_inputs' "
$   say "!! Index of output AIM: ''index_output' "
$
$   ipl_tmp_file = p1 - ".AIM" + "_ADD_TMP.COM"
$   open/write comfile 'ipl_tmp_file' 
$   write comfile "$ ipl_batch"
$   write comfile "/read in ''p1'"
$   i = 1
$   write_loop: 
$     i = i+1
$     aim_file = p'i'
$     write comfile "/read in2 ''aim_file'"
$     write comfile "/add in in2 out"
$     write comfile "/rename out in"
$     if (i .lt. nb_inputs) then goto write_loop
$   aim_file = p'index_output'
$   write comfile "/write in ''aim_file'"
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
$ say "!! ADD_AIMS.COM: completed."
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper ADD_AIMS.com
$ exit