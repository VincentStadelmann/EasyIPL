$ loc = "DK0:[MICROCT.DATA.00000243.00000875]"
$ submit/que=sys$fast/notify ez:get_tri.com /param=('loc'Z0000827_SHAPE.AIM, aim_tri, 0, 'loc'test_tri.log) /log='loc'test_tri.log
$ exit