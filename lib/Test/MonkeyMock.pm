package Test::MonkeyMock;

use strict;
use warnings;

require Carp;

our $VERSION = '0.05';

my $magic_counter = 0;

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my ($instance) = @_;

    my $self = {};
    bless $self, $class;

    if ($instance) {
        my $new_package =
          __PACKAGE__ . '::' . ref($instance) . '::' . ($magic_counter++);

        no strict 'refs';
        @{$new_package . '::ISA'} = (ref($instance));

        for my $method (
            qw/
            mock
            mocked_called
            mocked_call_args
            mocked_call_stack
            mocked_return_args
            mocked_return_stack
            /
          )
        {
            *{$new_package . '::' . $method} = sub { goto &$method };
        }

        bless $instance, $new_package;

        $instance->{__PACKAGE__ . '::instance'}++;

        return $instance;
    }

    return $self;
}

sub mock {
    my $self = shift;
    my ($method, $code) = @_;

    if (my $instance = $self->{__PACKAGE__ . '::instance'}) {
        Carp::croak("Unknown method '$method'")
          unless my $orig_method = $self->can($method);

        my $ref_self = ref($self);
        my $package = __PACKAGE__;
        $ref_self =~ s/^${package}::.*::\d+//;

        my $new_package = __PACKAGE__ . '::' . $ref_self . '::' . $magic_counter++;

        no strict 'refs';
        @{$new_package . '::ISA'} = ref($self);
        *{$new_package . '::' . $method} = sub {
            my $instance = shift;

            my $calls   = $self->{__PACKAGE__ . '::calls'}   ||= {};
            my $returns = $self->{__PACKAGE__ . '::returns'} ||= {};
            my $mocks   = $self->{__PACKAGE__ . '::mocks'}   ||= {};

            $calls->{$method}->{called}++;

            push @{$calls->{$method}->{stack}}, [@_];

            my @result;

            unshift @_, $instance;
            if ($code) {
                @result = $code->(@_);
            }
            else {
                @result = $orig_method->(@_);
            }

            push @{$returns->{$method}->{stack}}, [@result];

            return wantarray ? @result : $result[0];
        };

        bless $self, $new_package;

        $self->{__PACKAGE__ . '::instance'}++;
    }
    else {
        my $mocks = $self->{__PACKAGE__ . '::mocks'} ||= {};
        $mocks->{$method} = $code;
    }

    return $self;
}

sub mocked_instance {
    my $self = shift;

    return $self->{__PACKAGE__ . '::instance'};
}

sub mocked_called {
    my $self = shift;
    my ($method) = @_;

    my $mocks = $self->{__PACKAGE__ . '::mocks'} ||= {};
    my $calls = $self->{__PACKAGE__ . '::calls'} ||= {};

    if ($self->{__PACKAGE__ . '::instance'}) {
        Carp::croak("Unknown method '$method'")
          unless $self->can($method);
    }
    else {
        Carp::croak("Unmocked method '$method'")
          unless exists $mocks->{$method};
    }

    return $calls->{$method}->{called} || 0;
}

sub mocked_call_args {
    my $self = shift;
    my ($method, $frame) = @_;

    $frame ||= 0;

    my $stack = $self->mocked_call_stack($method);

    Carp::croak("Unknown frame '$frame'")
      unless @$stack > $frame;

    return @{$stack->[$frame]};
}

sub mocked_call_stack {
    my $self = shift;
    my ($method) = @_;

    Carp::croak("Method is required") unless $method;

    my $calls = $self->{__PACKAGE__ . '::calls'} ||= {};
    my $mocks = $self->{__PACKAGE__ . '::mocks'} ||= {};

    if ($self->{__PACKAGE__ . '::instance'}) {
        Carp::croak("Unknown method '$method'")
          unless $self->can($method);
    }
    else {
        Carp::croak("Unmocked method '$method'")
          unless exists $mocks->{$method};
    }

    Carp::croak("Method '$method' was not called")
      unless exists $calls->{$method};

    return $calls->{$method}->{stack};
}

sub mocked_return_args {
    my $self = shift;
    my ($method, $frame) = @_;

    $frame ||= 0;

    my $stack = $self->mocked_return_stack($method);

    Carp::croak("Unknown frame '$frame'")
      unless @$stack > $frame;

    return @{$stack->[$frame]};
}

sub mocked_return_stack {
    my $self = shift;
    my ($method) = @_;

    Carp::croak("Method is required") unless $method;

    my $returns = $self->{__PACKAGE__ . '::returns'} ||= {};
    my $mocks   = $self->{__PACKAGE__ . '::mocks'}   ||= {};

    if ($self->{__PACKAGE__ . '::instance'}) {
        Carp::croak("Unknown method '$method'")
          unless $self->can($method);
    }
    else {
        Carp::croak("Unmocked method '$method'")
          unless exists $mocks->{$method};
    }

    Carp::croak("Method '$method' was not called")
      unless exists $returns->{$method};

    return $returns->{$method}->{stack};
}

sub can {
    my $self = shift;
    my ($method) = @_;

    if ($self->{__PACKAGE__ . '::instance'}) {
        return $self->can($method);
    }
    else {
        my $mocks = $self->{__PACKAGE__ . '::mocks'} ||= {};
        return $mocks->{$method};
    }
}

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;

    my ($method) = (split /::/, $AUTOLOAD)[-1];

    return if $method =~ /^[A-Z]+$/;

    my $calls   = $self->{__PACKAGE__ . '::calls'}   ||= {};
    my $returns = $self->{__PACKAGE__ . '::returns'} ||= {};
    my $mocks   = $self->{__PACKAGE__ . '::mocks'}   ||= {};

    Carp::croak("Unmocked method '$method'")
      if !exists $mocks->{$method};

    $calls->{$method}->{called}++;

    push @{$calls->{$method}->{stack}}, [@_];

    my @result = $mocks->{$method}->($self, @_);

    push @{$returns->{$method}->{stack}}, [@result];

    return wantarray ? @result : $result[0];
}

1;
__END__

=pod

=head1 NAME

Test::MonkeyMock - Usable mock class

=head1 SYNOPSIS

    # Create a new mock object
    my $mock = Test::MonkeyMock->new;
    $mock->mock(foo => sub {'bar'});
    $mock->foo;

    # Mock existing object
    my $mock = Test::MonkeyMock->new(MyObject->new());
    $mock->mock(foo => sub {'bar'});
    $mock->foo;

    # Check how many times the method was called
    my $count = $mock->mocked_called('foo');

    # Check what arguments were passed on the first call
    my @args = $mock->mocked_call_args('foo');

    # Check what arguments were passed on the second call
    my @args = $mock->mocked_call_args('foo', 1);

    # Get all the stack
    my $call_stack = $mock->mocked_call_stack('foo');

=head1 DESCRIPTION

Why? I used and still use L<Test::MockObject> and L<Test::MockObject::Extends>
a lot but sometimes it behaves very strangely introducing hard to find global
bugs in the test code, which is very painful, since the test suite should have
as least bugs as possible. L<Test::MonkeyMock> is somewhat a subset of
L<Test::MockObject> but without side effects.

L<Test::MonkeyMock> is also very strict. When mocking a new object:

=over

=item * throw when using C<mocked_called> on unmocked method

=item * throw when using C<mocked_call_args> on unmocked method

=back

When mocking an existing object:

=over

=item * throw when using C<mock> on unknown method

=item * throw when using C<mocked_called> on unknown method

=item * throw when using C<mocked_call_args> on unknown method

=back

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
