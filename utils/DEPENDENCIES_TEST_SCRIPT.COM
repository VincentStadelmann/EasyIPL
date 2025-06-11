$! This is to test the dependencies.com script
$   @ue:add_2_aims.com				'wallseg_filename' 'close_filename' 'wallc_filename' ! this is a rough closed wall mask
$   ifdebug @ue:togobj.com			'wallc_filename' 'wallc_gobj' 
