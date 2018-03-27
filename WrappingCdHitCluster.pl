#! /usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

# Options
#========
my $usage = "\nUsage: $0 -c <cluster file> \n \t [Option] -o <output file suffix> \n\t          -l <list Clusters present by TSA> \n";
my $cluster ;
my @limitBinSize = (500, 1000);
my $out="_wrapping";
my $help;
my $list;
GetOptions(
           'c=s'          => \$cluster,
           'o=s'        =>\$out,
	   'l'        =>\$list,
           'h'        => \$help,
          );
if($help or !defined($cluster) ){
    print $usage;
    exit 0;
}

# Open cluster and store informations
# ===================================
open IN, "<$cluster" or die "Unable to open $cluster file !\n" ;
# Change local separator to fit the cd-hit-cluster file
local $/ = ">Cluster";

#
# per cluster REF/ALT (TSANAME -> length)
my %dataCluster ;
my %dataClusterListTSA ;
my %InitialNumberOfSequencesPerTSA ;
while(my $i =<IN>){
	chomp $i ; 
	my @lines = split "\n", $i ;
	my $NameCluster = "Cluster".shift(@lines) ;
	$NameCluster =~ s/ // ;
# 	print $NameCluster, "\n" ;
	
	# then wrapping cluster content :
	foreach my $hit (@lines){
		chomp $hit ;
		my @infosHit = split / +/, $hit ;
# 		my $Hitlength = $infosHit[1] ;
		my $Hitlength = shift @infosHit ;
# 		print $Hitlength, "--" ;
		$Hitlength =~ s/([0-9]+)\s+([0-9]+)nt,$/$2/ ;
# 		my $HitTsaName =  $infosHit[2] ;
		my $HitTsaName =  shift @infosHit ;
# 		print "$HitTsaName --" ;
		$HitTsaName =~ s/>([A-Z]+)_.+/$1/ ;
# 		print "$HitTsaName $Hitlength\n" ;
		#count number of seq per TSA
		if(defined $InitialNumberOfSequencesPerTSA{$HitTsaName}){
			$InitialNumberOfSequencesPerTSA{$HitTsaName}++ ;
		}else{
			$InitialNumberOfSequencesPerTSA{$HitTsaName} = 1 ;
		}
		#Check if sequence is reference or alternative
		my $Id = join " ", @infosHit ;
# 		print $Id."\n" ;
# 		print $infosHit[3]."\n" ;
# 		my $ClusterRef;
		if($Id =~ /\*/){
# 			$ClusterRef = "TRUE";
			$dataCluster{$NameCluster}{"REF"}{"TSANAME"} = $HitTsaName ;
			$dataCluster{$NameCluster}{"REF"}{"LENGTH"} = $Hitlength ;
		}else{
# 			$ClusterRef = "FALSE" ; 
			$dataCluster{$NameCluster}{"ALT"}{$HitTsaName} = $Hitlength ; # carefull (multiple sequence per TSA... number of ALT entries doesn't correspond to the number of sequence per cluster !!! )
		}
# 		print "$HitTsaName  $Hitlength $ClusterRef \n";
		
		# Produce list if asked :
		if($list){
			if(defined $dataClusterListTSA{$HitTsaName}{$NameCluster} ){
				$dataClusterListTSA{$HitTsaName}{$NameCluster} = 1;
			} else {
				$dataClusterListTSA{$HitTsaName}{$NameCluster}++ ;
			}
			
		}
	}
}



# Eplore Cluster behavior
# =======================
# How many unique cluster per TSA
# How many sequence per TSA kept
# Which behavior per bin size ()
my %FinalNumberOfSequencesPerTSA ;
my %NumberOfSingleClusterPerTSA ;
my %FinalNumberOfSequencesPerTSABinSize ;
my %NumberOfSingleClusterPerTSABinSize ;

