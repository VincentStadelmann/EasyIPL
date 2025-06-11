$! subroutines_lib.com
$!===========================
$ GET_LIST_LENGTH: SUBROUTINE
$! Usage:
$! 	CALL GET_LIST_LENGTH LIST_LENGTH_SYMBOL "e1,e2,e3,..."
$! or
$! 	CALL GET_LIST_LENGTH LIST_LENGTH_SYMBOL 'LIST_SYMBOL'
$!
$ J = 0
$! SH SYM P1
$! SH SYM P2
$ LEN = F$LENGTH(P2)
$! SH SYM LEN
$ IF (LEN .EQ. 0) THEN 'P1' == 0
$ START:
$   EL_J = f$element(J,",","''P2'")
$!   SH SYM EL_J
$   IF ("''EL_J'" .EQS. ",") 
$     THEN
$     'P1' == J
$     EXIT
$   ENDIF
$   J = J + 1
$   IF (J .LE. LEN) THEN GOTO START
$ ENDSUBROUTINE
$!===========================
