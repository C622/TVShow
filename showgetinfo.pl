#!/usr/bin/perl -w

use strict;
use LWP::Simple;

my $webpage = get("$ARGV[0]");

sub read_block {
	my $input_string = $_[0];
	my $block_start = $_[1];
	my $block_in = $_[2];
	my $block_out = $_[3];
	my $return_string;
	
	my $block_count = 0;
	my $in_block = 1;

	foreach my $line ( (split /\n/, $input_string) ) {
		if ( $line =~ m/$block_start/i ) {
			$in_block = 0;
		}
		if ( $in_block eq 0 ) {
			$return_string .= "$line\n";
			if ( $line =~ m/$block_in/i ) { $block_count = $block_count+1; }
			if ( $line =~ m/$block_out/i ) { $block_count = $block_count-1; }
			if ( $block_count eq 0 ) {
				return $return_string;
				last;
			}
		}
	}
}

sub return_single {
	my $input_string = $_[0];
	my $start_string = $_[1];
	my $end_string = $_[2];
	my $return_string;
	
	if ( defined $_[3] ) {
		$return_string .= $_[3];
	}
	
	foreach my $line ( (split /\n/, $input_string) ) {
		if ( $line =~ m/^.*$start_string(.*?)$end_string/ ) {
			$return_string .= $1;
			return $return_string;
		}
	}
}

## Select the wanted "header" block for name and status information, from the webpage
my $show_head_block = read_block ($webpage, "<div class=\"m show_head\"", "<div", "<\/div>");

## Select the wanted blocks for name and status, from the "header" block
my $show_name = read_block ($show_head_block, "<h1 data-name", "<h1", "<\/h1>");
my $show_state = read_block ($show_head_block, "<div class=\"tagline", "<div", "<\/div>");

## Select the string with name and status information from respective blocks
my $show_name_line = return_single ($show_name, "<h1 data-name=\"", "\"");
my $show_state_line = return_single ($show_state, "<span>[ ]", "<\/div>");

## if nothing was returned in the status string, try a second format. (Show status "ended", will be in this format)
if ( $show_state_line eq "" ) {
	$show_state_line = return_single ($show_state, "\\(", "\\)");
	$show_state_line = ucfirst ($show_state_line);
}

## Select the wanted block for previous episode information, from the webpage
my $previous_episode_block = read_block ($webpage, "<div class=\"previous_episode\">", "<div", "<\/div>");

## Select the wanted blocks for date, name and season/episode from the previous episode block
my $previous_episode_date = read_block ($previous_episode_block, "<p class=\"highlight_date", "<p", "<\/p>");
my $previous_episode_name = read_block ($previous_episode_block, "div class=\"highlight_name", "<div", "<\/div>");
my $previous_episode_season = read_block ($previous_episode_block, "<p class=\"highlight_season", "<p", "<\/p>");

## Select the wanted string for date, name, season and episode from the respective blocks
my $previous_episode_date_line = return_single ($previous_episode_date, "AIRED ON ", "\$");
my $previous_episode_name_line = return_single ($previous_episode_name, "<a href=.*>", "</a>");
my $previous_episode_season_line = return_single ($previous_episode_season, "Season ", " : Episode");
my $previous_episode_episode_line = return_single ($previous_episode_season, " : Episode ", "\$");

## Select the wanted block for next episode information, from the webpage
my $next_episode_block = read_block ($webpage, "<div class=\"next_episode", "<div", "<\/div>");

## Select the wanted blocks for date, name and season/episode from the next episode block
my $next_episode_date = read_block ($next_episode_block, "<p class=\"highlight_date", "<p", "<\/p>");
my $next_episode_name = read_block ($next_episode_block, "div class=\"highlight_name", "<div", "<\/div>");
my $next_episode_season = read_block ($next_episode_block, "<p class=\"highlight_season", "<p", "<\/p>");

## Select the wanted string for date, name, season and episode from the respective blocks
my $next_episode_date_line = return_single ($next_episode_date, "AIRS ON ", "\$");
my $next_episode_name_line = return_single ($next_episode_name, "<a href=.*>", "</a>");
my $next_episode_season_line = return_single ($next_episode_season, "Season ", " : Episode");
my $next_episode_episode_line = return_single ($next_episode_season, " : Episode ", "\$");

## if nothing was returned in the date string, try a second format. (Show status "TONIGHT", will be in this format)
if ( $next_episode_date_line eq "" ) {
	if ( $next_episode_date_line = return_single ($next_episode_date, "AT ", "\$") ) {
		$next_episode_date_line = "Tonight at $next_episode_date_line";
	}
}

## Reformat date format of next and previous episode date string: 4/15/2014 -> 15/4 2014
unless ($previous_episode_date_line eq "") {
	$previous_episode_date_line =~ /^(.*)\/(.*)\/(.*)$/;
	$previous_episode_date_line = "$2\/$1 $3";
}
unless ($next_episode_date_line eq "") {
	unless ($next_episode_date_line =~ m/^Tonight at/) {
		$next_episode_date_line =~ /^(.*)\/(.*)\/(.*)$/;
		$next_episode_date_line = "$2\/$1 $3";
	}
}

## Replace &#39; with "'", from name strings
unless ($show_name_line eq "") {$show_name_line =~ s/&#39;/\'/g;}
unless ($previous_episode_name_line eq "") {$previous_episode_name_line =~ s/&#39;/\'/g;}
unless ($next_episode_name eq "") {$next_episode_name =~ s/&#39;/\'/g;}

## Print all information strings
# unless ($show_name_line eq "") {
	print "show=\"$show_name_line\"\n";
# }
# unless ($show_state_line eq "") {
	print "state=\"$show_state_line\"\n";
# }
# unless ($previous_episode_date_line eq "") {
	print "last=\"$previous_episode_date_line\"\n";
# }
# unless ($previous_episode_name_line eq "") {
	print "last_titel=\"$previous_episode_name_line\"\n";
# }
# unless ($previous_episode_season_line eq "") {
	print "last_season=\"$previous_episode_season_line\"\n";
# }
# unless ($previous_episode_episode_line eq "") {
	print "last_episode=\"$previous_episode_episode_line\"\n";
# }
# unless ($next_episode_date_line eq "") {
	print "next=\"$next_episode_date_line\"\n";
# }
# unless ($next_episode_name_line eq "") {
	print "next_titel=\"$next_episode_name_line\"\n";
# }
# unless ($next_episode_season_line eq "") {
	print "next_season=\"$next_episode_season_line\"\n";
# }
# unless ($next_episode_episode_line eq "") {
	print "next_episode=\"$next_episode_episode_line\"\n";
# }
__END__
