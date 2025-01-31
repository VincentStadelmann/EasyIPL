$!****************************************************************************************            
$! COMPLABNR.COM
$! 
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! VERSION HISTORY:
$!  2018.07.29 Minor bugs
$! 
$! DESCRIPTION:
$! select objects between n and m voxels
$!
$! USAGE:
$!  @'scripts_dir'complabnr.com	'ipl_input' 'ipl_output' 'ipl_from_vol' 'ipl_to_vol' 'ipl_val'
$!
$! PARAMETERS:
$!  P1 : input aim file
$!  P2 : output aim file
$!  P3 : from vol...
$!  P4 : to vol...
$!  P5 : value object
$!
$!****************************************************************************************            
$!
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! COMPLABNR.COM:	"
$ say "=========================================================="
$!*
$!
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then goto terminate
$ if (p3 .eqs. "") then p3 = 10
$ if (p4 .eqs. "") then p4 = 0
$ if (p5 .eqs. "") then p5 = 127
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$ show symbol p5
$
$ if (f$locate("%", p3) .lt. f$length(p3)) then goto cl_in_percent
$
$ IPL_BATCH

/read
  -name                      in
  -filename                  "P1

/cl_nr_extract
  -input                     in
  -output                    cl
  -min_number                "p3
  -max_number                "p4
  -value_in_range            "p5
  -topology                  6
  
/write
  -name                      cl
  -filename                  "P2
  -compress_type             bin
  -version_020               true
  
..
$ goto completed
$
$ cl_in_percent:
$ if (p4 .eq. 0) then p4 = 100  
$
$ IPL_BATCH

/read
  -name                      in
  -filename                  "p1

/cl_extract
  -input                     in
  -output                    cl
  -lo_vol_fract_in_perc      "p3
  -up_vol_fract_in_perc      "p4
  -value_in_range            "p5
  -topology                  6
  
/write_v020
  -name                      cl
  -filename                  "p2
  -compress_type             bin
  -version_020               true
  
..
$
$ completed:
$ say "!! COMPLABNR.COM:	completed	 "
$ say "=========================================================="
$ exit
$!
$ terminate:
$ say "!! P1 : name of input file"
$ say "!! P2 : name of output file"
$ say "!! P3 : vol min* (10)"
$ say "!! P4 : vol max* (0)"
$ say "!! P5 : value* (127)"
$ exit
