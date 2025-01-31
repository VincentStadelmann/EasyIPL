$!*************************************************            
$! SCALE__.COM
$! 2015.02.20 V Stadelmann
$! 2017.07.17 VS add gobj
$! 2017.11.10 Possible to give float scale 
$! 2018.01.16 Adapt to vector libraries
$! 
$! Usage:
$!  @ue:scale__.com	'aim_filename' 'out_filename' 'scale_down' 'scale_up' 'integrate'
$!*************************************************            
$!
$ say = "write sys$output"
$ say "=========================================================="
$ say "!! SCALE__.COM: 
$ say "!!   Scales aim/gobj with numeric or vector scale factors " 
$ say "=========================================================="
$!*
$
$ if (p1 .eqs. "") then goto terminate1
$ if (p2 .eqs. "") then goto terminate1
$ p1 = f$edit(p1, "upcase")
$ p2 = f$edit(p2, "upcase")
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$ show symbol p5
$
$! Check if p3 is numeric or vector
$ if (f$locate(",", p3) .lt. f$length(p3))
$ 	then 
$   	s1 = f$element(0,",",p3)
$   	s2 = f$element(1,",",p3)
$   	s3 = f$element(2,",",p3)
$		down_scale := 's1' 's2' 's3'
$ 	else	
$       ! no comma -> numeric scale
$		down_scale := 'p3' 
$ endif
$!
$ if (f$locate(",", p4) .lt. f$length(p4))
$ 	then 
$   	s1 = f$element(0,",",p4)
$   	s2 = f$element(1,",",p4)
$   	s3 = f$element(2,",",p4)
$		up_scale := 's1' 's2' 's3'
$ 	else	
$		up_scale := 'p4'
$ endif
$!
$ if (p5 .eq. 1) then p5 = "TRUE"
$ if p5 .nes. "TRUE" then p5 = "false"
$!
$ show symbol p5
$ show symbol down_scale
$ show symbol up_scale
$!
$!
$ if (f$locate(".AIM", p1) .lt. f$length(p1)) 
$   then 
$     say "!! Scaling AIM to AIM"
$!
$     ipl_batch

/read
  -name                      in
  -filename                  "p1

/scale_elsize
  -input                     in
  -output                    sca
  -down_scale                "down_scale
  -up_scale                  "up_scale
  -integrate                 "p5

/delete
    -name		      		 in  
  
/write
  -name                      sca
  -filename                  "p2
  -compress_type             bin
  -version_020               true
  
..
$!
$ endif
$!
$ if (f$locate(".GOBJ", p1) .lt. f$length(p1)) 
$   then 
$     say "!! Scaling GOBJ to GOBJ"
$     ipl_batch

/gobj_scale
  -in_gobj_filename          "p1
  -out_gobj_filename         "p2
  -down_scale                "down_scale
  -up_scale                  "up_scale
  -interpolate               "p5

..
$ endif
$!
$ say "!! SCALE__.COM: Completed	"
$ say "=========================================================="
$ exit
$!
$ terminate1:
$   say " P1 : name of input file (AIM/GOBJ)"
$   say " P2 : name of output file (AIM/GOBJ)"
$   say " P3 : down-scale (f or fx,fy,fz)"
$   say " P4 : up-scale (f or fx,fy,fz)"
$   say " P5 : integrate (true/false)"
