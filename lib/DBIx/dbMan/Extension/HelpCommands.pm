package DBIx::dbMan::Extension::HelpCommands;

use strict;
use base 'DBIx::dbMan::Extension';
use Text::FormatTable;
use Term::ANSIColor;

our $VERSION = '0.08';

1;

sub IDENTIFICATION { return "000001-000010-000008"; }

sub preference { return 0; }

sub known_actions { return [ qw/HELP/ ]; }

sub menu {
	return ( { label => '_Help', preference => -10000, submenu => [
		{ label => 'Commands', action => { action => 'HELP', type => 'commands' } },
		{ label => 'License', action => { action => 'HELP', type => 'license' } },
		{ label => 'Version', action => { action => 'HELP', type => 'version' } }
	] } );
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'HELP') {
		if ($action{type} eq 'commands') {
			my @help = ();
			for my $ext (@{$obj->{-core}->{extensions}}) {
				if ($ext->can('cmdhelp')) {
					my %h = @{$ext->cmdhelp()};
					for (keys %h) {
						study $action{what} if $action{what};
						push @help,[ $_, $h{$_} ] if /^\Q$action{what}/i;
					}
				}
			}
			if (@help) {
                my $colorized = $obj->{-mempool}->get('output_format') eq 'colortable';
				my $table = new Text::FormatTable '| l l | l |';
				$table->rule;
				for (sort { $a->[0] cmp $b->[0] } @help) {
					$table->row( map {
                        my $r = $_;
                        $r =~ s/(\S+)/color( $obj->{-config}->tablecolor_content || 'bright_white' ) . $1 . color( $obj->{-config}->tablecolor_lines || 'reset' )/sge if $colorized;
                        $r; 
                    } ' * ',@$_);
				}
				$table->rule;
				$action{output} = ( $colorized ? color( $obj->{-config}->tablecolor_lines || 'reset' ) : '' )
                    . $table->render($obj->{-interface}->render_size) . ( $colorized ? color( 'reset' ) : '' );
			} else {
				$action{output} = "I havn't help for command ".$action{what}.".\n";
			}
			$action{action} = 'OUTPUT';
		} elsif ($action{type} eq 'version') {
			$action{output} = "dbMan version is ".$DBIx::dbMan::VERSION."\n";
			if ($action{gui}) {
				$action{action} = 'NONE';
				$obj->{-interface}->infobox($action{output});
			} else {
				$action{action} = 'OUTPUT';
			}
		} elsif ($action{type} eq 'license') {
			$action{output} = <<'EOF';
(c) Copyright 1999-2012 by Milan Sorm <sorm@is4u.cz>
All rights reserved.
			
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
EOF
			if ($action{gui}) {
				$action{action} = 'NONE';
				$obj->{-interface}->infobox($action{output});
			} else {
				$action{action} = 'OUTPUT';
			}
		}
	}

	$action{processed} = 1;
	return %action;
}
