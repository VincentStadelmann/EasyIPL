$! UCT_NEW_RECONSTRUCTION.COM      
$! 	             
$! Revision history
$!	V1.0 02-MAY-2016 Implementation  V. Stadelmann
$!
$!----------------------------------------------------------------------------
$! 
$ sh sym p*
$ RSQ_filename = p1
$ EVAL_MISC1_0 = p2 ! angle
$ EVAL_MISC1_1 = p3 ! direction
$ EVAL_MISC1_2 = p4 ! slices
$ EVAL_MISC1_3 = p5 ! batch mode
$!
$! 
$! Correct slice numbers :
$! (slice 1 in UCT_EVALUATION is slice 0 in UCT_RECONSTRUCTION)
$!
$! All slices - no correction
$ IF EVAL_MISC1_2 .EQS. "A"
$ THEN 
$   SLICES == "A"
$ ENDIF
$ IF F$LOCATE(":",EVAL_MISC1_2) .EQ. F$LENGTH(EVAL_MISC1_2)
$ THEN 
$   WRITE SYS$OUTPUT " no : in slices" 
$ 	SHOW SYM EVAL_MISC1_2
$   SLICES = EVAL_MISC1_2 - 1 
$ ELSE
$   WRITE SYS$OUTPUT ": in slices" 
$   SLICES = EVAL_MISC1_2
$ ENDIF
$ SHOW SYM SLICES
$!
$ exit
