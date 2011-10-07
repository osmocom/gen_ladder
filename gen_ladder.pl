#!/usr/bin/perl -w
use strict;

use OsmoLadder;

# Script to generate Graphviz (.dot) based ladder diagrams for network
# protocols
#
# (C) 2010 by Harald Welte <laforge@gnumonks.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


my $cfg_parse_state;
my $cfg_parse_section;

# parse a line of the config file
sub parse_cfg_line($)
{
	my $line = shift;

	if ($line =~ /^\#/ ||
	    $line =~ /^\s*$/) {
		return;
	}

	#printf("sec=%s\n", $cfg_parse_section);
	if ($line =~ /^\[/) {
		($cfg_parse_section) = $line =~ /^\[(.*)\]/;
		return;
	}
	if ($cfg_parse_section eq 'entities') {
		if (my ($entity, $label) = $line =~ /^(\S+)\s+"(.+)"/) {
			OsmoLadder::new_node($entity, $label);
		} else {
			my ($entity) = $line =~ /^(\S+)/;
			OsmoLadder::new_node($entity, $entity);
		}
	} elsif ($cfg_parse_section eq 'messages') {
		my ($src, $dst, $label, $flags) =
				$line =~ /(\S+)\s+(\S+)\s+"(.*)"(.*)/;
		#print("$src $dst $label $flags\n");
		OsmoLadder::new_msg($src, $dst, $label, $flags);
	}
}

# parse a line of the config file
sub parse_cfg_file($)
{
	my $fname = shift;
	open(INFILE, "<$fname");
	while (my $line = <INFILE>) {
		#print($line);
		chomp($line);
		parse_cfg_line($line);
	}
	close(INFILE);
}

parse_cfg_file($ARGV[0]);

OsmoLadder::draw_graph($ARGV[1]);
