$!****************************************************************           
$! SPLIT_IN_OUT.COM
$! 2017.06.06 V Stadelmann
$! Splits a tube-like aim into the outer shape and inner shape
$! Inside of the tube is assumed to be disconnected from outside
$! 
$! USAGE:
$!  @'scripts_dir'split_in_out.com	'aim_filename' 'outer_aim' 'inner_aim' 'border'
$!****************************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! SPLIT_IN_OUT.COM:	"
$ say "=========================================================="
$!*
$!
$ if p4 .eqs. "" then p4 = "0"
$!
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$!
$ IPL_BATCH

/read
  -name                      in
  -filename                  "p1

!! Add space aroung object

/bounding_box_cut
  -input                     in
  -output                    obj
  -z_only                    false
  -border                    "p4 "p4 0

!! Invert image

/set_value
  -input                     obj
  -value_object              0
  -value_background          127
  
!! Component label: first object = outside

/cl_rank_extract
  -input                     obj
  -output                    cl
  -first_rank                1
  -last_rank                 1
  -connect_boundary          false
  -value_in_range            127
  -topology                  6
 
!! Invert image, crop border, write file

/set_value
  -input                     cl
  -value_object              0
  -value_background          127
  
/bounding_box_cut
  -input                     cl
  -output                    out
  -z_only                    false
  -border                    0 0 0

/write_v020
  -name                      out
  -filename                  "p2
  -compress_type             bin
  -version_020               true
  
!! Component label: second object = inside

/cl_rank_extract
  -input                     obj
  -output                    cl
  -first_rank                2
  -last_rank                 2
  -connect_boundary          false
  -value_in_range            127
  -topology                  6
 
!! Crop border, write file
  
/bounding_box_cut
  -input                     cl
  -output                    out
  -z_only                    false
  -border                    0 0 0

/write_v020
  -name                      out
  -filename                  "p3
  -compress_type             bin
  -version_020               true
	
..	
$ say "!! SPLIT_IN_OUT.COM: completed "   
$ say "=========================================================="
$ exit
