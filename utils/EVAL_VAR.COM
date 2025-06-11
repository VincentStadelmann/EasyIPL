$	IF P1 .EQS. "" 
$	THEN
$	  WRITE SYS$OUTPUT "Give Special uct_evaluation_XXXX.COM as P1"
$	  EXIT
$	ENDIF
$
$!  Put the line in the following style into login.com:
$!
$!  EVAL_SPECIAL :== @UE:EVAL_VAR.COM UE:UCT_EVALUATION_SPECIAL.COM
$!
$!
$
$ define/user uct_evaluation 'P1'
$ uct_evaluation
$ exit
