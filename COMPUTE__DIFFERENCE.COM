$!*************************************************            
$! COMPUTE__DIFFERENCE.COM
$! 2012.09.20 V. Stadelmann 
$! 2018.01.17 VS __ format
$! 
$! USAGE:
$! 	Computes the differences between 2 segmented aims
$! 	P1: object of interest
$!	P2: reference object
$! 	P3: differences
$!	P4*: more_value,common_value,less_value
$! 	P5*: more_file,common_file,less_file
$!
$!  @'scripts_dir'compute__difference.com	'object1_aim' 'object2_aim' 'difference_aim' 'obj1,intersect,obj2_value' 'obj1_file,intersect_file,obj2_filename*'
$! $!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! COMPUTE__DIFFERENCE.COM: "
$ say "!! Computes differences between 2 seg aims "
$ say "=========================================================="
$!*
$
$! First 3 p's must no be empty
$  j = 0
$  pj_loop:
$    j = j + 1
$    if (p'j' .eqs. "") then goto terminate1
$    sh sym p'j'
$    if (j .lt. 3) then goto pj_loop
$
$! Default values
$  sh sym p4
$  p4_default = "110,100,90"
$  if (p4 .eqs. "") then p4 = p4_default
$  if (f$locate(",", p4) .eq. f$length(p4)) 
$   then 
$       ! no comma 
$       say "!! Warning: p4 wrongly defined: ''p4', using ""''p4_default'"" instead... "
$		p4 = p4_default
$  endif
$  if (f$locate(",", p4) .lt. f$length(p4))
$ 	then 
$   	object1_value   = f$element(0,",",p4)
$   	intersect_value = f$element(1,",",p4)
$   	object2_value   = f$element(2,",",p4)
$  endif
$
$  ipl_insert1 = "!! Writing objects "
$  ipl_insert2 = "!!  "
$
$  sh sym p5
$  if (f$locate(",", p5) .eq. f$length(p5)) 
$   then 
$       ! no comma 
$       say "! Warning: p5 wrongly defined: ''p5', not writing files ... "
$		p5 = ""
$  endif
$  if (f$locate(",", p5) .lt. f$length(p5))
$ 	then 
$   	object1_filename   = f$element(0,",",p5)
$   	intersect_filename = f$element(1,",",p5)
$   	object2_filename   = f$element(2,",",p5)
$       sh sym object*_filename
$       sh sym intersect_filename
$  endif
$  if (p5 .eqs. "") 
$    then 
$      ipl_insert1 = ".."
$      ipl_insert2 = "$ goto complete"
$  endif
$
$ 
$!
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
  -value_in_range            "object1_value
  
/absolute_threshold
  -input                     sum
  -output                    intersect
  -lower_in_abs              99.000000
  -upper_in_abs              101.000000
  -grayscale_or_scaledvalues true
  -value_in_range            "intersect_value

/absolute_threshold
  -input                     sum
  -output                    object2
  -lower_in_abs              -28.000000
  -upper_in_abs              -26.000000
  -grayscale_or_scaledvalues true
  -value_in_range            "object2_value
    	
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
    -filename                "object1_filename
    -compress_type           bin
    -version_020             true
    
/set_value
    -input                   intersect
    -value_object            127
    -value_background        0
    	
/write
    -name                    intersect
    -filename                "intersect_filename
    -compress_type           bin
    -version_020             true
	
/set_value
    -input                   object2
    -value_object            127
    -value_background        0
    	
/write
    -name                    object2
    -filename                "object2_filename
    -compress_type           bin
    -version_020             true

..
$ complete:
$ say "!! COMPUTE__DIFFERENCE.COM: Completed"
$ say "=========================================================="
$ exit
$ terminate1:
$ say "!!  	Computes the differences between 2 segmented aims"
$ say "!!  	P1: object of interest"
$ say "!! 	P2: reference object"
$ say "!!  	P3: differences"
$ say "!! 	P4*: object1_value,intersect_value,object2_value"
$ say "!!  	P5*: object1_file,intersect_file,object2_file"
$ exit
