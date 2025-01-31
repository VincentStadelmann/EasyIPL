$ loc = "DK0:[MICROCT.DATA.00000343.00001084]"    ! EasyIPL Dev
$ submit/notify/que=sys$fast ez:make_surface.com /param=('loc'CYLINDER.AIM, 'loc'SURF_1.AIM, "0,1,0", 2, 'loc'test_ms1.log) /log='loc'test_ms1.log
$ submit/notify/que=sys$fast ez:make_surface.com /param=('loc'CYLINDER.AIM, 'loc'SURF_2.AIM, "0,1,0", -2, 'loc'test_ms2.log) /log='loc'test_ms2.log
$ submit/notify/que=sys$fast ez:aim_to_gobj.com /param=('loc'SURF_1.AIM, 'loc'SURF_1.GOBJ, 0, 0, 5) /log='loc'test_atg1.log
$ submit/notify/que=sys$fast ez:aim_to_gobj.com /param=('loc'SURF_2.AIM, 'loc'SURF_2.GOBJ, 0, 0, 5) /log='loc'test_atg2.log
$ exit