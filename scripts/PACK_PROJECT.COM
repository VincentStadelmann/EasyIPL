$! PACK_PROJECT.COM
$! 2018.08.14 V Stadelmann
$!
$ say == "write sys$output "
$ on error then continue
$ set output_rate=00:00:01
$
$ say " "
$ say "============================================================================="
$ say " PACK_PROJECT.COM "
$
$   if (p1 .eqs "") then goto terminate
$
$ 	say " "
$   say "!! Packing files from current directory into a ZIP file..."
$
$   project_name 	= p1
$   eval_name       :=  eval_'project_name'
$   sav_file		:= 'eval_name'.sav
$   zip_file		:= 'eval_name'.zip
$   install_file	:= 'eval_name'_readme_install.txt
$   doc_file		:= 'eval_name'_documentation.*
$
$   sh sym project_name
$   sh sym *_file
$   
$ 	say " "
$   say "!! Making SAV file ''sav_file' ..."
$   backup/log *.*;* 'sav_file'/sav /exclude=(*.SAV,*.ZIP,*.DIR)
$
$ 	say " "
$   say "!! Making ZIP file ''zip_file' ..."
$   if (f$search(sav_file) .eqs. "") 
$		then say "!! Error:  SAV file ''sav_file'  does not exist."
$    	goto terminate
$	else
$   	zip "-V"   'zip_file' 'sav_file'
$ 	endif
$
$   if (f$search(install_file) .nes. "") 	
$      then 
$          zip "-V"   'zip_file' 'install_file'
$      else
$          say "!! No install file (looking for ''install_file' )"
$   endif
$
$   if (f$search(doc_file) .nes. "") 		
$      then 
$          zip "-V"   'zip_file' 'doc_file'
$      else
$          say "!! No documentation file (looking for ''doc_file' )"
$   endif
$
$
$ say "============================================================================="
$ say " "
$ say " "
$ exit
$
$ terminate:
$  say " "
$  say "  P1: Project name"
$  say " "
