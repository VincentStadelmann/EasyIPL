$!*************************************************            
$! FILL_Z_OFFSET.COM
$! 2012.06.06 V. Stadelmann
$!	2016.12.16 p3 can have "." to give variable borders
$!	2017.10.26 p3 can have "." to give variable borders
$! 
$! USAGE:
$! Cuts out empty regions
$!  @UE:FILL_Z_OFFSET.COM	'seg_filename' 'cut_filename' 'ipl_border_z'
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! FILL_Z_OFFSET.COM:	
$ say "!! Cuts out empty regions, adds offset, "
$ say "!! fills offset with border slices duplicates    "
$ say "=========================================================="
$!
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then goto terminate
$ if (p3 .nes. "") then goto terminate
$ show symbol p1 
$ show symbol p2 
$ show symbol p3 
$!
$ IPL_BATCH

/read
  -name                      in
  -filename                  "p1

!! border in z put into offset then, will be mirrored later

/bounding_box_cut
  -input                     in
  -output                    out 
  -z_only                    false
  -border                    0 0 "p3  

/offset_add
  -input                     out
  -add_offset                0 0 "p3

!! mirror out slices that were stolen in gauss
/fill_offset_duplicate
  -input                     out  
  
/write_v020
  -name                      out
  -filename                  "p2
  -compress_type             bin
  -version_020               true

..
$ say "!! FILL_Z_OFFSET.COM:	Completed "
$ say "=========================================================="
$ exit
$ terminate:
$  @ez:helper FILL_Z_OFFSET.com
$ exit