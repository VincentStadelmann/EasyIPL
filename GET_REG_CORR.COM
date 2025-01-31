$!*************************************************            
$! GET_REG_CORR.COM
$! 
$!  Written by: Vincent Stadelmann 2013.12.16
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Get registration correlation coefficients into a symbol 
$!  Currently only works with one registration per script
$!
$! PARAMETERS:
$!  P1  : output symbol name 
$!  P2* : log filename       (*eval_logfile2)
$!
$! USAGE:
$!  @ez:get_reg_corr	 'output_var' '*log_file'
$!
$! VERSION HISTORY:
$!  2013.12.16 V. stadelmann 
$!  2015.04.17 stv create result file if does not exist
$!  2016.06.28 template as p4
$!  2016.08.05 orientation search: if p5=1, different outcomes
$!				!%    Best results found for orientation:    4 corr= 0.910218
$!              !% -- Starting registration with resolution_scaling set to:  4 --
$!
$!  2016.08.30 Try to adapt to IPL 1.08
$!  2016.11.15 orientation search: p5=reg_init, different outcomes
$!				!%    Best results found for orientation:    4 corr= 0.910218
$!              !% -- Starting registration with resolution_scaling set to:  4 --
$!  2016.11.25 Added ref-file as p2: reference data also in export sheet
$!  2017.07.18 Writes results to global variable output_variable
$!  2018.01.16 Bug fix in if else structure p5
$!  2018.08.27 New name. Leave out write to files. Can be done in new extract_results.com
$!  2019.03.18 EZ format. Parameters: Only log and variable_out. Search in log for orientation
$!  2022.10.31 Warning!! Reverse parameters order to leave log file optional
$!  2023.03.17 Added get__regcorr_skip to enable multiple use in single script 
$!  2025.01.28 Renamed get_reg_corr.com and added help menu 
$!
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! GET_REG_CORR.COM  "
$ say "=========================================================="
$!*
$
$ if (p1 .eqs. "") then goto terminate
$   if (p2 .eqs. "") then p2 = eval_logfile2
$
$ if f$search("''p2'") .eqs. ""
$  then
$    say "!! ERROR:  log file does not exist."
$    goto terminate
$ endif
$
$ set output_rate=00:00:01
$ wait 00:00:01
$
$ show symbol p1
$ show symbol p2
$
$! init variables
$   __grc_logfile = p2
$   __grc_sym     = p1
$   sh sym __grc_logfile
$   sh sym __grc_sym
$
$! Init skip variables if needed
$! skip1 for orientation-search / skip2 for coeffs search
$ if (f$type(get__regcorr_skip1) .eqs. "") then get__regcorr_skip1 == 0
$ if (f$type(get__regcorr_skip2) .eqs. "") then get__regcorr_skip2 == 0
$
$! Prepare skip strings
$! /SKIP=0 is invalid -> must split in two ifs
$ if (get__regcorr_skip1 .eq. 0) then orientation_skip := ""
$ if (get__regcorr_skip1 .gt. 0) then orientation_skip := "/skip=''get__regcorr_skip1'"
$! increment skip1
$ get__regcorr_skip1 == get__regcorr_skip1 + 1 
$
$! skip2 for correlation coeffs
$ if (get__regcorr_skip2 .eq. 0) 
$   then 
$     skip_1 := ""
$     skip_2 := "/skip=1"
$     skip_3 := "/skip=2"
$ else
$     skip_1 := "/skip=''get__regcorr_skip2'"
$     icalc 'get__regcorr_skip2' + 1
$     skip_2 := "/skip=''icalc_out'"
$     icalc 'get__regcorr_skip2' + 2
$     skip_3 := "/skip=''icalc_out'"
$ endif
$ sh sym *skip*
$
$
$! Search in log file for orientation_search parameter
$  pipe search '__grc_logfile' "-orientation_search" 'orientation_skip' | (read sys$input line ; define/job/nolog line_tot &line)
$  orientation_search = f$integer(f$edit(f$trnlnm("line_tot") - "-orientation_search","trim,compress"))
$  sh sym orientation_search
$
$! Extract correlation coefficients:
$   say " "
$!  if orientation search > 2 outputs are different.
$   if ('orientation_search' .ge. 3) 
$     then
$		! orientation search > 2 was used in reg:
$		! Get correlation coefficients
$       say "!! Orientation_search > 2"
$       pipe search '__grc_logfile' "!%    Best results found for orientation:" 'skip'| (read sys$input line ; define/job/nolog line_tot &line)
$       cor1 = f$extract(53,8,f$trnlnm("line_tot"))
$       pipe search '__grc_logfile' "!% Corr. coeff.:"  'skip_1'| (read sys$input line ; define/job/nolog line_tot &line)
$       cor2 = f$extract(22,8,f$trnlnm("line_tot"))
$       pipe search '__grc_logfile' "!% Corr. coeff.:" 'skip_2' | (read sys$input line ; define/job/nolog line_tot &line)
$       cor3 = f$extract(22,8,f$trnlnm("line_tot"))
$       ! # increment get__regcorr_skip
$       get__regcorr_skip2 == get__regcorr_skip2 + 2
$     else
$       say "!! Orientation_search <= 2"
$       pipe search '__grc_logfile' "!% Corr. coeff.:" 'skip_1'| (read sys$input line ; define/job/nolog line_tot &line)
$       cor1 = f$extract(22,8,f$trnlnm("line_tot"))
$       pipe search '__grc_logfile' "!% Corr. coeff.:" 'skip_2' | (read sys$input line ; define/job/nolog line_tot &line)
$       cor2 = f$extract(22,8,f$trnlnm("line_tot"))
$       pipe search '__grc_logfile' "!% Corr. coeff.:" 'skip_3' | (read sys$input line ; define/job/nolog line_tot &line)
$       cor3 = f$extract(22,8,f$trnlnm("line_tot"))
$       get__regcorr_skip2 == get__regcorr_skip2 + 3
$  endif
$
$  if (cor1 .eqs. "o string") then cor1 := 0.0
$  if (cor2 .eqs. "o string") then cor2 := 0.0
$  if (cor3 .eqs. "o string") then cor3 := 0.0
$  sh sym cor1
$  sh sym cor2
$  sh sym cor3
$
$! Adding results to global_variable
$   @ez:vector__make '__grc_sym' 'cor1' 'cor2' 'cor3'
$   @ez:vector__multiply 'cor1','cor2','cor3' 100 __grc_tmp
$   @ez:vector__floor '__grc_tmp' '__grc_sym'__pc
$
$ say "!! GET_REG_CORR.COM: Completed"
$ say "=========================================================="
$!
$ exit  
$!
$ terminate:
$    @ez:helper GET_REG_CORR
$   exit
