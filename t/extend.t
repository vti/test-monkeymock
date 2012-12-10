use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Test::MonkeyMock;

package MyClass;
use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    return $self;
}

sub foo { shift->{foo} }
sub bar { shift->{bar} }

package main;

subtest 'mock existing method' => sub {
    my $mock =
      Test::MonkeyMock->new( MyClass->new( foo => 'foo', bar => 'bar' ) );
    $mock->MOCK( foo => sub { 'bar' } );

    is( $mock->foo, 'bar' );
};

subtest 'thrown when mocking unknown method' => sub {
    my $mock =
      Test::MonkeyMock->new( MyClass->new( foo => 'foo', bar => 'bar' ) );

    like(
        exception {
            $mock->MOCK( 'unknown_method' => sub { 'haha' } );
        },
        qr/Unknown method 'unknown_method'/
    );
};

subtest 'remember how many times method was called' => sub {
    my $mock =
      Test::MonkeyMock->new( MyClass->new( foo => 'foo', bar => 'bar' ) );

    $mock->foo;
    $mock->foo;
    $mock->foo;

    is( $mock->CALLED('foo'), 3 );
};

subtest 'remember how many times mocked method was called' => sub {
    my $mock =
      Test::MonkeyMock->new( MyClass->new( foo => 'foo', bar => 'bar' ) );
    $mock->MOCK( foo => sub { 'bar' } );

    $mock->foo;
    $mock->foo;
    $mock->foo;

    is( $mock->CALLED('foo'), 3 );
};

subtest 'remember the stack' => sub {
    my $mock =
      Test::MonkeyMock->new( MyClass->new( foo => 'foo', bar => 'bar' ) );
    $mock->MOCK( foo => sub { 'bar' } );

    $mock->foo;
    $mock->foo(1);
    $mock->foo('Hi there!');

    is_deeply( [ $mock->CALL_ARGS( 'foo', 0 ) ], [] );
    is_deeply( [ $mock->CALL_ARGS( 'foo', 1 ) ], [1] );
    is_deeply( [ $mock->CALL_ARGS( 'foo', 2 ) ], ['Hi there!'] );
};

subtest 'throw on unknown frame' => sub {
    my $mock =
      Test::MonkeyMock->new( MyClass->new( foo => 'foo', bar => 'bar' ) );
    $mock->MOCK( foo => sub { 'bar' } );

    $mock->foo;

    like( exception { $mock->CALL_ARGS( 'foo', 1 ) }, qr/Unknown frame '1'/ );
};

subtest 'throw on unmocked method when counting calls' => sub {
    my $mock =
      Test::MonkeyMock->new( MyClass->new( foo => 'foo', bar => 'bar' ) );

    like(
        exception { $mock->CALLED('unknown_method') },
        qr/Unknown method 'unknown_method'/
    );
};

subtest 'throw on unknown method when getting stack' => sub {
    my $mock =
      Test::MonkeyMock->new( MyClass->new( foo => 'foo', bar => 'bar' ) );

    like( exception { $mock->CALL_ARGS('unknown_method') },
        qr/Unknown method 'unknown_method'/ );
};

done_testing;
