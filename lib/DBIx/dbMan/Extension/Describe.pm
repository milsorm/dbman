package DBIx::dbMan::Extension::Describe;

use strict;
use base 'DBIx::dbMan::Extension';
use Term::ANSIColor;

our $VERSION = '0.07';

1;

sub IDENTIFICATION { return "000001-000032-000007"; }

sub preference { return 0; }

sub known_actions { return [ qw/DESCRIBE/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'DESCRIBE') {
		$action{action} = 'NONE';
		unless ($obj->{-dbi}->current) {
			$obj->{-interface}->error("No current connection selected.");
			return %action;
		}	

        my $colorized = $obj->{-mempool}->get('output_format') eq 'colortable';

		if ($action{oper} eq 'complete') {
			my $sth = $obj->{-dbi}->table_info();
			my $ret = $sth->fetchall_arrayref();
			my @all = ();
			if (defined $ret) {
				for (@$ret) {
					if ($_->[3] =~ /^(table|view)$/i) {
						push @all,$_->[2];
						push @all,$_->[1].'.'.$_->[2] if $_->[1];
					}
				}
			}
			$sth->finish;
			$action{list} = \@all;
			$action{action} = 'CACHE';
			$action{what} = 'list';
			$action{cache_type} = 'describe_std';
			$action{processed} = 1;
			return %action;
		}

		my $table = new Text::FormatTable '| l | l | l | l | l |';
		$table->rule;
		$table->head(map { $colorized ? color( $obj->{-config}->tablecolor_head || 'bright_yellow' ) . $_ . color( $obj->{-config}->tablecolor_lines || 'reset' ) : $_; } 'COLUMN','TYPE','SIZE','SCALE','NULLABLE');
		$table->rule;

		my $sth = $obj->{-dbi}->prepare(q!SELECT * FROM !.$action{what}.q! WHERE 0 = 1!);
		unless (defined $sth) {
			$action{action} = 'OUTPUT';
			$action{output} = '';
            $obj->{-interface}->error( $obj->{-dbi}->errstr() );
			$action{processed} = 1;
			return %action;
		}
		my $ret = $sth->execute();
		if (defined $ret) {
			my @type = map { (defined $obj->{-dbi}->type_info($_)) 
				? (scalar $obj->{-dbi}->type_info($_)->{TYPE_NAME})
				: $_ } @{$sth->{TYPE}};
			my @prec = @{$sth->{PRECISION}};
			my @scale = @{$sth->{SCALE}};
			my @null = @{$sth->{NULLABLE}};
			my %nullcvt = qw/0 no 1 yes 2 unknown/;
			$nullcvt{''} = 'no';
			for (@{$sth->{NAME}}) {
				$table->row(map { $colorized ? color( $obj->{-config}->tablecolor_content || 'bright_white' ) . $_ . color( $obj->{-config}->tablecolor_lines || 'reset' ) : $_; } $_,shift @type,shift @prec,shift @scale,$nullcvt{shift @null});
			}
		} else {
			$obj->{-interface}->error("Table $action{what} not found.");
			return %action;
		}
		$sth->finish;
		$table->rule;
		$action{action} = 'OUTPUT';
		$action{output} = ( $colorized ? color( $obj->{-config}->tablecolor_lines || 'reset' ) : '' )
            . $table->render($obj->{-interface}->render_size) . ( $colorized ? color( 'reset' ) : '' );
	}

	$action{processed} = 1;
	return %action;
}
