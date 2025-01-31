$!************************* EZ_IPL *****************************************           
$!
$! SCALE.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2015.02.20
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Scale an AIM or GOBJ file down (ie voxel size larger -> smaller image) 
$!  or up (ie voxel size becomes smaller -> larger image) or combination 
$!  of both. Integrate will average voxel values. To scale a binary file 
$!  into binary file set p5 as "false"
$! 
$! USAGE:
$!  @ez:scale.com  'in_file' 'out_file'  'scale_down' 'scale_up' 'integrate?'
$!
$! PARAMETERS:
$!  P1  : Input AIM or GOBJ file
$!  P2* : Output scaled AIM or GOBJ file                (*_SCALE.***)
$!  P3* : Scale down factor or vector d or d1,d2,d3     (*1)
$!  P4* : Scale up factor or vector u or u1,u2,u3       (*1)
$!  P5* : Integrate values ?                            (*true/false)
$! 
$! EXAMPLE:
$!  Scale an image down by a factor 3 in x,y but no scale in z  
$!  @ez:scale image.aim scale.aim 3,3,1 
$! 
$! VERSION HISTORY:
$!  2017.07.17 Add gobj support
$!  2017.11.10 Possible to give float scale 
$!  2018.10.20 EZ Format
$!
$!***************************************************************************            
$!*
$
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! SCALE.COM: 	" 
$ say "=========================================================="
$!*
$!
$ if (p1 .eqs. "") then goto terminate
$ if (p3 .eqs. "") then p3 = 1
$ if (p4 .eqs. "") then p4 = 1
$ if (p5 .nes. "FALSE") then p5 = "TRUE"
$!
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$ show symbol p5
$
$ if (f$locate(",", p3) .eq. f$length(p3)) then p3 := 'p3','p3','p3'
$ if (f$locate(",", p4) .eq. f$length(p4)) then p4 := 'p4','p4','p4'
$ @ez:vector__parse 'p3' __sc_downscale
$ @ez:vector__parse 'p4' __sc_upscale
$
$ if (f$locate(".AIM", p1) .lt. f$length(p1)) 
$   then 
$     say "!! Scaling AIM to AIM"
$     if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_SCALE.AIM"
$     ipl_batch

       /read
         -name                      in
         -filename                  "p1

       /scale_elsize
         -input                     in
         -output                    sca
         -down_scale                "__sc_downscale__ipl
         -up_scale                  "__sc_upscale__ipl
         -integrate                 "p5
  
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
$     if (p2 .eqs. "") then p2 = p1 - ".GOBJ" + "_SCALE.GOBJ"
$     ipl_batch

       /gobj_scale
         -in_gobj_filename          "p1
         -out_gobj_filename         "p2
         -down_scale                "__sc_downscale__ipl
         -up_scale                  "__sc_upscale__ipl
         -interpolate               "p5
       
       ..
$ endif
$!
$ say "!! SCALE.COM: Completed	"
$ say "=========================================================="
$ exit
$!
$ terminate:
$  @ez:helper scale.com
$ exit
