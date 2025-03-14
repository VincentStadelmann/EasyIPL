$!****************************************************************************************            
$! HEADER.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.11.08
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! VERSION HISTORY:
$!  2025.03.14 Created
$! 
$! DESCRIPTION:
$!  Display EasyIPL header
$! 
$! USAGE:
$!  @ez:header
$!
$! PARAMETERS:
$! 
$!
$!****************************************************************************************            
$!
$!*
$
$ type sys$input

    _/_/_/_/  _/_/_/_/      _/_/_/  _/_/_/    _/         
   _/             _/         _/    _/    _/  _/         
  _/_/_/       _/           _/    _/_/_/    _/            
 _/         _/           _/_/_/  _/        _/_/_/_/         
_/_/_/_/   _/_/_/_/   

                  EasyIPL  
        (c) Vincent Stadelmann 2025
        
$ exit
$