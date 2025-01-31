$! FOO.COM
$! Written by: Vincent Stadelmann 2011.08.03
$!*
$  if (p1 .eqs. "") then goto terminate
$
$  show symbol p1 
$
$  if (p5 .eqs. "0") then goto apply_gobj_nobox 
$
$!
$ IPL_BATCH

/read
  -name                      tmp
  -filename                  "P1

..
$ goto apply_gobj_complete
$
$ apply_gobj_nobox:
$! do nothing
$
$ apply_gobj_complete:
$!#
$ say "!! FOO.COM:	Completed "
$ exit
$
$ terminate:
$ say "!! P1 : name of input file"