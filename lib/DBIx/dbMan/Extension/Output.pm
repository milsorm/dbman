package DBIx::dbMan::Extension::Output;

use strict;
use base 'DBIx::dbMan::Extension';
use utf8;

our $VERSION = '0.04';

1;

sub IDENTIFICATION { return "000001-000016-000004"; }

sub preference { return -100; }

sub known_actions { return [ qw/OUTPUT/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'OUTPUT') {
		$obj->{-interface}->print( $action{output} );
		$action{action} = 'NONE';
	}

	$action{processed} = 1;
	return %action;
}
