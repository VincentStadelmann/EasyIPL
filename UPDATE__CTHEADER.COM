$!*************************************************            
$! UPDATE__CTHEADER.COM
$! 2018.01.18 VS
$! 
$! USAGE:
$!  @ue:update__ctheader.com	'isq_filename' 'sampleno' 'measno' 'samplename' 'show_results?*(1/0)'
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! UPDATE__CTHEADER.COM: "
$ say "!!  Update SampleNo, MeasNo, SampleName in ISQ "
$ say "=========================================================="
$!*
$!
$
$ if p1 .eqs. "" then goto terminate
$ if p2 .eqs. "" then goto terminate
$
$   show symbol p1
$   show symbol p2
$   show symbol p3
$   show symbol p4
$   show symbol p5
$!
$ if f$search("''p1'") .eqs. ""
$  then
$    say "!! Error:  aim file does not exist."
$    goto terminate
$ endif
$!
$ p1 = p1 - f$parse(p1,,,"version")
$ checkaim = f$extract(f$length(p1)-3,3,p1)       
$ if (checkaim .nes. "ISQ" )
$  then
$    say "!! Error:  input file not an ISQ"
$    goto terminate
$ endif
$
$ if (p2 .eqs. "0") then p2 = " "
$ if (p3 .eqs. "0") then p3 = " "
$ if (p3 .eqs. "") then p3 = " "
$ if (p4 .eqs. "0") then p4 = " "
$ if (p4 .eqs. "") then p4 = " "
$
$! Update CT header
$
$ comfilename = p1 - ".ISQ" + "_UPDH.COM"
$ open/write outfile 'comfilename'
$ write outfile "$ R IDISK1:[VINCENT.UTIL]UPDH_SAMPLE_MEAS_NAME.EXE"
$ write outfile "''p1'"
$ write outfile "''p2'"
$ write outfile "''p3'"
$ write outfile "''p4'"
$ write outfile "$"
$ close outfile
$ @'comfilename'
$ if (p5 .eqs. "1") then ctheader 'p1'
$!
$ say "!!  "
$ say "!! UPDATE__CTHEADER.COM: completed"
$ say "=========================================================="
$ exit
$
$ terminate:
$   say "!! P1: ISQ input"
$   say "!! P2: Sample No   (0 = no change)"
$   say "!! P3: MeasNo      (0 = no change)"
$   say "!! P4: Sample Name (0 = no change)"
$   exit
