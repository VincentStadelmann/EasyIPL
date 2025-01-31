$ loc = "DK0:[MICROCT.DATA.00000343.00001084]"    ! EasyIPL Dev
$ submit/notify/que=sys$fast ez:extrude_gobj.com /param=('loc'SURF_1.GOBJ, 'loc'SURF_1Y.GOBJ, Y, "90,140", 'loc'test_eg.log) /log='loc'test_eg.log
$ submit/notify/que=sys$fast ez:extrude_gobj.com /param=('loc'SURF_1.GOBJ, 'loc'SURF_1X.GOBJ, X, "100,120", 'loc'test_eg.log) /log='loc'test_eg.log
$ exit
$ submit/notify/que=sys$fast ez:extrude_aim.com /param=('loc'SURF_1.AIM, 'loc'SURF_1Y.AIM, Y, "90,140", 'loc'test_ea.log) /log='loc'test_ea.log
$ submit/notify/que=sys$fast ez:aim_to_gobj.com /param=('loc'SURF_1Y.AIM, 'loc'SURF_1Y.GOBJ, 0, 0, 5) /log='loc'test_eag.log
$ submit/notify/que=sys$fast ez:extrude_aim.com /param=('loc'SURF_1.AIM, 'loc'SURF_1X.AIM, X, "10,200", 'loc'test_ea.log) /log='loc'test_ea.log
$ submit/notify/que=sys$fast ez:aim_to_gobj.com /param=('loc'SURF_1X.AIM, 'loc'SURF_1X.GOBJ, 0, 0, 5) /log='loc'test_eag.log
$ exit