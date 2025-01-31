$!*************************************************            
$! GET__REG_CORRS.COM
$! 
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
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
$!
$! DESCRIPTION:
$!  Get correlation coefficients after registration into a symbol 
$!
$! PARAMETERS:
$!  P1 : aim file
$!  P2 : ref aim file
$!  P3 : log name
$!  P4 : orientation search used for registration 
$!  P5 : output symbol name
$!
$! USAGE:
$!  @'scripts_dir'get__reg_corrs.com	'aim_filename' 'ref_filename' 'log_filename' 'orientation_search' 'output_variable'
$!
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! GET__REG_CORRS.COM  "
$ say "=========================================================="
$!*
$
$ !slow down output rate for readout
$   set output_rate=00:00:01
$   wait 00:00:01
$
$   if (p1 .eqs. "") then goto terminate
$   if (p2 .eqs. "") then goto terminate
$   if (p3 .eqs. "") then goto terminate
$   if (p4 .eqs. "") then p4 = 2    !! Later: look into log file for actual value
$   if (p5 .eqs. "") then p5 = "reg_corr"
$
$   show symbol p1
$   show symbol p2
$   show symbol p3
$   show symbol p4
$   show symbol p5
$
$! Prepare variable name
$   if (p5 .eqs. "")
$     then 
$       variable_name = "reg_corr__"
$     else
$       variable_name := 'p5'__
$   endif
$   show symbol variable_name
$!
$! Prepare skips 
$! TBD if multiple registrations in a single script. 
$
$! Extract correlation coefficients:
$!  if orientation search > 2 outputs are different.
$   if (p5 .ge. 3) 
$     then
$		! orientation search was used in reg:
$		! Get correlation coefficients
$       pipe search 'p3' "!%    Best results found for orientation:"| (read sys$input line ; define/job/nolog line_tot &line)
$       cor1 = f$extract(53,8,f$trnlnm("line_tot"))
$       pipe search 'p3' "!% Corr. coeff.:" | (read sys$input line ; define/job/nolog line_tot &line)
$       cor2 = f$extract(22,8,f$trnlnm("line_tot"))
$       pipe search 'p3' "!% Corr. coeff.:" /skip=1 | (read sys$input line ; define/job/nolog line_tot &line)
$       cor3 = f$extract(22,8,f$trnlnm("line_tot"))
$     else
$		! Get correlation coefficients
$       pipe search 'p3' "!% Corr. coeff.:"| (read sys$input line ; define/job/nolog line_tot &line)
$       cor1 = f$extract(22,8,f$trnlnm("line_tot"))
$       pipe search 'p3' "!% Corr. coeff.:" /skip=1 | (read sys$input line ; define/job/nolog line_tot &line)
$       cor2 = f$extract(22,8,f$trnlnm("line_tot"))
$       pipe search 'p3' "!% Corr. coeff.:" /skip=2 | (read sys$input line ; define/job/nolog line_tot &line)
$       cor3 = f$extract(22,8,f$trnlnm("line_tot"))
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
$    'variable_name'corr_coeff1 == cor1
$    'variable_name'corr_coeff2 == cor2
$    'variable_name'corr_coeff3 == cor3
$
$    icalc  floor(100 * 'cor1')
$    'variable_name'corr_coeff1_pc == icalc_out
$    icalc  floor(100 * 'cor2')
$    'variable_name'corr_coeff2_pc == icalc_out
$    icalc  floor(100 * 'cor3')
$    'variable_name'corr_coeff3_pc == icalc_out
$
$    sh sym 'variable_name'*
$
$ say "!! GET__REG_CORRS.COM: Completed"
$ say "=========================================================="
$!
$ exit  
$!
$ terminate:
$   say "!! P1: AIM input"
$   say "!! P2: Reference AIM "
$   say "!! P3: Log filename"
$   say "!! P4: Orientation search"
$   say "!! P5: Symbol output"
$   exit
