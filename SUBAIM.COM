$!*************************************************            
$! SUBAIM.COM
$! 2011.10.20 V. Stadelmann
$!	Mod 2015.04.16 added P5 to correct a bug
$! 
$! USAGE:
$! Creates SUBAIM
$! P1 : input aim
$! P2 : sub aim
$! P3 : new position  "p1.p2.p3"
$! P4 : new dimension "d1.d2.d3"
$! 
$!  @'scripts_dir'subaim.com	'ipl_input' 'ipl_output' 'new_pos1.2.3' 'newdim1.2.3' 'global'
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! SUBAIM.COM:	"
$ say "=========================================================="
$!*
$
$       if p1 .eqs. "" then goto terminate
$       if p2 .eqs. "" then goto terminate
$
$   show symbol p1
$   show symbol p2
$
$       if p3 .eqs. "" then p3 := 0,0,0
$       if p4 .eqs. "" then p4 := -1,-1,-1
$       if p5 .eqs. "" then p5 := true
$
$   show symbol p3
$   show symbol p4
$   show symbol p5
$
$   if (f$locate(",", p3) .lt. f$length(p3)) 
$     then 
$      __pos1 = f$element(0,",",p3)
$      __pos2 = f$element(1,",",p3)
$      __pos4 = f$element(2,",",p3)
$     else
$       if (f$locate(".", p3) .lt. f$length(p3)) 
$         then 
$          __pos1 = f$element(0,".",p3)
$          __pos2 = f$element(1,".",p3)
$          __pos4 = f$element(2,".",p3)
$       else
$         goto terminate
$       endif
$   endif
$
$   if (f$locate(",", p4) .lt. f$length(p4)) 
$     then 
$      __dim1 = f$element(0,",",p4)
$      __dim2 = f$element(1,",",p4)
$      __dim3 = f$element(2,",",p4)
$     else
$       if (f$locate(".", p4) .lt. f$length(p4)) 
$         then 
$          __dim1 = f$element(0,".",p4)
$          __dim2 = f$element(1,".",p4)
$          __dim3 = f$element(2,".",p4)
$       else
$         goto terminate
$     endif
$   endif
$
$   show symbol __pos*
$   show symbol __dim*
$
$ IPL_BATCH

/read
  -name                      tmp
  -filename                  "P1

/sub_get
  -input                     tmp
  -output                    sub
  -pos                       "__pos1 "__pos2 "__pos3
  -dim                       "__dim1 "__dim2 "__dim3
  -global_pos_flag           "P5

/bounding_box_cut
  -input                     sub
  -output                    tmp
  -z_only                    false
  -border                    0 0 0
   
/write
  -name                      tmp
  -filename                  "P2
  -compress_type             bin
  -version_020               true  
  
..
$ say "!! SUBAIM.COM:	Completed"
$ say "=========================================================="
$ exit
$
$ terminate:
$ say "  P1 : AIM name"
$ say "  P2 : SUBAIM name"
$ say "  P3* : New position (px,py,pz / 0,0,0*)"
$ say "  P4* : New dimension (dx,dy,dz / -1,-1,-1*)"
$ say "  P5* : Global or local coordinate system (true* / false)"
$ exit
