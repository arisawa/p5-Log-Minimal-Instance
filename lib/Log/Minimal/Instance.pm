package Log::Minimal::Instance;

use strict;
use warnings;
use parent 'Log::Minimal';
use File::Stamped;

our $VERSION = '0.01';

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
                local $Log::Minimal::TRACE_LEVEL = ($Log::Minimal::TRACE_LEVEL||0) + 1;
                local $Log::Minimal::LOG_LEVEL   = $self->{level};
                local $Log::Minimal::PRINT       = $self->{_print};
                $parent_code->( ($suffix eq 'd') ? Log::Minimal::ddf(@_) : @_ );
            };
            *{$method} = $code;
        }
    }
}

sub new {
    my ($class, %args) = @_;

    my $pattern  = $args{pattern}  || undef;
    my $base_dir = $args{base_dir} || '.';

    my $fh;
    if ($pattern) {
        $pattern = $class->_build_pattern($base_dir, $pattern);
        $fh = File::Stamped->new( pattern => $pattern );
    }
    else {
        $fh = *STDERR;
    }

    bless {
        level    => $args{level} || 'DEBUG',
        pattern  => $pattern,
        base_dir => $base_dir,
        _fh      => $fh,
        _print   => sub {
            my ($time, $type, $message, $trace) = @_;
            print {$fh}  "$time [$type] $message at $trace\n"
        },
    }, $class;
}

sub log_to {
    my ($self, $pattern, @args) = @_;

    $pattern = $self->_build_pattern($self->{base_dir}, $pattern);
    my $fh   = File::Stamped->new( pattern => $pattern );

    local $self->{_print} = sub {
        my ($time, $type, $message, $trace) = @_;
        print {$fh} "$time $message at $trace\n";
    };

    # Must be logging!
    local $Log::Minimal::LOG_LEVEL = 'DEBUG';
    $self->critf(@args);
}

sub debugd {
    my ($self, $stuff) = @_;

    local $Log::Minimal::TRACE_LEVEL = ($Log::Minimal::TRACE_LEVEL||0) + 1;
    local $self->{_print} = sub {
        my ($time, $type, $message, $trace, $raw_message) = @_;
        local $Data::Dumper::Indent   = 1;
        local $Data::Dumper::Terse    = 1;
        local $Data::Dumper::Useqq    = 1;
        local $Data::Dumper::Sortkeys = 1;
        $message = Data::Dumper::Dumper($raw_message);

        print { $self->{_fh} } "$time [$type DUMP]\n$message at $trace\n";
    };
    $self->debugf($stuff);
}

sub _build_pattern {
    my ($self, $base_dir, $pattern) = @_;

    unless (File::Spec->file_name_is_absolute($pattern)) {
        $pattern = File::Spec->catfile($base_dir, $pattern);
    }
    return $pattern;
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
