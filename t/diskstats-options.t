use warnings;
use strict;
use Test::Most;

require_ok('Linux::Info::DiskStats::Options');

dies_ok { Linux::Info::DiskStats::Options->new( [] ) }
'should die with wrong options reference';
like $@, qr/hash\sreference/, 'got expected error message';
dies_ok { Linux::Info::DiskStats::Options->new() }
'should die without global_block_size';
like $@, qr/block_size/, 'got expected error message';
ok(
    Linux::Info::DiskStats::Options->new( { backwards_compatible => 0 } ),
    'get instance with backwards_compatible disabled and without block sizes'
);

note('Testing with backwards compatibility');
dies_ok {
    Linux::Info::DiskStats::Options->new( { global_block_size => 4.34 } )
}
'dies with invalid value for global_block_size';
like $@, qr/integer\sas\svalue/, 'got expected error message';

dies_ok {
    Linux::Info::DiskStats::Options->new( { block_sizes => '' } )
}
'dies with invalid value for block_sizes';
like $@, qr/hash\sreference/, 'got expected error message';

dies_ok {
    Linux::Info::DiskStats::Options->new( { block_sizes => {} } )
}
'dies with invalid value for the block_sizes hash reference';
like $@, qr/at\sleast\sone\sdisk/, 'got expected error message';

dies_ok {
    Linux::Info::DiskStats::Options->new( { block_sizes => { sda => '' } } )
}
'dies with invalid value for block size in block_sizes disk';
like $@, qr/must\sbe\san\sinteger/, 'got expected error message';

ok( Linux::Info::DiskStats::Options->new( { global_block_size => 4096 } ),
    'get instance with proper global_block_size' );
ok(
    Linux::Info::DiskStats::Options->new( { block_sizes => { sda => 4096 } } ),
    'get instance with proper block_sizes'
);

done_testing;
