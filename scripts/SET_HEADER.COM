$!************************* EZ_IPL *****************************************           
$!
$! SET_HEADER.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2010.06.03
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! DESCRIPTION:
$!  Change the position, offset and element size headers in file
$! 
$! USAGE:
$!  @ez:set_header.com  'in_file' 'out_file' 'new_pos' 'new_offset' 'new_elsize'
$!
$! PARAMETERS:
$!  P1  : Input AIM file
$!  P2* : Output AIM file                               (*_SH.AIM)
$!  P3* : New position vector p1,p2,p3                  (*0,0,0)
$!  P4* : New offset vector o1,o2,o3                    (*0,0,0)
$!  P5* : New element size vector e1,e2,e3              (*-1,-1,-1 = no change)
$! 
$! EXAMPLE:
$!  Move an image to global coordinate system origin  
$!  @ez:set_header image.aim image.aim 
$! 
$! VERSION HISTORY:
$!  2013.03.08 Bug fix
$!  2013.12.10 Outputfile, pos1 -> pos2, pos3
$!  2018.03.05 vec format
$!  2018.10.20 EZ Format
$!
$!***************************************************************************            
$!*
$
$ say = "write sys$output"
$ say " "
$ say "=========================================================="
$ say "!! SET_HEADER.COM:	 "
$ say "=========================================================="
$!*
$!
$ if (p1 .eqs. "") then goto terminate
$ if (p2 .eqs. "") then p2 = p1 - ".AIM" + "_SH.AIM"
$ if (p3 .eqs. "") then p3 = "0,0,0"
$ if (p4 .eqs. "") then p4 = "0,0,0"
$ if (p5 .eqs. "") then p5 = "-1,-1,-1"
$
$ show symbol p1
$ show symbol p2
$ show symbol p3
$ show symbol p4
$ show symbol p5
$
$ if (f$locate(",", p3) .eq. f$length(p3)) then goto terminate
$ if (f$locate(",", p4) .eq. f$length(p4)) then goto terminate
$ if (f$locate(",", p5) .eq. f$length(p5)) then goto terminate
$ @ez:vector__parse 'p3' __sh_new_pos
$ @ez:vector__parse 'p4' __sh_new_offset
$ @ez:vector__parse 'p5' __sh_new_elsize
$
$ ipl_batch

/read
  -name                      tmp
  -filename                  "p1

/header_geo_set
  -input                     tmp
  -off_new                   "__sh_new_offset__ipl
  -pos_new                   "__sh_new_pos__ipl
  -el_size_mm_new            "__sh_new_elsize__ipl

/write
  -name                      tmp
  -filename                  "p2
  -compress_type             bin
  -version_020               true

..
$ say "!! SET_HEADER.COM: Completed	 "
$ say "=========================================================="
$ exit
$
$ terminate:
$  @ez:helper SET_HEADER.com
$ exit
