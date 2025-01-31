$! test_subroutines_lib.com
$ @ue:subroutines_lib.com
$ test_list = "a,b,c"
$ CALL GET_LIST_LENGTH test_list__length 'test_list'
