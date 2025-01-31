$!*************************************************            
$! EXTRACT_REG_RESULTS.COM
$! 2013.12.16 V. stadelmann 
$! 2015.04.17 stv create result file if does not exist
$! 2016.06.28 template as p4
$! 2016.08.05 orientation search: if p5=1, different outcomes
$!				!%    Best results found for orientation:    4 corr= 0.910218
$!              !% -- Starting registration with resolution_scaling set to:  4 --

$! 
$! usage:
$!  @'ipl_script_dir'extract_reg_results.com	'aim_filename' 'log_filename' 'results_filname' 'template_filename' 'orientation_search'
$!*************************************************            
$!
$ 	write sys$output ">>> "
$ 	write sys$output ">>> EXTRACT_REG_RESULTS.COM"
$   show symbol p1
$   show symbol p2
$   show symbol p3
$   show symbol p4
$   show symbol p5
$!
$! If no template is provided, use default
$    if p4 .eqs. ""
$      then 
$        p4 :== "ADISK1:[VIVACT.COM.TEMPLATES]REGCOR_HEADERS.T"
$    endif
$!
$! If output file doesnt exist, create it. 
$    if f$search("''p3'") .eqs. ""
$     then
$ 		write sys$output ">>> Creating output file"
$		copy 'p4' 'p3'
$    endif
$!
$! lookup for sample data from aim
$  pipe aix 'p1' | search sys$pipe "index measurement"| (read sys$input line ; define/job line_log &line)
$  meas_no = f$edit(f$extract(45,8,f$trnlnm("line_log")),"trim,compress")
$  sh sym meas_no
$!
$  pipe aix 'p1' | search sys$pipe "index patient"| (read sys$input line ; define/job line_samno &line)
$  sample_no = f$edit(f$extract(45,8,f$trnlnm("line_samno")),"trim,compress")
$  sh sym sample_no
$!
$  pipe aix 'p1' | search sys$pipe "patient name"| (read sys$input line ; define/job line_samname &line)
$  sample = f$edit(f$extract(30,20,f$trnlnm("line_samname")),"trim,compress")
$  sh sym sample
$!
$! correlation coefficients
$  pipe search 'p2' "!% corr. coeff.:"| (read sys$input line ; define/job line_tot &line)
$  cor1 = f$extract(22,8,f$trnlnm("line_tot"))
$  sh sym cor1
$!
$! correlation coefficients
$  pipe search 'p2' "!% corr. coeff.:" /skip=1 | (read sys$input line ; define/job line_tot &line)
$  cor2 = f$extract(22,8,f$trnlnm("line_tot"))
$  sh sym cor2
$!
$! correlation coefficients
$  pipe search 'p2' "!% corr. coeff.:" /skip=2 | (read sys$input line ; define/job line_tot &line)
$  cor3 = f$extract(22,8,f$trnlnm("line_tot"))
$  sh sym cor3
$!
$! If orientation search was used in reg:
$  	  if p5 .eqs. "1" 
$	   	then
$         pipe search 'p2' "!%    Best results found for orientation:"| (read sys$input line ; define/job line_tot &line)
$         cor1 = f$extract(53,8,f$trnlnm("line_tot"))
$         sh sym cor1
$!
$         pipe search 'p2' "!% -- Starting registration with resolution_scaling set to:" /skip=1 | (read sys$input line ; read sys$input line ; define/job line_tot &line)
$         cor2 = f$extract(22,8,f$trnlnm("line_tot"))
$         sh sym cor2
$!
$         pipe search 'p2' "!% corr. coeff.:" /skip=2 | (read sys$input line ; define/job line_tot &line)
$         cor3 = f$extract(22,8,f$trnlnm("line_tot"))
$         sh sym cor3
$	  endif
$!
$ data_line = "''sample', ''sample_no', ''meas_no', ''cor1', ''cor2', ''cor3'
$ sh sym data_line
$!
$ open/append output_file 'p3'
$ write output_file "''data_line'"
$ close output_file
$ write sys$output ">>> EXTRACT_REG_RESULTS.COM: COMPLETED"
$ write sys$output ">>> "
$!
$ exit  
