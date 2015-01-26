#!/usr/bin/perl -w

my $prowl = "/usr/bin/prowl.pl";
my $apikey = "7619c566e1c575644bc0057935c52f3732d487c4";
my $application = "OpenNMS";
my $priority = 1;
my $event = "Alert";
my $msg = "";
 
foreach (@ARGV) {
        $msg .= $_." ";
}
 
my $cmd = $prowl." -apikey ".$apikey.
" -application=\"".$application."\" -priority=".
$priority." -event=\"".$event."\" -notification=\"".$msg."\"";
 
my $return = qx( $cmd );
print $return;

