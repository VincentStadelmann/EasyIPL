$!*************************************************            
$! HISTO.COM
$! 2018.02.02 V Stadelmann
$! 
$! Description:
$! Applies a mask to aim then computes histogram
$! P1 : name of input aim file
$! P2 : name of histo file
$! P3* : name of gobj
$! P4* : count zeros
$!
$! USAGE:
$!   @ue:histo.com	'input_filename' 'histo_filename' 'gobj_filename*' 'count_zeros*' 'vec_min_max_nbins*' 'unit'
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! HISTO.COM:	 "
$ say "=========================================================="
$!*
$!
$  	if p1 .eqs. "" then goto terminate
$  	if p2 .eqs. "" then goto terminate
$
$  	if p3 .eqs. "" then p3 = "NONE"
$  	if p3 .eqs. "0" then p3 = "NONE"
$
$  	if p4 .eqs. "" then p4 = "TRUE"
$  	if p4 .eqs. "1" then p4 = "TRUE"
$  	if p4 .nes. "TRUE" then p4 = "FALSE"
$
$  	if p6 .eqs. "" then p6 = "0"
$
$! Check if p5 is a vector
$  	if p5 .eqs. "" then p5 = "-1.0,-1.0,-1"
$   if (f$locate(",", p5) .lt. f$length(p5))
$ 	 then 
$   	__min_val = f$element(0,",",p5)
$   	__max_val = f$element(1,",",p5)
$   	__n_bins  = f$element(2,",",p5)
$       sh sym __*
$ 	else	
$       ! no comma -> error
$		goto terminate
$   endif
$
$   show symbol p1 
$   show symbol p2 
$   show symbol p3 
$   show symbol p4
$   show symbol p5
$   show symbol p6
$
$   if p3 .eqs. "NONE" then goto nogobj
$
$!
$ IPL_BATCH

/read
  -name                      in
  -filename                  "P1

/gobj_maskaimpeel_ow
  -input_output              in
  -gobj_filename             "P3
  -peel_iter                 0
  
/bounding_box_cut
  -input                     in
  -output                    out
  -z_only                    false
  -border                    0 0 0

/histo
  -input                     in
  -fileout_or_screentab      "P2
  -from_val                  "__min_val
  -to_val                    "__max_val
  -nr_bins_in_tab            "__n_bins
  -dt_type                   auto
  -count_zeros               "p4
  -unit                      "p6

  
..
$ say "!! HISTO.COM:	Completed "
$ say "=========================================================="
$ exit
$
$ nogobj:
$ say "!! No GOBJ: "
$ IPL_BATCH

/read
  -name                      in
  -filename                  "P1

/histo
  -input                     in
  -fileout_or_screentab      "P2
  -from_val                  "__min_val
  -to_val                    "__max_val
  -nr_bins_in_tab            "__n_bins
  -dt_type                   auto
  -count_zeros               "p4
  -unit                      "p6
  
..
$ say "!! HISTO.COM:	Completed "
$ say "=========================================================="
$
$ exit
$
$ terminate:
$ say "!! P1 : name of input file"
$ say "!! P2 : name of histo file"
$ say "!! P3 : gobj file (filename or none*)"
$ say "!! P4 : count zeros? (TRUE*/FALSE or 1/0)"
$ say "!! P5 : bins vector: min_val,max_val,n_bins (-1.0,-1.0,-1*)"
$ exit
