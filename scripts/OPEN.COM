$!************************* EZ_IPL *****************************************           
$!
$! OPEN.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2012.06.06
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Clean debris off of an object by a sequence of erosion, 
$!  component labelling, dilation
$! 
$! USAGE:
$!  @ez:open 'in_file' 'out_file' 'erosion_dist' 'min_vol' 'delta_dilation'
$!
$! PARAMETERS:
$!  P1  : Input SEG file
$!  P2* : Output SEG file              (*_OPEN.AIM)
$!  P3* : Erosion/dilation dist        (*0)
$!  P4* : Min volume (in voxels or %)  (*0)
$!  P5* : Delta dilation               (*0)
$! 
$! EXAMPLE:
$!  Opens (clean) image.seg with erosion by 10 voxels and remove speckles below 
$!  2% of total volume, then dilation of 9 voxels
$!  @ez:open	image.seg image_open.seg 10 2% 1
$! 
$! VERSION HISTORY:
$!  2017.09.07 New
$!  2018.03.21 Added % option in CL
$!  2018.08.03 Added delta dilation option
$!  2018.10.20 EZ Format
$!
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say "  "
$ say "=========================================================="
$ say "!! OPEN.COM:  "
$ say "=========================================================="
$!*
$!
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_OPEN.AIM"
$ if (p3 .eqs. "") then p3 = 0
$ if (p4 .eqs. "") then p4 = 0
$ if (p5 .eqs. "") then p5 = 0
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$ show symbol p5
$
$ __dil_dst = 'p3' - ('p5')
$ show symbol __dil_dst
$
$! Detect if volume expressed in voxels or percent
$ if (f$locate("%", p4) .lt. f$length(p4)) 
$   then 
$      cl_function   = "/cl_extract"
$      min_nr_param  = "-lo_vol_fract_in_perc"
$      max_param_nr  = "-up_vol_fract_in_perc"
$      max_param_val = "100"
$   else
$      cl_function   = "/cl_nr_extract"
$      min_nr_param  = "-min_number"
$      max_param_nr  = "-max_number"
$      max_param_val = "0"
$ endif
$
$ IPL_BATCH

/read
  -name                      in
  -filename                  "p1

/erosion
  -input                     in
  -output                    out
  -erode_distance            "p3
  -use_previous_margin       false
  -metric                    101

"cl_function
  -input                     out
  -output                    cl
  "min_nr_param              "p4
  "max_param_nr              "max_param_val
  -value_in_range            127
  -topology                  6

/dilation
  -input                     cl
  -output                    out
  -dilate_distance           "__dil_dst
  -continuous_at_boundary    0 0 0
  -use_previous_margin       true
  -metric                    101

/write_v020
  -name                      out
  -filename                  "P2
  -compress_type             bin
  -version_020               true
  
..
$
$!#
$ say "!! OPEN.COM: Completed "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper open.com
$ exit