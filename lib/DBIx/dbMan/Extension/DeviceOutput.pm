package DBIx::dbMan::Extension::DeviceOutput;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.04';

1;

sub IDENTIFICATION { return "000001-000018-000004"; }

sub preference { return -50; }

sub known_actions { return [ qw/OUTPUT/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'OUTPUT' and $action{output_device}) {
		$action{output_device} = ">>$action{output_device}" if $action{output_device} !~ /^[|>]./;
		if (open F,$action{output_device}) {
            if ( $obj->{ -interface }->is_utf8 ) {
                binmode F, ':utf8';
            }
			print F $action{output};
			close F;
			$action{action} = 'NONE' unless $action{output_save_copy};
		}
	}

	$action{processed} = 1;
	return %action;
}
