$ loc = "DK0:[MICROCT.DATA.00000243.00000875]"
$ submit/que=sys$fast ez:get_vox.com /param=('loc'Z0000827_SHAPE.AIM, 'loc'Z0000827_SHAPE_SEG.AIM, 'loc'Z0000827_SHAPE.GOBJ,  shape_vox, 'loc'test_vox.log) /log='loc'test_vox.log
$ exit