#Print number of sequence Per TSA AND initialize structure of result:
print "TsaName", "\t","NumberSequenceRaw", "\n" ;
foreach my $tsa (keys %InitialNumberOfSequencesPerTSA){
 	print $tsa, "\t", $InitialNumberOfSequencesPerTSA{$tsa}, "\n" ;
	$FinalNumberOfSequencesPerTSA{$tsa}=0 ;
	$NumberOfSingleClusterPerTSA{$tsa}=0 ;
	foreach my $bin (@limitBinSize){
		$FinalNumberOfSequencesPerTSABinSize{$tsa}{$bin}=0 ;
		$NumberOfSingleClusterPerTSABinSize{$tsa}{$bin}=0 ;
	}
	$FinalNumberOfSequencesPerTSABinSize{$tsa}{"bigger"}=0 ;
	$NumberOfSingleClusterPerTSABinSize{$tsa}{"bigger"}=0 ;
}

# compute metrics :
foreach my $c (keys %dataCluster){
	# we are at the cluster level
# 	print $dataCluster{$c}{"REF"}{"TSANAME"} ;
	$FinalNumberOfSequencesPerTSA{$dataCluster{$c}{"REF"}{"TSANAME"}}++ ;
	
	#determine size bin
	my $SizeBin = "FALSE" ; # because sup limit isn't in the bin size...
	foreach my $bin (@limitBinSize){
# 		print "$bin" ;
		unless($SizeBin =~ /FALSE/){next ;}
		if($dataCluster{$c}{"REF"}{"LENGTH"} < $bin){
			$SizeBin = $bin ;
		}
	}
	if($SizeBin =~/FALSE/){
		$SizeBin = "bigger" ;
	}
	$FinalNumberOfSequencesPerTSABinSize{$dataCluster{$c}{"REF"}{"TSANAME"}}{$SizeBin}++ ;
	
	#Test for Singleton
	unless( defined $dataCluster{$c}{"ALT"} ){ 
		$NumberOfSingleClusterPerTSA{$dataCluster{$c}{"REF"}{"TSANAME"}}++ ;
		$NumberOfSingleClusterPerTSABinSize{$dataCluster{$c}{"REF"}{"TSANAME"}}{$SizeBin}++ ;
	}
}

#Print metrics :
print "TsaName", "\t", "limitSupSizeBin", "\t" , "NumberSequenceClustered", "\t", "NumberSequenceSingleton", "\n";
foreach my $tsa (keys %InitialNumberOfSequencesPerTSA){
	foreach my $bin (@limitBinSize){
		print $tsa, "\t", $bin, "\t", $FinalNumberOfSequencesPerTSABinSize{$tsa}{$bin}, "\t", $NumberOfSingleClusterPerTSABinSize{$tsa}{$bin}, "\n" ;
	}
	
	print $tsa, "\t","bigger", "\t", $FinalNumberOfSequencesPerTSABinSize{$tsa}{"bigger"}, "\t", $NumberOfSingleClusterPerTSABinSize{$tsa}{"bigger"}, "\n" ;
}
# 
# foreach my $tsa (keys %InitialNumberOfSequencesPerTSA){
# 	print $tsa, "\t",$InitialNumberOfSequencesPerTSA{$tsa} , "\t" , $FinalNumberOfSequencesPerTSA{$tsa}, "\t", $NumberOfSingleClusterPerTSA{$tsa}, "\n" ;
# 	$FinalNumberOfSequencesPerTSA{$tsa}=0 ;
# }

#Print list :
if($list){
	print "LIST Cluster by TSA\n" ;
	foreach my $t (keys %dataClusterListTSA){
		my $outfile = "${cluster}${out}_list$t";
		open OUT, ">$outfile" or die "Unable to open $outfile !\n" ;
		foreach my $clust (keys %{$dataClusterListTSA{$t}}){
			print OUT $clust, "\n" ;
		}
		close OUT ;
	}
}
