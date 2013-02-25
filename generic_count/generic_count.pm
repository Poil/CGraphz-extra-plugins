package Collectd::Plugins::generic_count;
 
use Collectd qw( :all );
 
#use strict; # STRICT
 
use Exporter ();
use Config::General ('ParseConfig');
 
use Net::HTTP;
use Getopt::Std;
use Time::HiRes qw(gettimeofday);
use URI;
 
plugin_register (TYPE_DATASET, 'gauge', undef);
plugin_register (TYPE_CONFIG, 'generic_count', 'generic_count_config');
plugin_register (TYPE_READ, 'generic_count', 'generic_count_read');
 
#====================================================================
# Option
#====================================================================
 
sub append_to_file { my $f = shift; open(my $F, ">>$f") or die "output in file $f failed: $!\n"; print $F $_ foreach @_; 1 }
 
#====================================================================
# Connection to HTTP monitor
#====================================================================
sub generic_count_config {
    my ($config) = @_;
    use Data::Dumper;
    my %tmp_config = map { $_->{key} => $_->{values}[0] } @{$config->{children}};
    $debug = $tmp_config{debug};
    $generic_count_config{$tmp_config{PHost}.$tmp_config{ID}} = \%tmp_config;
    append_to_file("/var/log/collectd_generic_count.log", "config got called with " . Dumper($config)) if $debug;
    append_to_file("/var/log/collectd_generic_count.log", "config is " . Dumper(\%generic_count_config) ) if $debug;
}
 
sub generic_count_read {
    append_to_file("/var/log/collectd_generic_count.log", "READ got called\n") if $debug;
    my ($startTime, $tmp, $s);
 
    foreach my $key (sort keys %generic_count_config) {
        my $my_config = $generic_count_config{$key};
        my $vl= {
            name => 'generic_count',
            plugin => 'generic_count',
            type => 'gauge',
        };
        if ($my_config->{PHost}) {
           $vl->{'host'} = $my_config->{Host};
        }
        if ($my_config->{PInst}) {
           $vl->{'plugin_instance'} = $my_config->{PInst};
        }
        if ($my_config->{TInst}) {
           $vl->{'type_instance'} = $my_config->{TInst};
        }
 
        append_to_file("/var/log/collectd_generic_count.log", "looking at $key " . Dumper($my_config) ) if $debug;
 
        chomp($tmp=`$my_config->{CMD}`);
        if ($tmp =~ /^\d+$/) {
           $vl->{'values'}  = [ $tmp ];
        } else {
           $tmp='NaN'
        }
 
        append_to_file("/var/log/collectd_generic_count.log", "dispatching for $key is " . Dumper($vl) ) if $debug;
        plugin_dispatch_values ($vl);
    }
 
    return 1;
}
