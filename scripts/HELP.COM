$!****************************************************************************************            
$! HELP.COM
$! 
$! COPYRIGHTS:
$!  Written by: Vincent Stadelmann 2018.11.08
$!  Copyright (c) 2018 Vincent Stadelmann/EasyIPL
$!  Do not duplicate or distribute without written permission by author.
$! 
$! VERSION HISTORY:
$!  2018.11.08 Created
$!  2021.03.05 Replaced 'help list' by 'list'
$! 
$! DESCRIPTION:
$!  EasyIPL help menu
$! 
$! USAGE:
$!  @ez:help
$!  @ez:help 'query'
$!
$! PARAMETERS:
$!  P1* : query 
$!
$!****************************************************************************************            
$!
$ say = "write sys$output"
$!*
$!-------------------------------------------------------------
$! Test inputs
$!-------------------------------------------------------------
$
$! Option 0: no query
$ if (p1 .eqs. "") then goto help_intro
$ if (f$search("ez:''p1'") .nes. "" .or. f$search("ez:''p1'.com") .nes. "") then goto help_script
$ if (p1 .nes. "") then goto help_list_keyword
$
$!
$ exit
$
$!-------------------------------------------------------------
$! General help message EasyIPL
$!-------------------------------------------------------------
$ help_intro:
$ say " "
$ @ez:header
$ say " "
$ type sys$input
 
==============================================================================
 
  EasyIPL is a collection of macros designed for fast and efficient
  IPL scripts development on SCANCO environments. 
  
  V1.02 2021-01-20 
  Tested with IPL V5.42 & OpenVMS V8.3

  COPYRIGHTS:
   Written by: Vincent Stadelmann 2012.06.06
   Copyright (c) 2025 Vincent Stadelmann/EasyIPL
   Do not duplicate or distribute without written permission by author.

  USAGE:

   To list all available scripts:
    @ez:list
    
   To search for a script based on a keyword
    @ez:help keyword
    
   To get help for a specific script:
    @ez:script_name 
  
==============================================================================


$ goto terminate
$
$!-------------------------------------------------------------
$! Help for specific script
$!-------------------------------------------------------------
$
$ help_script:
$ say "=========================================================="
$ @ez:helper.com 'p1' 
$ goto terminate
$
$!-------------------------------------------------------------
$! Help list: list all available scripts in EZ
$!-------------------------------------------------------------
$
$ help_list:
$ @ez:list.com 
$ goto terminate
$
$!-------------------------------------------------------------
$! Help list with search string, list all matching scripts
$!-------------------------------------------------------------
$
$ help_list_keyword:
$ @ez:list.com 'p1'
$ goto terminate
$
$ terminate:
$ exit