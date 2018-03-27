#! /usr/bin/perl
use strict;
use warnings;
use Bio::SearchIO;
use Getopt::Long;
use Bio::SeqIO;

# Options
#========
my $usage = "\nUsage: $0 -l <tab fasta file / prefix> \n \t [Option] -o <output file> \n";
$usage .= "\t\t Description: Add prefix behind every sequence names according the file of origin before concatenate sequences in a single fasta file.\n";
$usage .= "\t\t Fasta file to process and prefix are given from a file (-l <tab>) with two column (tabulated):.\n";
$usage .= "\t\t\t\t\t\t - col1: Name of the fasta file.\n";
$usage .= "\t\t\t\t\t\t - col2: Prefix to add.\n";
my $fastain;
my $tab ;
my $fastaout;
my $help;
my $seqio_out ;
GetOptions(
           'l=s'          => \$tab,
           'o=s'        =>\$fastaout,
           'h'        => \$help,
          );
if($help or !defined($tab) ){
    print $usage;
    exit 0;
}

#=================================
#	Open tab
#=================================
open IN, "<$tab" or die "Unable to open $tab file !\n";
my %files ;
while (my $i = <IN>){
	chomp $i ;
	my @words = split "\t", $i ;
	$files{$words[0]} = $words[1] ; # filename / prefix
}

#=================================
#	Open file, rename seq and print
#=================================
if(defined $fastaout){ $seqio_out = Bio::SeqIO->new(-file => ">$fastaout", -format => "fasta" );}
foreach my $i (keys %files){
	my $fastain = $i ;
	my $prefix = $files{$i} ;
	my $seqio_obj = Bio::SeqIO->new(-file => "$fastain", -format => "fasta" );
	while (my $seq_obj = $seqio_obj->next_seq){
	    # rename sequence:
	    my $oldID = $seq_obj->display_id ;
	    my $newID = $prefix."_".$oldID ;
	    $seq_obj->display_id("$newID") ;
	    
	    # print sequence
	    if(defined $fastaout){$seqio_out->write_seq($seq_obj) ;}
	    else{print ">", $seq_obj->display_id, "\n", $seq_obj->seq, "\n"; }
	} 
}
