#!/usr/bin/perl -w
use strict;

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

my %cfg_entities;
my @cfg_entity_arr;
my $cfg_nr_entities = 0;
my @cfg_messages;

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
		my ($entity) = $line =~ /^(\S+)/;
		$cfg_entities{$entity} = $cfg_nr_entities++;
		push(@cfg_entity_arr, $entity);
	} elsif ($cfg_parse_section eq 'messages') {
		my ($src, $dst, $label, $flags) =
				$line =~ /(\S+)\s+(\S+)\s+"(.*)"(.*)/;
		my %msg;
		$msg{'src'} = $src;
		$msg{'dst'} = $dst;
		$msg{'label'} = $label;
		$msg{'flags'} = $flags;
		# store a reference to the new hash on the global pile of
		# message hash references
		#print("$src $dst $label $flags\n");
		push(@cfg_messages, \%msg);
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

# generate the nodes between which we will transfer messages
sub gen_nodes()
{
	my $num_msgs = @cfg_messages;

	foreach my $m (@cfg_entity_arr) {
		printf("  %s [shape=none]\n", $m);
	}
	print("\n");

	foreach my $m (@cfg_entity_arr) {
		my $first = 0;
		my $count;

		# initial edge between header entity and the chain
		printf("  %s -> %s0 [style=invis]\n", $m, $m);

		# chain of edges between the individual nodes of one entity
		for ($count = 0; $count < $num_msgs+1; $count++) {
			my $name = sprintf("%s%u", $m, $count);
			if ($first == 0) {
				printf("  %s ", $name);
			} else {
				printf("-> %s ", $name);
			}
			$first = 1;
		}
		print(" [weight=1000]\n");
	}
	print("\n");

	# invisible chain of edges between all entities
	my $first = 1;
	print("  { rank=same;\n    edge[style=invis]\n");
	foreach my $e (@cfg_entity_arr) {
		if ($first) {
			printf("    %s0 ", $e);
			$first = 0;
		} else {
			printf("-> %s0 ", $e);
		}
	}
	print("\n  }\n");
	print("\n");
}

sub entity_left_of($$)
{
	my $l = shift;
	my $r = shift;
	if ($cfg_entities{$l} < $cfg_entities{$r}) {
		return 1;
	} else {
		return 0;
	}
}

# generate edges for the individual messages
sub gen_edges()
{
	my $count = 1;

	foreach my $m (@cfg_messages) {
		my $l; my $r; my $dir; my $attr = "";
		if (entity_left_of($$m{'src'}, $$m{'dst'})) {
			$l = $$m{'src'};
			$r = $$m{'dst'};
			$dir = 'forward';
		} else {
			$l = $$m{'dst'};
			$r = $$m{'src'};
			$dir = 'back';
		}
		if ($$m{'flags'} =~ /\W+both\W*/) {
			$dir = 'both';
		}
		if ($$m{'flags'} =~ /\W+dashed\W*/) {
			$attr .= ' style=dashed';
		}
		print("  { rank=same;\n");
		printf("    %s%u -> %s%u [dir=%s label=\"%s\"%s]\n  }\n",
			$l, $count, $r, $count, $dir, $$m{'label'}, $attr);
		$count++;
	}
}

parse_cfg_file($ARGV[0]);

# print static header
print("digraph ladder {\n");
print("  node [shape=point]\n");
print("  edge [dir=none]\n");

# generate and print dynamic content
gen_nodes();
gen_edges();

# print footer
print("}\n");
