$!**************************************************************************************************            
$! GET_REG_CORR.COM
$! 2017.07.18
$! 
$! USAGE:
$!  @ue:get_reg_corr.COM	'reg_filename' 'ref_filename' 'reg_logfilename' 'reg_results_filname' 'reg_init' 'global_var'
$!**************************************************************************************************       
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! GET_REG_CORR.COM: submit extract_reg_corr2	"
$ say "=========================================================="
$!
$   if p5 .eqs. "" then p5 = 1
$   if p4 .eqs. "" then goto terminate$   show symbol p1
$   show symbol p1
$   show symbol p2
$   show symbol p3
$   show symbol p4
$   show symbol p5
$   show symbol p6
$!  
$   extract_log_filaname = p3 - ".LOG" + "_EXTRACT.LOG"
$   sh sym extract_log_filaname
$   
$ 	submit/noprint/que=sys$fast/notify/priority=255 ue:get__regcorr.com /params=('p1', 'p2', 'p3', 'p4', 'p5', 'p6') /log='extract_log_filaname' /after="+00:00:02"
$!
$ say "!! GET_REG_CORR.COM: Completed	"
$ say "=========================================================="
$ exit
