#!/usr/bin/perl

# --------------------------------------------------------- #
# 				*** dokuwiki2trac.pl ***
#	Author: Emilien Mantel
#	Github: https://github.com/HanXHX/
#	Website: http://www.debianiste.org
#	Licence: GPLv2
# --------------------------------------------------------- #

use strict;
use warnings;

use feature qw/say/;
use Data::Dumper;
use Getopt::Long;

my $in_file = undef;
my $out_file = undef;
my $out_line;
my $debug = 0;


GetOptions(
	'i|in-file=s' => \$in_file,
	'o|out-file=s' => sub { $out_file = $_[1]; },
	'h|help' => sub { say STDERR "Usage: $0 -i|--in-file input-file [ -o|--out-file output-file ] [ -h|--help ] [ --debug ]\n\t-i: file to parse\n\t-o: output file (print in STDOUT if not specified)"; exit 1; },
	'debug' => \$debug
);


my $OUT_FH = *STDOUT;
if(defined $out_file)
{
	say STDERR "file created";
	open($OUT_FH, '>', $out_file) or die($!);
}


if( !defined $in_file || ! -f $in_file)
{
	say STDERR "Can't input open file";
	exit 1;
}

open('IN_FH', '<', $in_file) or die('FUCK');
my $pre_formating = 0;
while(my $line = <IN_FH>)
{
	$out_line = $line;
	chomp($out_line);
	say STDERR "|<|$out_line" if $debug;

	# === Multi-lines === 
	$pre_formating++ if($out_line =~ s#<code>#\n{{{#g);
	$pre_formating++ if($out_line =~ s#<code (\w+)>#\n{{{\n\#!$1#g);
	$pre_formating-- if($out_line =~ s#</code>#}}}#g);

	# if we are in "code block", we don't reformat
	goto FORCELOOP if $pre_formating > 0;

	# === Font ===
	# Bold
	$out_line =~ s/\*\*(.+?)\*\*/'''$1'''/g;
	# Italic
	$out_line =~ s/\/\/(.+?)\/\//''$1''/g;
	# Underlined OK
	# Monospaced
	$out_line =~ s/\{\{\{(.+?)\}\}\}/''$1''/g;
	# Strike-through
	$out_line =~ s/<del>(.+?)<\/del>/~~$1~~/g;
	# Heading
	$out_line =~ s/^(=+)(.+?)(=+)/h($1)."$2".h($3)/ge;
	# Lists
	$out_line =~ s/^(\s+)(\*|a\.|i\.|1\.)/l($1)."$2"/ge;
	# Hyperlinks
	if($out_line =~ /\[http:\/\//)
	{
		$out_line =~ s/\[\[(.+?)\|(.+?)\]\]/[$1 $2]/g;
		$out_line =~ s/\[\[(.+?)\]\]/[$1]/g;
	}
	else
	{
		$out_line =~ s/\[\[(.+)\|(.+)\]\]/[wiki:$1 $2]/g;
		$out_line =~ s/\[\[(.+)\]\]/[wiki:$1]/g;
	}

	# === Tables ===
	$out_line = tables($out_line);

	FORCELOOP:
	say $OUT_FH $out_line;
	say STDERR "|>|$out_line\n" if $debug;
}
close(IN_FH);
close($OUT_FH) if defined $out_file;


sub tables
{
	my $s = shift;
	my $new = '';

	sub a { return '|' x length($_[0]); }
	$s =~ s#([\^])(.+?)([\^]{2,})#a($3)."$2|"#ge;

	my @raw = split(/(\^)|(\|)/, $s);
	
	my $nb_separators = grep (defined $_ && /(\^)|(\|)/, @raw);	
	my $c = 1;
	my $previous_heading = 0;
	foreach my $ele(@raw)
	{
		next unless defined $ele;
		if ($ele eq '^')
		{
			if($c == $nb_separators)
			{
				$new .= '=||';
			}
			elsif($previous_heading)
			{
				$new .= '=||=';
			}
			else
			{
				$new .= '||='
			}
			$previous_heading = 1;
			$c++;
		}
		elsif($ele eq '|')
		{
			if($previous_heading)
			{
				$new .= '=||';
			}
			else
			{
				$new .= '||';
			}
			$c++;
		}
		else
		{
			$new .= $ele;
		}
	}
	return $new;
}

sub h
{
	my $s = shift;
	return '=' x (abs(length($s) - 6) + 1);
}

sub l
{
	my $s = shift;
	return ' ' x (length($s) - 2);
}
