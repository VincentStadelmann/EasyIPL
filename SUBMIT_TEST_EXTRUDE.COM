$ define ez ADISK1:[VINCENT.EVAL.EZ]
$ loc = "DK0:[MICROCT.DATA.00012138.00026892]R0005449"
$ submit/que=sys$fast/notify/priority=200 ez:test_extrude.com /log='loc'_test_ex.log /noprint
$ exit