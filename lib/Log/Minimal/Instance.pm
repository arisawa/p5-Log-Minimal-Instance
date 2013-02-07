package Log::Minimal::Instance;

use strict;
use warnings;
use parent 'Log::Minimal';
use File::Stamped;

our $VERSION = '0.01';
our $TRACE_LEVEL = 0;

BEGIN {
    # for object methods
    for my $level (qw/crit warn info debug croak/) {
        for my $suffix (qw/f ff d/) {
            my $method = $level.$suffix;
            next if $method eq 'debugd';

            my $parent_code = Log::Minimal->can( ($suffix eq 'd') ? $level."f" : $method );

            no strict 'refs';
            my $code = sub {
                my $self = shift;
                my $pattern = $self->{pattern};
                local $Log::Minimal::TRACE_LEVEL = $self->{trace_level} || 1;
                local $Log::Minimal::LOG_LEVEL = uc $self->{log_level} if $self->{log_level};
                local $Log::Minimal::PRINT = $self->{_print};
                $parent_code->( ($suffix eq 'd') ? Log::Minimal::ddf(@_) : @_ );
            };
            *{$method} = $code;
        }
    }
}

sub new {
    my ($class, %args) = @_;

    my $pattern = $args{pattern} || undef;
    my $fh      = $pattern ? File::Stamped->new( pattern => $pattern ) : undef;

    bless {
        trace_level => $args{trace_level} || 0,
        log_level   => $args{log_level}   || 'DEBUG',
        pattern => $pattern,
        _print  => $fh ? sub {
            my ($time, $type, $message, $trace) = @_;
            print {$fh}  "$time [$type] $message at $trace\n"
        } : sub {
            my ($time, $type, $message, $trace) = @_;
            print STDERR "$time [$type] $message at $trace\n"
        },
    }, $class;
}

sub log_to {
    my ($self, $pattern, $message) = @_;

    my $fh = File::Stamped->new( pattern => $pattern );

    my $print = $self->{_print};

    local $Log::Minimal::TRACE_LEVEL = $self->{trace_level} || 1;
    local $Log::Minimal::LOG_LEVEL = uc $self->{log_level} if $self->{log_level};
    local $Log::Minimal::PRINT = sub {
        my ($time, $type, $message, $trace) = @_;
        print {$fh} "$time $message at $trace\n";
    };

    # Must be logging!
    local $Log::Minimal::LOG_LEVEL = 'DEBUG';
    Log::Minimal::_log('CRITICAL', 0, $message);

    $self->{_print} = $print;
}

sub debugd {
    my ($self, @m) = @_;

    my $print = $self->{_print};

    local $Log::Minimal::TRACE_LEVEL = $self->{trace_level} || 0;
    local $Log::Minimal::PRINT = sub {
        my ($time, $type, $message, $trace, $raw) = @_;
        local $Data::Dumper::Indent = 1;
        local $Data::Dumper::Terse  = 1;
        local $Data::Dumper::Useqq  = 1;
        local $Data::Dumper::Sortkeys = 1;
        $message = Data::Dumper::Dumper($raw);

        print STDERR "[$type DUMP]\n $message at $trace\n";
    };
    Log::Minimal::_log('DEBUG', 0, \@m);

    $self->{_print} = $print;
}


1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

Log::Minimal::Instance - Instance based on Log::Minimal

=head1 SYNOPSIS

  use Log::Minimal::Instance;

  # log to file
  my $log = Log::Minimal::Instance->new(
      pattern => './log/myapp.log.%Y%m%d',  # File::Stamped style
  );
  $log->debugf('debug');  # same of Log::Minimal
  $log->infof('info');

  # ./log/myapp.log.20130101 
  2013-01-01T16:15:39 [DEBUG] debug at lib/MyApp.pm line 10
  2013-01-01T16:15:39 [INFO] info at lib/MyApp.pm line 11
  ## You cannot specify format now ;(

  # log to stderr
  $log = Log::Minimal::Instance->new();

  # specified $Log::Minimal::LOG_LEVEL
  $log = Log::Minimal::Instance->new(
      level => 'WARN',
  );

  # original methods
  $log->infod(\%hash);
  $log->warnd(\@array);
  $log->log_to($pattern, $message);

=head1 DESCRIPTION

Log::Minimal::Instance is used in Log::Minimal based module to create an instance.

=head1 IMPORTED METHODS

See L<Log::Minimal>

=over 4

=item critf

=item warnf

=item infof

=item debugf

=item critff

=item warnff

=item infoff

=item debugff

=back

=head1 ORIGINAL METHODS

=over 4

=item critd($value)

=item warnd($value)

=item infod($value)

=item debugd($value)

=back

When expressed in code the above methods:

  use Log::Minimal;
  infof( ddf(\%hash) );

=over 4

=item log_to($pattern, $message)

  # $pattern is File::Stamped style.
  $log->log_to('./log/trace.log.%Y%m%d', 'traceroute');

  # ./log/trace.log.20130101
  2013-01-01T16:15:40 traceroute at lib/MyApp.pm line 13

=back

=head1 AUTHOR

Kosuke Arisawa E<lt>arisawa@gmail.com<gt>

=head1 COPYRIGHT

Copyright 2013- Kosuke Arisawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
