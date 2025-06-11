$!************************* EZ_IPL *****************************************           
$!
$! GET_TH_MIN_MAX.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.12.17
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Get max min thickness from histogram into symbol
$! 
$! USAGE:
$!  @ez:get_th_min_max 'histo_file' 'variable_out' 
$!
$! PARAMETERS:
$!  P1  : Input histogram file
$!  P2* : Variable out         (*aim)
$!
$! EXAMPLE:
$!  
$!
$! 
$! VERSION HISTORY:
$!  2018.12.17 Created
$! 
$!***************************************************************************            
$!
$ say = "write sys$output
$ set output_rate=00:00:01
$ say " 
$ say "==========================================================
$ say "!! GET_TH_MIN_MAX.COM:	
$ say "=========================================================="
$!*
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 := aim
$
$ show symbol p1
$ show symbol p2
$
$ if (f$search("''p1'") .eqs. "")
$  then
$    say "!! ERROR:  histogram file does not exist.
$    goto terminate
$ endif
$
$! Setup output variable
$ variable_name = "''p2'__
$ show symbol variable_name
$!
$ __gtmm_i = 0
$ open/read __histofile 'p1'
$ loop_histo:
$   read/end_of_file=end_histo __histofile __histo_line
$   __gtmm_i = __gtmm_i + 1
$   __histo_line_'__gtmm_i' = __histo_line
$!   sh sym __histo_line_'__gtmm_i'
$   goto loop_histo
$
$ end_histo:
$  !extract th min from line 19
$  __line_min = f$edit(__histo_line_19,"trim,compress")
$  __th_min = f$element(0," ",__line_min)
$
$  !extract max from last line
$  __line_max = f$edit(__histo_line_'__gtmm_i',"trim,compress")
$  __th_max = f$element(0," ",__line_max)
$
$  close __histofile
$
$! Legacy 
$ 'variable_name'th_min == __th_min
$ 'variable_name'th_max == __th_max
$
$  sh sym 'variable_name'th*
$
$!#
$ say " 
$ say "!! GET_TH_MIN_MAX.COM: completed
$ say "==========================================================
$ exit
$!
$ terminate:
$    @ez:helper GET_TH_MIN_MAX.com
$   exit