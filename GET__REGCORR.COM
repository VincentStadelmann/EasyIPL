$!*************************************************            
$! GET__REGCORR.COM
$! 2013.12.16 V. stadelmann 
$! 2015.04.17 stv create result file if does not exist
$! 2016.06.28 template as p4
$! 2016.08.05 orientation search: if p5=1, different outcomes
$!				!%    Best results found for orientation:    4 corr= 0.910218
$!              !% -- Starting registration with resolution_scaling set to:  4 --
$!
$! 2016.08.30 Try to adapt to IPL 1.08
$! 2016.11.15 orientation search: p5=reg_init, different outcomes
$!				!%    Best results found for orientation:    4 corr= 0.910218
$!              !% -- Starting registration with resolution_scaling set to:  4 --
$! 2016.11.25 Added ref-file as p2: reference data also in export sheet
$! 2017.07.18 Writes results to global variable output_variable
$! 2018.01.16 Bug fix in if else structure p5
$! 
$! USAGE:
$!  @'scripts_dir'get__regcorr.com	'aim_filename' 'ref_filename' 'log_filename' 'results_filname' 'orientation_search' 'output_variable'
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! GET__REGCORR.COM  "
$ say "=========================================================="
$!*
$
$ set output_rate=00:00:01
$ wait 00:00:01
$
$ if (p6 .eqs. "") then p6 := reg_corr
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$ show symbol p5
$ show symbol p6
$!
$ head_line := "SampName, SampNo, MeasNo, RefSampName, RefSampNo, RefMeasNo, Correlation1, Correlation2, Correlation3"
$!
$! If output file doesnt exist, create it. 
$    if f$search("''p4'") .eqs. ""
$     then
$ 		say "!! Creating output file"
$       open/write output_file 'p4'
$       write output_file "''head_line'"
$       close output_file
$    endif
$!
$! Lookup for sample data from AIM1
$   pipe aix 'p1' | search sys$pipe "index measurement"| (read sys$input line ; define/job line_log &line)
$   meas_no = f$edit(f$extract(45,8,f$trnlnm("line_log")),"trim,compress")
$   sh sym meas_no
$!
$   pipe aix 'p1' | search sys$pipe "index patient"| (read sys$input line ; define/job line_samno &line)
$   sample_no = f$edit(f$extract(45,8,f$trnlnm("line_samno")),"trim,compress")
$   sh sym sample_no
$!
$   pipe aix 'p1' | search sys$pipe "patient name"| (read sys$input line ; define/job line_samname &line)
$   sample_name = f$edit(f$trnlnm("line_samname"),"trim,compress") - "Patient Name "
$   sh sym sample_name
$!
$! Lookup for sample data from REF AIM
$   pipe aix 'p2' | search sys$pipe "index measurement"| (read sys$input line ; define/job line_log &line)
$   ref_meas_no = f$edit(f$extract(45,8,f$trnlnm("line_log")),"trim,compress")
$   sh sym ref_meas_no
$!
$   pipe aix 'p2' | search sys$pipe "index patient"| (read sys$input line ; define/job line_samno &line)
$   ref_sample_no = f$edit(f$extract(45,8,f$trnlnm("line_samno")),"trim,compress")
$   sh sym ref_sample_no
$!
$   pipe aix 'p2' | search sys$pipe "patient name"| (read sys$input line ; define/job line_samname &line)
$   ref_sample_name = f$edit(f$trnlnm("line_samname"),"trim,compress") - "Patient Name "
$   sh sym ref_sample_name
$!
$! Extract correlation coefficients:
$!  if orientation search > 2 outputs are different.
$   if (p5 .ge. 3) 
$     then
$		! orientation search was used in reg:
$		! Get correlation coefficients
$       pipe search 'p3' "!%    Best results found for orientation:"| (read sys$input line ; define/job line_tot &line)
$       cor1 = f$extract(53,8,f$trnlnm("line_tot"))
$       pipe search 'p3' "!% Corr. coeff.:" | (read sys$input line ; define/job line_tot &line)
$       cor2 = f$extract(22,8,f$trnlnm("line_tot"))
$       pipe search 'p3' "!% Corr. coeff.:" /skip=1 | (read sys$input line ; define/job line_tot &line)
$       cor3 = f$extract(22,8,f$trnlnm("line_tot"))
$     else
$		! Get correlation coefficients
$       pipe search 'p3' "!% Corr. coeff.:"| (read sys$input line ; define/job line_tot &line)
$       cor1 = f$extract(22,8,f$trnlnm("line_tot"))
$       pipe search 'p3' "!% Corr. coeff.:" /skip=1 | (read sys$input line ; define/job line_tot &line)
$       cor2 = f$extract(22,8,f$trnlnm("line_tot"))
$       pipe search 'p3' "!% Corr. coeff.:" /skip=2 | (read sys$input line ; define/job line_tot &line)
$       cor3 = f$extract(22,8,f$trnlnm("line_tot"))
$  endif
$  if (cor1 .eqs. "o string") then cor1 := 0.0
$  if (cor2 .eqs. "o string") then cor2 := 0.0
$  if (cor3 .eqs. "o string") then cor3 := 0.0
$  sh sym cor1
$  sh sym cor2
$  sh sym cor3
$
$! Writing results to result file:
$   say "!! Writing data_line to ''p4': "
$   data_line = "''sample_name', ''sample_no', ''meas_no', ''ref_sample_name', ''ref_sample_no', ''ref_meas_no', ''cor1', ''cor2', ''cor3'"
$   sh sym data_line
$   open/append output_file 'p4'
$   write output_file "''data_line'"
$   close output_file
$!
$! Adding results to global_variable
$    'p6'__cor1 == cor1
$    'p6'__cor2 == cor2
$    'p6'__cor3 == cor3
$
$    icalc  floor(100 * 'cor1')
$    'p6'__cor1_pc == icalc_out
$    icalc  floor(100 * 'cor2')
$    'p6'__cor2_pc == icalc_out
$    icalc  floor(100 * 'cor3')
$    'p6'__cor3_pc == icalc_out
$
$    sh sym 'p6'__*
$!
$ say "!! GET__REGCORR.COM: Completed"
$ say "=========================================================="
$!
$ exit  
