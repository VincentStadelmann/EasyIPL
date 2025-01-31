$!*************************************************            
$! CREATE__CUBOID.COM
$! 2017.06.19 V Stadelmann
$! 2018.01.24 VS new format ","
$! 2018.03.05 VS cuboid based on  cylinder
$! 
$! Description:
$! Creates a cuboid AIM (see below)
$!   P1: Filename 
$!   P2: edges               (default=(1,1,1) )               
$!   P3: base                (default=(0,0,0) )
$!   P4: voxel size          (default = 1.00) 
$!   P5: Units (mm/vx)       (default = mm)
$!   P6: Value               (default = 127) 
$!
$! USAGE:
$!  @ez:create__cuboid.com	'cuboid_filename' 'edge_vec*' 'base_point*' 'el_size*' 'units*' 'value*' 
$!*************************************************            
$!*
$
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! CREATE__CUBOID.COM: "
$ say "=========================================================="
$!
$  if ("''coms'" .eqs. "") then coms = "ue:"
$  if (f$search("ez:vector__parse.com") .eqs. "") then goto terminate0
$  if (f$search("ez:vector__make.com") .eqs. "") then goto terminate0
$!
$! Test inputs
$
$  sh sym p1 
$  if (p1 .eqs. "") then goto terminate1
$
$  j = 1
$  pj_loop:
$    j = j + 1
$    show symbol p'j'
$    if (j .lt. 6) then goto pj_loop
$!
$  if (p2 .eqs. "") then p2 := 1,1,1
$  if (p3 .eqs. "") then p3 := 0,0,0
$  if (p4 .eqs. "") then p4 := 1.00
$  if (p5 .eqs. "") then p5 := MM
$  if (p5 .nes. "MM" .and. p5 .nes. "VX") then goto terminate1
$  if (p6 .eqs. "") then p6  = 127
$
$! Parse inputs
$   say "!! Conversion factor 1/elsize_mm :"
$   elsize_mm = p5
$   icalc 1/'elsize_mm'
$   elsize_vx = icalc_out
$   @ez:vector__parse.com  'p3' base_point
$   @ez:vector__parse.com  'p2' edges_vec
$
$! Convert units
$   if (p6 .eqs. "MM")
$    then
$     say "!! Convert mm to vx"
$     icalc 'edges_vec' * 'elsize_vx'
$     edges_vec = icalc_out
$   endif
$!
$ IPL_BATCH

/create_canvas
  -output                    in
  -dim                       "edges_vec__ipl
  -off                       0 0 0
  -pos                       "base_point__ipl
  -el_size_mm                "elsize_mm
  -type                      char

/set_value
  -input                     in
  -value_object              127
  -value_background          127

/write_v020
  -name                      in
  -filename                  "p1
  -compress_type             bin
  -version_020               true

..
$ say "!! CREATE__CUBOID.COM:	Completed "
$ say "=========================================================="
$ exit
$!
$ terminate0:
$   say "  "
$   say "!! Error: vector_floor.com requires vector__parse.com and vector__make.com in ''coms' "
$   exit
$ terminate1:
$   say "  "
$   say "P1: Filename "
$   say "P2*: Edges ( > 0) (default=1,1,1)    "                  
$   say "P3*: Base point   (default=0,0,0) "      
$   say "P4*: Voxel size   (default=1.00)"
$   say "P6*: Units        (MM*/VX)"
$   say "P7*: Value        (default = 127) "
$   exit
