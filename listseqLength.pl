#! /usr/bin/perl
use strict;
use warnings;
use Bio::SearchIO; 
use Getopt::Long;
use Bio::SeqIO;
 
# Options
#========
my $usage = "\nUsage: $0 -i <Fasta file> \n \t [Option] -o <output file> \n";
my $fastain;
my $fastaout;
my $help;
my $lenght=300;

GetOptions(
           'i=s'	  => \$fastain,
           'o=s'	=>\$fastaout,
           'h'        => \$help,
          );
if($help or !defined($fastain) ){
    print $usage;
    exit 0;
}


my $seqio_obj = Bio::SeqIO->new(-file => "$fastain", -format => "fasta" );

if(defined $fastaout){open OUT, ">$fastaout"}
while (my $seq_obj = $seqio_obj->next_seq){   
    # print the sequence  
    if(defined $fastaout){print OUT $seq_obj->id, "\t", $seq_obj->length, "\n" ;}
    else{print $seq_obj->id, "\t", $seq_obj->length, "\n"; }
}