$ define ez ADISK1:[VINCENT.EVAL.EZ]
$ @ez:init
$ loc = "DK0:[MICROCT.DATA.00012138.00026819]"
$ file = "Y0005441_DEF"
$ @ez:get_tri.com 'loc''file'.AIM  aim_tri1  0  'loc''file'test_tri.log
$ @ez:get_tri.com 'loc''file'.AIM  aim_tri2  0  'loc''file'test_tri.log
$ sh sym aim_tri*
$ exit