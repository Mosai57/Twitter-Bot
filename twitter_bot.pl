#!/usr/local/bin/perl

#########################################################################
#	Name:		Twitter_Bot.pl					#
#	Author:		Jaykob Ross					#
#	Purpose:	Creates a random, sometimes coherant sentence	#
#			and tweets it.					#
#########################################################################

use strict;
use Net::Twitter::Lite::WithAPIv1_1;
use Tie::File;

#########################
#	SET UP		#

# Obtain text files
my $file_dir = "/path/to/textfile/directory";
opendir(D, $file_dir) or die "Cannot open directory $file_dir: $!";
my @files = grep {/.txt/} readdir(D);
closedir(D);

# Obtain Key information
my @file_info;
tie @file_info, 'Tie::File', "/pth/to/twitterdata.dat" or die "Cannot tie file twitterinfo.dat: $!";

# Create Twitter object
my $twitter = Net::Twitter::Lite::WithAPIv1_1->new(		
	access_token_secret	=> $file_info[0],
	consumer_secret		=> $file_info[1],
	access_token		=> $file_info[2],
	consumer_key		=> $file_info[3],
	user_agent		=> $file_info[4],
	ssl			=> $file_info[5],
);

untie @file_info;

#	END SET-UP	#
#########################

sub gen_tweet {
	my $time_limit = time + 30;
	my $min_limit = 20;
	my $max_limit = 50;

	open(my $file, "<", $file_dir . $files[int(rand(scalar(@files)))]) 
		or die "Error, could not open a file to read from: $!";

	binmode $file, ':utf8';

	my @words;

	while(scalar(@words) < $max_limit || (scalar(@words) > $min_limit && int(rand(2)) == 0)){
		my @lines;
		for ($min_limit..$max_limit) {
    			# choose NUM_LINES random lines
    			my $idx = 0;
    			while(<$file>) {
        			$idx++;

				# Make sure the line chosen is not a blank line.
				if($_ !~ /^\s*$/i){
        				if (@lines < $max_limit) {
         					push @lines, $_;
           					next;
        				}
        				if (rand($idx / $max_limit) < 1) {
          					$lines[rand @lines] = $_;
					}
				}
    			}
		}

		for(my $idx = 0; $idx < $max_limit; $idx++){
			# Split the entire line by spaces. creating an array of every word in the sentence
			my @exploded_line = split(' ', $lines[$idx]);

			# Pick a random word from the array of words and push it to the words array
			my $word = $exploded_line[int(rand(scalar(@exploded_line)))];
			push(@words, $word);
		}
		if($time_limit < time){
			# If the program takes too long. Shouldnt ever be reached but is here as
			# a safety measure to prevent the program from hanging too long
			last;
		}
	}	
	# Join the words array into a new sentence and trim the sentence to match
	# Twitter's 140 character message limit.
	my $sentence = join(' ', @words);
	my $tweet = substr($sentence, 0, 139);	
	close $file;
	return $tweet;
}

#################
#      MAIN	#

my $text = gen_tweet();

$twitter->update($text);

#   END MAIN    #
#################
