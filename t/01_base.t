use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Output;
use File::Temp ();

use Log::Minimal::Instance;

my @levels = qw/crit warn info croak/;

sub _tempfile {
    my (undef, $fname) = File::Temp::tempfile;
    $fname;
}

subtest 'instance' => sub {
    my $log = Log::Minimal::Instance->new;
    isa_ok $log, 'Log::Minimal::Instance';

    for my $level (@levels) {
        for my $suffix (qw/f ff d/) {
            my $method = $level.$suffix;
            can_ok $log, $method;
        }
    }
};

subtest 'log to file' => sub {
    my $fname = _tempfile();
    my $log   = Log::Minimal::Instance->new(pattern => $fname);
    my $body  = 'file';

    for my $level (@levels) {
        my $method = $level.'f';
        if ($level eq 'croak') {
            dies_ok { $log->$method($body) } "died at level:$level";
        } else {
            $log->$method($body);
        }
    }

    open my $fh, '<', $fname or die $!;
    for my $level (@levels) {
        next if ($level eq 'croak');
        like(scalar <$fh>, qr/\[$level.*\] .*$body at/i, "level:$level");
    }
    close $fh;
};

subtest 'log to stderr' => sub {
    my $log  = Log::Minimal::Instance->new;
    my $body = 'stderr';
    for my $level (@levels) {
        my $method = $level.'f';
        if ($level eq 'croak') {
            dies_ok { $log->$method($body) } "died at level:$level";
        } else {
            stderr_like { $log->$method($body) }
                qr/\[$level.*\] .*$body.* at/i, "level: $level";
        }
    }
};

subtest 'log_to' => sub {
    my $fname1 = _tempfile();
    my $fname2 = _tempfile();

    my $log = Log::Minimal::Instance->new(pattern => $fname1);
    $log->infof('default file 1st');
    $log->log_to($fname2, 'specified file 1st'); my $log_to_line1 = __LINE__;
    $log->infof('default file 2nd');
    $log->log_to($fname2, 'specified file 2nd'); my $log_to_line2 = __LINE__;

    open my $fh1, '<', $fname1 or die $!;
    like(scalar <$fh1>, qr/\[INFO] .*default file 1st/i, "default 1st");
    like(scalar <$fh1>, qr/\[INFO] .*default file 2nd/i, "default 2nd");
    close $fh1;

    open my $fh2, '<', $fname2 or die $!;
    like(scalar <$fh2>, qr/.*specified file 1st at .*$log_to_line1/i, "specified 1st");
    like(scalar <$fh2>, qr/.*specified file 2nd at .*$log_to_line2/i, "specified 2nd");
    close $fh2;
};

done_testing;
