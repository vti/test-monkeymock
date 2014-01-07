# NAME

Test::MonkeyMock - Usable mock class

# SYNOPSIS

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

# DESCRIPTION

Why? I used and still use [Test::MockObject](http://search.cpan.org/perldoc?Test::MockObject) and [Test::MockObject::Extends](http://search.cpan.org/perldoc?Test::MockObject::Extends)
a lot but sometimes it behaves very strangely introducing hard to find global
bugs in the test code, which is very painful, since the test suite should have
as least bugs as possible. [Test::MonkeyMock](http://search.cpan.org/perldoc?Test::MonkeyMock) is somewhat a subset of
[Test::MockObject](http://search.cpan.org/perldoc?Test::MockObject) but without side effects.

[Test::MonkeyMock](http://search.cpan.org/perldoc?Test::MonkeyMock) is also very strict. When mocking a new object:

- throw when using `mocked_called` on unmocked method
- throw when using `mocked_call_args` on unmocked method

When mocking an existing object:

- throw when using `mock` on unknown method
- throw when using `mocked_called` on unknown method
- throw when using `mocked_call_args` on unknown method

# AUTHOR

Viacheslav Tykhanovskyi, `vti@cpan.org`.

# COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
