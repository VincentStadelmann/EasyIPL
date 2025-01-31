$ loc = "DK0:[MICROCT.DATA.00000243.00000875]"
$ submit/que=sys$fast ez:get_geometry.com /param=('loc'Z0000827_SHAPE.AIM, shape_geo, 'loc'test_geo.log) /log='loc'test_geo.log
$ exit