#!c:/prog/perl560/bin
# Usage	 V1.0 5/4/03
#
# DirList.pl -switches 
#
# Creates file dir.csv in the current directory
# One line for each file in the current dir and subdirectories
# As a comma separated list (.csv format):
#   root dir, current dir, name, ext, modify date-time, size
#
#  Say current directory is C:/bug/ant
#  rootdir is C:/bug
#  current dir is ant, ant/sub1, ant/sub2, ant/sub1/ssub1, etc.
#
# Andrew Garland 

use File::Find ; #standard file package
use Getopt::Std; #Command line arg processing
use Cwd        ; #for cwd() current working directory

$isOK = getopts('ade:hi:o:s:');

if (!$isOK or $opt_h) {
  print <<EOD ;

DirFiles.pl  Command line utility for Windows systems
             Lists dir and file info in comma separated (.csv) format
             to a file.  by Andrew M. Garland  5/2003

-a             Append to output file
-d             Include directory names, shown as "dir/dirname.*"
-e ext[.ext]   Limit to these extensions eg   txt or  txt.doc
               Leading dot is optional   eg	 .txt or .txt.doc
               Include null extensions   eg . or ..txt.doc or .txt.doc.
               Directories are not affected (usually not included)  
-h             help  - Shows these command options
-i directory   Directory to start   default = current directory  
               "a" -> "curdir/a"   "/b" or "C:/b" is an absolute directory
-o outputFile  default = "dir.csv"
-s 0..n        Process n levels of subdirectory
               Default is all subdirs (100000), 0 -> no subdirs
-d -e/         How To include only directory names
EOD
  exit;
  } # if $opt_h
  
$opt_s = 100000 unless defined $opt_s;
$opt_d =      0 unless defined $opt_d; # 1 include dir names in output
$opt_e =    "*" unless defined $opt_e; # list of included extensions

$ofilename = $opt_o ? $opt_o : "dir.csv";
$wmode     = $opt_a ? ">>"   : ">"      ; # append or write the file
$dirStart  = Cwd::cwd() ; # current working directory
$dirtarget = $dirStart ; # target directory is cwd by default

if ($opt_i) { # user specified a directory
  $dirtarget = $opt_i ;
  $dirtarget =~ s#\\#/#g ; #use forward slashes in dir name
  unless ($dirtarget =~ m#^([a-zA-Z]:)?/# )  # begins with "x:/" or "/" -> absolute
    {$dirtarget = "$dirStart/$dirtarget"; } # prepend current directory
  -e $dirtarget || die "?Err Directory $dirtarget does not exist\n";
  chdir($dirtarget); #remove indirections like ".." and "." by changing dir
  $dirtarget = Cwd::cwd() ; # and recovering name from system
  }
#change to forward slashes and remove any trailing "/" 
$dirtarget =~ s#\\#/#g ; #use forward slashes in dir name
chomp($dirtarget) if substr($dirtarget,-1,1) == "/";
print "Processing directory $dirtarget\n";

# if $dirtarget is C:/bug/ant  then $dirroot is C:/bug 
$dirtarget =~ m#(.*)([:/])# ; # match to last slash or colon
$dirroot   = $1; # the directory "above" us
$dirlen    = length($dirroot)+1 ;

# set list of extensions to form ".txt.doc." or "..txt." or ".*."
$opt_e =~ s/^\.//           ; # remove any leading dot
$opt_e = "." . $opt_e . "." ; # add leading and following dots
$opt_e = "*" if $opt_e =~ /\.\*\./ ; # allow all files if contains ".*."

chdir $dirStart; #for opening the output file
open (OUT, "$wmode$ofilename");	#output file is either write or append
print "Output to $wmode$ofilename\n";

#walk the directory tree using std package function
#top to bottom (not depth first)
$subDirCount = -1 ;# to process only one directory if -s switch used
File::Find::find(\&wanted, $dirtarget) ;

chdir($dirStart); #finish in same directory we started
close(OUT);

# ---------------------
# Called by  File::Find::find() above
# Print lines of form  dir,name,ext,create,size

sub wanted {
  $subDirCount += (-d); # add 1 if a directory  is 0 in first directory 
  # prune all sub-directories if -s switch
  $File::Find::prune = ($opt_s < $subDirCount); # true is skip this file (directory)

    # dev ino mode nlink uid gid rdev size access-time modify-time cnode-time blksize blocks
	#  0   1    2    3    4   5    6    7         8           9          10      11     12
  ($size,$modT) = (stat($_))[7,9] ;#info on file
    # sec, min, hour, day, month, year, weekday, yearday, isDaylightSavings
	#  0    1     2    3     4      5      6        7               8
  ($sec, $min, $hour, $day, $month, $year) = (localtime($modT))[0,1,2,3,4,5];

  #  " 4/15/2003 _3:07:23"
  $modTime = sprintf "%2d/%02d/%4d %2d:%02d:%02d", $mon+1, $day, $year+1900, $hour, $min, $sec;
  
  # match up to last '.' in $_ filename
  if ( /(.*)\./ ) {$a = $1; $b = $';} # name and ext separated by "."
  else            {$a = $_; $b = "";} # name with no extension
  
  $n = length($File::Find::dir); #entire directory name
  $subdir = substr($File::Find::dir,$dirlen-$n,$n); #keep just the subdirectory part 

{ # block for printing
  last unless (! -d _ or $opt_d) ;# dont print directories unless told to

  # select for allowed extensions if not a directory and extensions are limited
  if (! -d _ and $opt_e ne "*")
   { last unless $opt_e =~  /\.$b\./i ;} # leave unless ext is in the list   

  $b = "*" if (-d _) ; #special extension labels directories
  print OUT "$dirroot,$subdir,$a,$b,$modTime,$size\n"; 
  }	# block for printing
} #wanted()

# end
