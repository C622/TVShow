#!/usr/bin/perl -w

use strict;

package MyParser;
use base "HTML::Parser";

use LWP::Simple;


my $webpage = get("$ARGV[0]");

my $class_flag = 0;
my $div_count  = 0;
my $div = "";


sub start {
	my ($self, $tag, $attr, $attrseq, $origtext) = @_;
	if ($class_flag && $tag =~ /^div$/i) {
		$div_count++;
	}

	if (defined ($attr->{class}) && ($tag =~ /^div$/i) && ($attr->{class} =~ /^highlight_info$/i) && ! $div) {
		$class_flag = 1;
		$div_count++;
	}

	if ($class_flag) {
		$div .= $origtext;
	}
}

sub text {
	my ($self, $text) = @_;
	if ($class_flag) {
#		$text =~ s/[\t|\r]//g;
		$div .= $text;
	}
}

sub comment {
	my ($self, $comment) = @_;
	print "";
}


sub end {
	my ($self, $tag, $origtext) = @_;
	if ($class_flag) {
		$div .= $origtext;
	}

	if ($class_flag && $tag =~ /^div$/i) {
		$div_count--;
	}

	if ($div_count == 0) {
		$class_flag = 0;
	}
}


my $plain_text = new MyParser;
$plain_text->parse($webpage);

print $div, "\n";

__END__
