$! DELETE_FILE.COM
$! 2017.07.07 V Stadelmann
$! To delete temporary files 
$!
$ say == "write sys$output "
$ on error then exit
$ say "========================================="
$ say " DELETE_FILE.COM      "
$ say "========================================="
$!
$   if (p1 .eqs. "")
$    then 
$	   say " P1: file to delete (full address)"
$      exit
$   endif
$!
$   if f$search(p1) .eqs. ""   ! make sure the file exists
$    then
$ 	   say "!! Error: File does not exists."
$	   exit
$   endif
$!
$   if (f$locate(";", p1) .lt. f$length(p1))
$ 	  then 
$       fullfilename := 'p1'
$     else	
$       fullfilename := 'p1';*
$   endif
$
$   delete/log 'fullfilename'
$   say " "
$   say " File ''fullfilename' deleted. "
$   exit
