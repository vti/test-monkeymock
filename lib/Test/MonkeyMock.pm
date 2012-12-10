package Test::MonkeyMock;

use strict;
use warnings;

require Carp;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my ($instance) = @_;

    my $self = { instance => $instance };
    bless $self, $class;

    return $self;
}

my $magic_counter = 0;

sub MOCK {
    my $self = shift;
    my ( $method, $code ) = @_;

    if ( my $instance = $self->{instance} ) {
        Carp::croak("Unknown method '$method'")
          unless $self->can($method);

        my $new_package = ref($self) . '::' . ref($instance) . $magic_counter++;

        no strict 'refs';
        @{ $new_package . '::ISA' } = ( ref($instance) );
        *{ $new_package . '::' . $method } = $code;

        bless $instance, $new_package;

        $self->{instance} = $instance;
    }
    else {
        my $MOCKS = $self->{MOCKS} ||= {};
        $MOCKS->{$method} = $code;
    }

    return $self;
}

sub CALLED {
    my $self = shift;
    my ($method) = @_;

    my $MOCKS = $self->{MOCKS} ||= {};
    my $CALLS = $self->{CALLS} ||= {};

    if ( $self->{instance} ) {
        Carp::croak("Unknown method '$method'")
          unless $self->can($method);
    }
    else {
        Carp::croak("Unmocked method '$method'")
          unless exists $MOCKS->{$method};
    }

    return $CALLS->{$method}->{called};
}

sub CALL_ARGS {
    my $self = shift;
    my ( $method, $frame ) = @_;

    $frame ||= 0;

    my $CALLS = $self->{CALLS} ||= {};
    my $MOCKS = $self->{MOCKS} ||= {};

    if ( $self->{instance} ) {
        Carp::croak("Unknown method '$method'")
          unless $self->can($method);
    }
    else {
        Carp::croak("Unmocked method '$method'")
          unless exists $MOCKS->{$method};
    }

    Carp::croak("Method '$method' was not called")
      unless exists $CALLS->{$method};

    Carp::croak("Unknown frame '$frame'")
      unless @{ $CALLS->{$method}->{stack} } > $frame;

    return @{ $CALLS->{$method}->{stack}->[$frame] };
}

sub can {
    my $self = shift;
    my ($method) = @_;

    if ( $self->{instance} ) {
        return $self->{instance}->can($method);
    }
    else {
        my $MOCKS = $self->{MOCKS} ||= {};
        return exists $MOCKS->{$method};
    }
}

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;

    my ($method) = ( split /::/, $AUTOLOAD )[-1];

    return if $method =~ /^[A-Z]+$/;

    my $CALLS = $self->{CALLS} ||= {};
    my $MOCKS = $self->{MOCKS} ||= {};

    $CALLS->{$method}->{called}++;
    push @{ $CALLS->{$method}->{stack} }, [@_];

    Carp::croak("Unmocked method '$method'")
      if !$self->{instance} && !exists $MOCKS->{$method};

    if ( $self->{instance} ) {
        return $self->{instance}->$method(@_);
    }
    else {
        return $MOCKS->{$method}->( $self, @_ );
    }
}

1;
