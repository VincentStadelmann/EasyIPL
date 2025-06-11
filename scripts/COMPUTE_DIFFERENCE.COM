$!************************* EZ_IPL *****************************************           
$!
$! COMPUTE_DIFFERENCE.COM
$!
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2015.04.05
$!  Copyright (c) 2011-2018 Vincent Stadelmann
$!  Do not duplicate or distribute without written permission by author. 
$!
$! DESCRIPTION:
$!  Computes the differences between two binary AIMs
$! 
$! USAGE:
$!  @ez:compute_difference 'aim1' 'aim2' 'diff' 'vec_val*' 'vec_files*'
$!
$! PARAMETERS:
$! 	P1: AIM1: Object of interest
$!	P2: AIM2: Reference object
$! 	P3: Differences AIM
$!	P4*: Values vector: only1,common,only2 (*110,100,90)
$! 	P5*: Files vector: only1,common,only2  (*no write)
$!
$! EXAMPLE:
$!   
$!
$! VERSION HISTORY:
$!  2012.09.20 V. Stadelmann 
$!  2018.01.17 __ format
$!  2019.02.29 EZ format
$! 
$!***************************************************************************            
$!
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! COMPUTE_DIFFERENCE.COM: "
$ say "=========================================================="
$!*
$! Test inputs
$   if (p1 .eqs. "") then goto terminate
$   if (p2 .eqs. "") then goto terminate
$   if (p3 .eqs. "") then goto terminate
$   show symbol p1
$   show symbol p2
$   show symbol p3
$
$! Default values
$  sh sym p4
$  p4_default = "110,100,90"
$  if (p4 .eqs. "") then p4 = p4_default
$  @ez:vector__parse.com  'p4' __diff_values 
$  if (__diff_values__h .nes. "V") then goto terminate1
$
$! No write files unless p5 is well defined
$  sh sym p5
$  ipl_insert1 = ".."
$  ipl_insert2 = "$ goto complete"
$  if (p5 .nes. "") then @ez:vector__parse.com  'p5' __diff_files 
$  if (__diff_files .nes. "") 
$    then 
$      ipl_insert1 = "!! "
$      ipl_insert2 = "!! Writing objects  "
$  endif
$  sh sym ipl_insert*
$ 
$! Script body
$ ipl_batch

/read
  -name                      object1
  -filename                  "P1

/read
  -name                      object2
  -filename                  "P2

/set_value
  -input                     object1
  -value_object              127
  -value_background          0
  
/set_value
  -input                     object2
  -value_object              -27
  -value_background          0
   
/add_aims
  -input1                    object1
  -input2                    object2
  -output                    sum  
  	
/absolute_threshold
  -input                     sum
  -output                    object1
  -lower_in_abs              126.000000
  -upper_in_abs              128.000000
  -grayscale_or_scaledvalues true
  -value_in_range            "__diff_values__1
  
/absolute_threshold
  -input                     sum
  -output                    intersect
  -lower_in_abs              99.000000
  -upper_in_abs              101.000000
  -grayscale_or_scaledvalues true
  -value_in_range            "__diff_values__2

/absolute_threshold
  -input                     sum
  -output                    object2
  -lower_in_abs              -28.000000
  -upper_in_abs              -26.000000
  -grayscale_or_scaledvalues true
  -value_in_range            "__diff_values__3
    	
/add_aims
  -input1                    intersect
  -input2                    object1
  -output                    tmp  
  	  	
/add_aims
  -input1                    tmp
  -input2                    object2
  -output                    difference  
  	
/write
    -name                    difference
    -filename                "P3
    -compress_type           bin
    -version_020             true
 
"ipl_insert1 
"ipl_insert2 
	
/set_value
    -input                   object1
    -value_object            127
    -value_background        0
    	
/write
    -name                    object1
    -filename                "__diff_files__1
    -compress_type           bin
    -version_020             true
    
/set_value
    -input                   intersect
    -value_object            127
    -value_background        0
    	
/write
    -name                    intersect
    -filename                "__diff_files__2
    -compress_type           bin
    -version_020             true
	
/set_value
    -input                   object2
    -value_object            127
    -value_background        0
    	
/write
    -name                    object2
    -filename                "__diff_files__3
    -compress_type           bin
    -version_020             true

..
$
$ complete:
$
$!#
$ say "!! COMPUTE_DIFFERENCE.COM: Completed"
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper COMPUTE_DIFFERENCE
$ exit