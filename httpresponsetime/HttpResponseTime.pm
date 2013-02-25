package Collectd::Plugins::HttpResponseTime;
 
use Collectd qw( :all );
 
#use strict; # STRICT
 
use Exporter ();
use Config::General ('ParseConfig');
 
use Net::HTTP;
use Getopt::Std;
use Time::HiRes qw(gettimeofday);
 
plugin_register (TYPE_DATASET, 'response_time', undef);
plugin_register (TYPE_CONFIG, 'HttpResponseTime', 'httpreponsetime_config');
plugin_register (TYPE_READ, "httpreponsetime", "httpreponsetime_read");
 
#====================================================================
# Option
#====================================================================
 
sub append_to_file { my $f = shift; open(my $F, ">>$f") or die "output in file $f failed: $!\n"; print $F $_ foreach @_; 1 }
 
#my ($debug, %http_config); # STRICT
 
#====================================================================
# Connection to HTTP monitor
#====================================================================
sub httpreponsetime_config {
    my ($config) = @_;
    use Data::Dumper;
    my %tmp_config = map { $_->{key} => $_->{values}[0] } @{$config->{children}};
    $debug = $tmp_config{debug};
    $http_config{$tmp_config{PInst}} = \%tmp_config;
    append_to_file("/tmp/debug.log", "config got called with " . Dumper($config)) if $debug;
    #%http_config = map { $_->{key} => join('.', grep { $_ } @{$_->{values}}) } @{$config->{children}};
    append_to_file("/tmp/debug.log", "config is " . Dumper(\%http_config) ) if $debug;
}
 
sub httpreponsetime_read {
    append_to_file("/tmp/debug.log", "READ got called\n"); # if $debug;
    my ($startTime, $tmp, $s);
 
    foreach my $key (sort keys %http_config) {
        my $my_config = $http_config{$key};
        my $vl= {
            name => 'httpresponsetime',
            plugin => 'httpreponsetime',
            type => 'response_time',
            plugin_instance => $my_config->{PInst},
            #type_instance   => ''
        };
 
        append_to_file("/tmp/debug.log", "looking at $key " . Dumper($my_config) ) if $debug;
        $startTime = gettimeofday();
        unless ($my_config->{ProxyPort}) {
            $s = Net::HTTP->new(Host => $my_config->{Host}) || die $@;
            $s->write_request(GET => $my_config->{Host}, 'User-Agent' => "Mozilla/5.0");
        } else {
            $s = Net::HTTP->new(Host => $my_config->{Host},
                PeerAddr => $my_config->{Proxy}, PeerPort => $my_config->{ProxyPort}) || die $@;
            $s->write_request(GET => $my_config->{Host}, 'User-Agent' => "Mozilla/5.0");
        }
        my($code, $mess, %h) = $s->read_response_headers;
 
        $tmp=gettimeofday() - $startTime;
        $tmp*=1000;
        $vl->{'values'}  = [ sprintf("%.2f", $tmp) ];
        append_to_file("/tmp/debug.log", "dispatching for $key is " . Dumper($vl) ) if $debug;
        plugin_dispatch_values ($vl);
    }
    return 1;
}
