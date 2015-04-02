use warnings;
use strict;
use Test::More;
use Test::TCP;
use IO::Socket::IP;
use t::Server;

sub doit {
    my $host = shift;
    test_tcp(
        client => sub {
            my $port = shift;
            ok $port, "test case for sharedfork" for 1..10;
            my $sock = IO::Socket::IP->new(
                PeerPort => $port,
                PeerAddr => $host,
                Proto    => 'tcp',
                V6Only   => 1,
            ) or die "Cannot open client socket: $!";

            note "send 1";
            print {$sock} "foo\n";
            my $res = <$sock>;
            is $res, "foo\n";

            note "send 2";
            print {$sock} "bar\n";
            my $res2 = <$sock>;
            is $res2, "bar\n";

            note "finalize";
            print {$sock} "quit\n";
        },
        server => sub {
            my $port = shift;
            ok $port, "test case for sharedfork" for 1..10;
            t::Server->new($host, $port)->run(sub {
                note "new request";
                my ($remote, $line, $sock) = @_;
                print {$remote} $line;
            });
        },
        host => $host,
    );
}

subtest 'v4' => sub {
    doit('127.0.0.1');
};
subtest 'v6' => sub {
    do {
        local $@;
        my $p = eval {
            empty_port({ host => '::1' });
        };
        plan skip_all => "IPv6 not supported"
            if $@;
    };
    doit('::1');
};

done_testing;
