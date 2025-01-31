$!*************************************************            
$! ALIGN_IN_Z_REF.COM
$! 2011.09.20 V. Stadelmann 
$! Mod 2013.03.08 VS - added Usage
$! Mod 2014.12.18 VS - added interpolation option
$! 
$! USAGE:
$! Calculates matrix to align MOI of input aim (P1) in Z
$! APPLIES MATRIX TO P2 and write it as P3
$! P1 : reference AIM
$! P2 : aim to be aligned
$! P3 : aligned aim
$! P4 : skip nb: how many /examine have been used before this one
$! P5 : interpolate image (use 0 for segmented images)
$!
$! USGAGE:
$!  @'scripts_dir'ALIGN_IN_Z_REF.COM	'ref_filename' 'aim_filename' 'aligned_filename' 'skip' 'interpol'
$!*************************************************            
$!*
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! ALIGN_IN_Z_REF.COM:	Align AIM in Z using REF for MOI calc "
$ say "=========================================================="
$!
$ show symbol p1 
$ show symbol p2 
$ show symbol p3 
$ show symbol p4
$!
$!
$!  This script looks in the log file for align matrix
$!  If /tri have been used before in the main script
$!  It needs to skip them.
$  if p4 .eqs. "" then p4 ="0"
$  if p4 .nes. "0" 
$     then skip := /skip='p4'
$  else 
$     skip = ""
$  endif
$!
$  if p5 .nes. "0" 
$     then interpol := 1
$  else 
$     interpol := 0
$  endif
$!
$ show symbol skip
$ show symbol interpol
$!
$ 	say ">>> CALCULATING MATRIX:"
$ IPL_BATCH

/read
  -name                     in
  -filename                 "P1

/moment3d
  -input					in
  -output					tri
  -gobj						none	

..
$ SET OUTPUT_RATE=00:00:02
$ WAIT 00:00:05
$
$ PIPE SEARCH'skip' 'log_filename' "!>   -origin_point " | (READ SYS$PIPE LINE ; DEFINE/JOB/NOLOG LINE_LOG &LINE)
$ LINE_SYM = F$TRNLNM("LINE_LOG")
$ align_input1 = LINE_SYM - "!>   -origin_point "
$ align_input1 = F$EDIT(align_input1,"TRIM,COMPRESS") 
$!
$ PIPE SEARCH'skip' 'log_filename' "!>   -z-axis_point " | (READ SYS$PIPE LINE ; DEFINE/JOB/NOLOG LINE_LOG &LINE)
$ LINE_SYM = F$TRNLNM("LINE_LOG")
$ align_input2 = LINE_SYM - "!>   -z-axis_point "
$ align_input2 = F$EDIT(align_input2,"TRIM,COMPRESS")   
$!
$ PIPE SEARCH'skip' 'log_filename' "!>   -xz-plane_point " | (READ SYS$PIPE LINE ; DEFINE/JOB/NOLOG LINE_LOG &LINE)
$ LINE_SYM = F$TRNLNM("LINE_LOG")
$ align_input3 = LINE_SYM - "!>   -xz-plane_point "
$ align_input3 = F$EDIT(align_input3,"TRIM,COMPRESS")   
$! 
$   SHOW SYMBOL align_input*
$ 	say ">>> APPPLY MATRIX:"
$   SHOW SYMBOL align_input*
$ IPL_BATCH

/read
  -name                     in
  -filename                 "P2
  
/align_z
  -input					in
  -output					out
  -origin_point				"align_input1
  -z-axis_point				"align_input2
  -xz-plane					"align_input3
  -img_interpol_option       "interpol

/delete
    -name		      		 in  
    
/header_geo_set
  -input                     out
  -off_new                   0 0 0
  -pos_new                   0 0 0
  -el_size_mm_new            -1.000 -1.000 -1.000

/write
  -name                      out
  -filename                  "P3
  -compress_type             bin
  -version_020               true
  
..  
$!
$ say "!! ALIGN_IN_Z_REF.COM:	Completed "
$ say "=========================================================="
$ exit  
