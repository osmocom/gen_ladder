package OsmoLadder;

# Perl Module to generate ladder diagrams for network protocols
#
# (C) 2010-2011 by Harald Welte <laforge@gnumonks.org>
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


use GD;
use GD::Arrow;

my $ROW_SIZE = 50;
my $HEAD_SIZE = 70;
my $TITLE_SIZE = 20;
my $FOOT_SIZE = 50;
my $COL_SIZE_MIN = 200;
my $MARGIN_LR = 50;
my $NODELINE_OVERLAP = 30;

my $FONT = "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf";

my $graph_title;

sub compute_img_size($$)
{
	my ($num_nodes, $num_msgs) = @_;

	my $height = (($num_msgs-1) * $ROW_SIZE) +
			$HEAD_SIZE + $TITLE_SIZE + $FOOT_SIZE;
	my $width = 2*$MARGIN_LR + ($num_nodes-1)*$COL_SIZE_MIN;

	return ($width, $height);
}

sub compute_node_x($)
{
	my $node_num = shift;

	return $MARGIN_LR + $node_num * $COL_SIZE_MIN;
}

sub compute_msg_y($)
{
	my $msg_num = shift;

	return $HEAD_SIZE + $TITLE_SIZE + $msg_num * $ROW_SIZE;
}

my %nodes;
my $next_node_number = 0;
my @msgs;

sub new_node($$)
{
	my ($name, $label) = @_;
	my %nn;

	$nn{'name'} = $name;
	$nn{'label'} = $label;

	$nn{'num'} = $next_node_number++;
	$nn{'x_pos'} = compute_node_x($nn{'num'});

	$nodes{$name} = \%nn;
}

sub new_msg($$$$)
{
	my ($src, $dst, $label, $flags) = @_;
	my %nm;

	$nm{'src'} = $src;
	$nm{'dst'} = $dst;
	$nm{'label'} = $label;
	$nm{'flags'} = $flags;

	push(@msgs, \%nm);
}

sub try_fontsize($$$)
{
	my ($font, $text, $size) = @_;

	my @arr = GD::Image->stringFT(0, $font, $size, 0, 0, 0, $text);

	return ($arr[4] - $arr[0]);
}

sub get_fontsize($$$)
{
	my ($font, $text, $x_avail) = @_;
	my $fontsize;

	for ($fontsize = 12; $fontsize >= 6; $fontsize--) {
		my $width = try_fontsize($font, $text, $fontsize);
		if ($width < $x_avail) {
			return ($fontsize, $width);
		}
	}
	return (6,0);
}

sub draw_scaled_label($$$$$)
{
	my ($im, $text, $line_y, $start_x, $end_x) = @_;
	my $black = $im->colorAllocate(0, 0, 0);

	if ($start_x > $end_x) {
		my $tmp = $end_x;
		$end_x = $start_x;
		$start_x = $tmp;
	}
	my $delta_x = $end_x - $start_x;

	my ($fontsize, $x_pixels) = get_fontsize($FONT, $text, $delta_x);
	my $x_offset = ($delta_x - $x_pixels)/2;

	my @a = $im->stringFT($black, $FONT, $fontsize, 0,
			      $start_x+$x_offset, $line_y-5, $text);
}


sub draw_msg_label($$$$$)
{
	my ($im, $m, $line_y, $start_x, $end_x) = @_;
	my $text = $$m{'label'};
	draw_scaled_label($im, $text, $line_y, $start_x, $end_x);
}

sub set_title($)
{
	$graph_title = shift;
}

sub draw_graph($)
{
	my $outfile_name = shift;
	my $num_nodes = keys %nodes;
	my $num_msgs = @msgs;
	my ($x, $y) = compute_img_size($num_nodes, $num_msgs);
	my $im = new GD::Image($x, $y);

	my $white = $im->colorAllocate(255, 255, 255);
	$im->transparent($white);
	my $black = $im->colorAllocate(0, 0, 0);

	if ($graph_title) {
		my $gap_oneside = ($x/2) * 0.8;
		draw_scaled_label($im, $graph_title, $TITLE_SIZE,
				  $x/2-$gap_oneside, $x/2+$gap_oneside);
	}

	# vertical lines for each of the nodes in the graph
	foreach my $n (values %nodes) {
		printf("node %s (%s)\n", $$n{'name'}, $$n{'label'});
		my $line_x = $$n{'x_pos'};
		my $start_y = compute_msg_y(0)-$NODELINE_OVERLAP;
		my $end_y = compute_msg_y($num_msgs-1)+$NODELINE_OVERLAP;
		$im->line($line_x, $start_y, $line_x, $end_y, $black);

		my $space_oneside = ($COL_SIZE_MIN/2) * 0.8;
		draw_scaled_label($im, $$n{'label'}, $start_y-10,
				  $line_x-$space_oneside,
				  $line_x+$space_oneside);
	}

	# draw per-message arrows
	$im->setThickness(2);
	my $msg_n = 0;
	foreach my $m (@msgs) {
		my $line_y = compute_msg_y($msg_n++);
		my $start_node = $nodes{$$m{'src'}};
		my $end_node = $nodes{$$m{'dst'}};
		my $start_x = $$start_node{'x_pos'};
		my $end_x = $$end_node{'x_pos'};

		if ($$m{'flags'} =~ /\W+both\W*/) {
			# FIXME
		}
		if ($$m{'flags'} =~ /\W+dashed\W*/) {
			print("setting dahsed style\n");
			$im->setStyle($black, $black, gdTransparent,
					gdTransparent);
		}

		#$im->line($start_x, $line_y, $end_x, $line_y, $black);
		my $arrow = GD::Arrow::Full->new(-X1 => $end_x,
						 -Y1 => $line_y,
						 -X2 => $start_x,
						 -Y2 => $line_y,
						 -WIDTH => 3);
		$im->polygon($arrow, $black);

		draw_msg_label($im, $m, $line_y-5, $start_x, $end_x)
	}

	open(OUTFILE, ">$outfile_name");
	print(OUTFILE $im->png);
	close(OUTFILE);
}

1;
__END__

sub test()
{
	new_node('ms', 'MS');
	new_node('bts', 'BTS');
	new_node('bsc', 'BSC');

	new_msg('ms', 'bts', 'RACH REQ', undef);
	new_msg('bts', 'bsc', 'RSL CHAN RQD', undef);
	new_msg('bsc', 'bts', 'RSL CHAN ACT', undef);
	new_msg('bts', 'bsc', 'RSL CHAN ACT ACK', undef);

	draw_graph();
}

test();
