$!****************************************************************************************            
$! CREATE__TIMESTAMP.COM
$! 2018.07.10 V Stadelmann
$! 
$! Description:
$!  Creates a unique timestamp for filenames
$! 	p1 : timestamp symbol
$!
$! Usage:
$!   @'scripts_dir'create__timestamp.com	'timestamp_symbol'
$!****************************************************************************************            
$!
$ say = "write sys$output "
$ on error then exit
$ set output_rate=00:00:01
$
$ !say " "
$ !say "============================================================================="
$ !say " CREATE__TIMESTAMP.COM "
$
$  if (p1 .eqs. "") then p1 := "new_timestamp"
$
$ 	time_stamp = f$edit(f$time(),"trim,compress")
$ 	ts_date = f$element(0," ",time_stamp)
$ 	ts_time = f$element(1," ",time_stamp)
$ 	ts_hr  = f$element(0,":",ts_time)
$ 	ts_min  = f$element(1,":",ts_time)
$ 	ts_sec  = f$element(2,":",ts_time)
$ 	ts_msec = f$element(1,".",ts_sec)
$ 	ts_sec  = f$element(0,".",ts_sec)
$   time_stamp := 'ts_date'_'ts_hr'-'ts_min'-'ts_sec'-'ts_msec'
$
$   !sh sym time_stamp
$   'p1' == time_stamp   
$
$ !say "============================================================================="
$ !say " "
$ exit
