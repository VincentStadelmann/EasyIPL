$!*************************************************            
$! EXTRACT_REG_CORR2.COM
$! 2013.12.16 V. stadelmann 
$! 2015.04.17 stv create result file if does not exist
$! 2016.06.28 template as p4
$! 2016.08.05 orientation search: if p5=1, different outcomes
$!				!%    Best results found for orientation:    4 corr= 0.910218
$!              !% -- Starting registration with resolution_scaling set to:  4 --
$!
$! 2016.08.30 Try to adapt to IPL 1.08
$! 2016.11.15 orientation search: p4=reg_init, different outcomes
$!				!%    Best results found for orientation:    4 corr= 0.910218
$!              !% -- Starting registration with resolution_scaling set to:  4 --
$! 2016.11.25 Added ref-file as p2: reference data also in export sheet
$! 
$! USAGE:
$!  @'scripts_dir'extract_reg_corr2.com	'aim_filename' 'ref_filename' 'log_filename' 'results_filname' 'orientation_search'
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! EXTRACT_REG_CORR2.COM:								 "
$ say "=========================================================="
$!*
$   show symbol p1
$   show symbol p2
$   show symbol p3
$   show symbol p4
$   show symbol p5
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
$   if p5 .ge. 3 then goto orientation_search
$!
$! Correlation coefficients
$    pipe search 'p3' "!% Corr. coeff.:"| (read sys$input line ; define/job line_tot &line)
$    cor1 = f$extract(22,8,f$trnlnm("line_tot"))
$    sh sym cor1
$!
$    pipe search 'p3' "!% Corr. coeff.:" /skip=1 | (read sys$input line ; define/job line_tot &line)
$    cor2 = f$extract(22,8,f$trnlnm("line_tot"))
$    sh sym cor2
$!
$    pipe search 'p3' "!% Corr. coeff.:" /skip=2 | (read sys$input line ; define/job line_tot &line)
$    cor3 = f$extract(22,8,f$trnlnm("line_tot"))
$    sh sym cor3
$!
$! If orientation search was used in reg:
$  	 orientation_search:
$     say "!! Orientation search ON: "
$     pipe search 'p3' "!%    Best results found for orientation:"| (read sys$input line ; define/job line_tot &line)
$     cor1 = f$extract(53,8,f$trnlnm("line_tot"))
$     sh sym cor1
$!
$     pipe search 'p3' "!% Corr. coeff.:" | (read sys$input line ; define/job line_tot &line)
$     cor2 = f$extract(22,8,f$trnlnm("line_tot"))
$     sh sym cor2
$!
$     pipe search 'p3' "!% Corr. coeff.:" /skip=1 | (read sys$input line ; define/job line_tot &line)
$     cor3 = f$extract(22,8,f$trnlnm("line_tot"))
$     sh sym cor3
$!
$ data_line = "''sample_name', ''sample_no', ''meas_no', ''ref_sample_name', ''ref_sample_no', ''ref_meas_no', ''cor1', ''cor2', ''cor3'"
$ sh sym data_line
$!
$ say "!! Writing data_line to ''p4': "
$ open/append output_file 'p4'
$ write output_file "''data_line'"
$ close output_file
$!
$ say "!! EXTRACT_REG_CORR2.COM: COMPLETED"
$ say "=========================================================="
$!
$ exit  
