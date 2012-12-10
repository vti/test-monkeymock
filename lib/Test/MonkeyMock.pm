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
__END__

=pod

=head1 NAME

Test::MonkeyMock

=head1 SYNOPSIS

    # Create a new mock object
    my $mock = Test::MonkeyMock->new;
    $mock->MOCK(foo => sub {'bar'});
    $mock->foo;

    # Mock existing object
    my $mock = Test::MonkeyMock->new(MyObject->new());
    $mock->MOCK(foo => sub {'bar'});
    $mock->foo;

    # Check how many times the method was CALLED
    my $count = $mock->CALLED('foo');

    # Check what arguments were passed on the first call
    my @args = $mock->CALL_ARGS('foo');

    # Check what arguments were passed on the second call
    my @args = $mock->CALL_ARGS('foo', 1);

=head1 DESCRIPTION

Why? I used and still use L<Test::MockObject> and L<Test::MockObject::Extends>
a lot but sometimes it behaves very strangely introducing hard to find global
bugs in the test code, which is very painful, since the test suite should have
as least bugs as possible. L<Test::MonkeyMock> is somewhat a subset of
L<Test::MockObject> but without side effects.

L<Test::MonkeyMock> is also very strict. When mocking a new object:

=over

=item * throw when using C<CALLED> on unmocked method

=item * throw when using C<CALL_ARGS> on unmocked method

=back

When mocking an existing object:

=over

=item * throw when using C<MOCK> on unknown method

=item * throw when using C<CALLED> on unknown method

=item * throw when using C<CALL_ARGS> on unknown method

=back

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
