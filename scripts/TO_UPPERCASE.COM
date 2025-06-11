$!****************************************************************************************            
$! TO_UPPERCASE.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2021.07.08
$!  Copyright (c) 2021 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! VERSION HISTORY:
$!  2021.07.08 V.Stadelmann
$! 
$! DESCRIPTION:
$!  User script to rename all files in directory with uppercase names
$! 
$! USAGE:
$!  In UCT_EVALUATION -> "User-script" -> EZ:TO_UPPERCASE.COM
$! 
$!****************************************************************************************            
$
$ WRITE OUTFILE "$   say=""write sys$output""  "
$ WRITE OUTFILE "$   say ""=========================================================="" "
$ WRITE OUTFILE "$   say ""!! TO_UPPERCASE.COM:"" "
$ WRITE OUTFILE "$   say ""=========================================================="" "
$ WRITE OUTFILE "$   loop:"
$ WRITE OUTFILE "$     file = f$search(""''EVAL_DIR'*.*"")"
$ WRITE OUTFILE "$       if file.eqs."""" then exit"
$ WRITE OUTFILE "$       rename ''''file ''''f$edit(file,""UPCASE"")" !/log
$ WRITE OUTFILE "$       goto loop"
$ WRITE OUTFILE "$   wait 00:00:04 ! Let log flush"
$ WRITE OUTFILE "$   say ""=========================================================="" "
$ WRITE OUTFILE "$   say ""!! TO_UPPERCASE.COM: Completed "" "
$ WRITE OUTFILE "$   say ""=========================================================="" "
$ WRITE OUTFILE "$ exit"