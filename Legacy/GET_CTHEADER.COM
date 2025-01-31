$!*************************************************            
$! GET_CTHEADER.COM
$! 2017.06.15 VS
$! 
$! USAGE:
$!  @'scripts_dir'get_ctheader.com	'isq_filename' 'log_filename' 'skip'
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! GET_CTHEADER.COM: "
$ say "!!  Get SampleNo, MeasNo, SampleName, Dimensions, "
$ say "!!  Voxel size, ...	from ISQ file"
$ say "=========================================================="
$!*
$!
$   show symbol p1
$   show symbol p2
$   show symbol p3
$!
$   if p3 .eqs. "" then skip := ""
$   if p3 .nes. "" then skip := "/skip=''p3'"
$   if p3 .eqs. "0" then skip := ""
$   sh sym skip
$!
$! Search CT header
$!
$   pipe ctheader 'p1' | search sys$pipe "Patient Name :" 'skip'| (read sys$input line ; define/job line_log &line)
$   samp_name == f$edit(f$trnlnm("line_log") - "Patient Name :", "trim,compress")
$!
$   pipe ctheader 'p1' | search sys$pipe "Patient Index :" 'skip'| (read sys$input line ; define/job line_log &line)
$   samp_no == f$edit(f$trnlnm("line_log") - "Patient Index :", "trim,compress")
$!
$   pipe ctheader 'p1' | search sys$pipe "Measurement Index :" 'skip'| (read sys$input line ; define/job line_log &line)
$   meas_no == f$edit(f$trnlnm("line_log") - "Measurement Index :", "trim,compress")
$!
$   pipe ctheader 'p1' | search sys$pipe "Dim X :" 'skip'| (read sys$input line ; define/job line_log &line)
$   isq_dim_x == f$element(0, " ", f$edit(f$trnlnm("line_log") - "Dim X :", "trim,compress"))
$   pipe ctheader 'p1' | search sys$pipe "Dim Y :" 'skip'| (read sys$input line ; define/job line_log &line)
$   isq_dim_y == f$element(0, " ", f$edit(f$trnlnm("line_log") - "Dim Y :", "trim,compress"))
$   pipe ctheader 'p1' | search sys$pipe "Dim Z :" 'skip'| (read sys$input line ; define/job line_log &line)
$   isq_dim_z == f$element(0, " ", f$edit(f$trnlnm("line_log") - "Dim Z :", "trim,compress"))
$!
$   pipe ctheader 'p1' | search sys$pipe "Voxel Size :" 'skip'| (read sys$input line ; define/job line_log &line)
$   voxel_size_um == f$element(0, " ", f$edit(f$trnlnm("line_log") - "Voxel Size :", "trim,compress"))
$   icalc 'voxel_size_um' / 1000
$   voxel_size == icalc_out
$!
$ say "!!  "
$!
$   sh sym samp_name
$   sh sym samp_no
$   sh sym meas_no
$   sh sym isq_dim_*
$   sh sym voxel_size*
$!
$ say "!!  "
$ say "!! GET_CTHEADER.COM: completed"
$ say "=========================================================="
$ exit
