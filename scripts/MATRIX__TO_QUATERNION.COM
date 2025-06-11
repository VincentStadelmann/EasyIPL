$    tab == f$fao("!_")
$    tab == "	"
$
$   Say "First rotation"
$    open/write output_file 'tmat1_filename'
$    write output_file "SCANCO TRANSFORMATION DATA VERSION: 10"
$    write output_file "R4_MAT:"
$
$    r1_str = tab+M_11+tab+M_12+tab+M_13+tab+M_14
$    r2_str = tab+M_21+tab+M_22+tab+M_23+tab+M_24
$    r3_str = tab+M_31+tab+M_32+tab+M_33+tab+M_34
$    r4_str = tab+M_41+tab+M_42+tab+M_43+tab+M_44
$
$    sh sym r*_str
$ 
$    write/symbol output_file r1_str   
$    write/symbol output_file r2_str
$    write/symbol output_file r3_str   
$    write/symbol output_file r4_str   
$    close output_file
$    Say " "
$    type 'tmat1_filename'
$    Say " "
