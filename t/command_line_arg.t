use Rex::Dondley::ProcessTaskArgs;
use Rex -feature => [qw / 1.4 / ];
use Test::More;
use Test::Exception;
use Test::Output;
use strict;
use warnings;

lives_ok { my $out = `rex -f 't/Rexfile' test1` } 'runs';
is_deeply eval_rex('test1'), { one => undef }, 'blah';
stderr_unlike { rex_cmd('test1 --one=five') } qr/ERROR/;
stderr_unlike { rex_cmd('test1 five') } qr/ERROR/;
stderr_like { rex_cmd('test1 --two=five') } qr/invalid key/i, 'blah';
stderr_like { rex_cmd('test1 five six') } qr/Too many/, 'too many array args';
is_deeply eval_rex('test2 boo bah'), { one => 'boo', two => 'bah' }, 'handles multiple args';
is_deeply eval_rex('test2 bah --one=boo'), { one => 'boo', two => 'bah' }, 'handles mix of arg types';

sub eval_rex {
  my $arg = shift;
  return eval `rex -f 't/Rexfile' $arg`;
}

sub rex_cmd {
  my $arg = shift;
  return `rex -f 't/Rexfile' $arg`;
}



#is ref run_task('one', params => [ 'blah' ]), 'HASH', 'returns a hash';
#is_deeply run_task('one', params => [ 'nuts' ]), {one => 'nuts', three => undef}, 'assigns args from hash reference';
#is_deeply run_task('one', params => [ 'nuts', 'flour' ]),{one=> 'nuts', three => 'flour'}, 'assigns multiple args';
#lives_ok { run_task('three', params => ['hi']) } 'lives if unrequired value is not passed';
#lives_ok { run_task('three', params => [ 'two', 'seven' ] ) } 'lives if unrequired value is passed';
#is_deeply run_task('five', params => [ 'boo', 'baba', 'next' ] ), {one => 'boo', two => 'baba', three => 'next'}, 'default values can be overridden';
#is_deeply run_task('six', params => [ 3 ]), {one => 3, two => undef, three => undef}, 'recognized valueless keys as not required';

done_testing();
