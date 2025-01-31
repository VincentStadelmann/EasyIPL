$ loc = "DK0:[MICROCT.DATA.00012138.00026819]"
$ file = "Y0005441_DEF"
$ submit/que=sys$fast/notify ez:test_get_tri_bruettisellen.com /log='loc''file'test_tri.log /noprint
$ exit