$ define ez ADISK1:[VINCENT.EVAL.EZ]
$ @ez:init
$ loc = "DK0:[MICROCT.DATA.00012138.00026892]R0005449"    ! EPIC
$ @ez:extrude_xray.com 'loc'_EXRAY.AIM  'loc'_test_ex.aim  -376,340  'loc'_test_ex.log
$ exit