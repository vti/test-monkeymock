use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Test::MonkeyMock;

subtest 'mock method' => sub {
    my $mock = Test::MonkeyMock->new();
    $mock->MOCK( foo => sub { 'bar' } );

    is( $mock->foo, 'bar' );
};

subtest 'remember how many times method was called' => sub {
    my $mock = Test::MonkeyMock->new();
    $mock->MOCK( foo => sub { 'bar' } );

    $mock->foo;
    $mock->foo;
    $mock->foo;

    is( $mock->CALLED('foo'), 3 );
};

subtest 'remember the stack' => sub {
    my $mock = Test::MonkeyMock->new();
    $mock->MOCK( foo => sub { 'bar' } );

    $mock->foo;
    $mock->foo(1);
    $mock->foo('Hi there!');

    is_deeply( [ $mock->CALL_ARGS( 'foo', 0 ) ], [] );
    is_deeply( [ $mock->CALL_ARGS( 'foo', 1 ) ], [1] );
    is_deeply( [ $mock->CALL_ARGS( 'foo', 2 ) ], ['Hi there!'] );
};

subtest 'throw on unknown frame' => sub {
    my $mock = Test::MonkeyMock->new();
    $mock->MOCK( foo => sub { 'bar' } );

    $mock->foo;

    like( exception { $mock->CALL_ARGS( 'foo', 1 ) }, qr/Unknown frame '1'/ );
};

subtest 'throw on unmocked method when counting calls' => sub {
    my $mock = Test::MonkeyMock->new();

    like( exception { $mock->CALLED('foo') }, qr/Unmocked method 'foo'/ );
};

subtest 'throw on unmocked method when getting stack' => sub {
    my $mock = Test::MonkeyMock->new();

    like( exception { $mock->CALL_ARGS('foo') }, qr/Unmocked method 'foo'/ );
};

subtest 'throw on unmocked method' => sub {
    my $mock = Test::MonkeyMock->new();

    like( exception { $mock->foo }, qr/Unmocked method 'foo'/ );
};

done_testing;
