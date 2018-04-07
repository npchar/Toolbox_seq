#!/bin/bash

# npcharrier

usage+="Usage: $0 <filename> \n"
usage+="\n"
usage+="Description : Count the number of reads\n"
usage+="Option :\t -c compressed fastq file (fastq.gz)\n"
usage+="        \t -l list context, <filename> is a file listing fastq\n"
List="no"
Gz="no"

while getopts ":lc" opt; do
  case $opt in
    l)
      echo "file provided is a list" >&2
      List="yes"
      ;;
    c)
      echo "gz compression context" >&2
      Gz="yes"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      printf "%b" "$usage" >&2
      exit
      ;;
  esac
done

# retire les options de la liste des arguments
shift $((OPTIND-1))
# test de l'argument obligatoire <name of>
if [ "$#" -eq 0 ];
then
        printf "%b" "$usage"
        exit
fi

args=("$@")


if [ "$List" = yes ];
then
	listFASTQ=($(cat ${args[0]}))
else
	listFASTQ=${args[0]}
fi


for i in ${listFASTQ[@]}
do
#	echo $i
        if [ "$Gz" = yes  ];
        then
		echo $i $( echo $( zcat $i | wc -l )/4 |bc )
        else
		echo $i $( $(cat $i|wc -l)/4|bc )
        fi

done

