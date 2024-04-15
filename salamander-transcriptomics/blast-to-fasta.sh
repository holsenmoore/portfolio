#!/bin/bash

# BLAST to FASTA
# version 1.0

# Performs BLAST searches of genes of interest and makes FASTA files of
# resulting transcripts.

# Salamander Transcriptomics, Biodiversity Discovery, FRI
# The University of Texas at Austin
# By Holsen B. Moore
# Last Updated: 2024-04-14

# GLOBAL VARIABLES:

species=() # Empty species array
wd="/stor/work/Hillis" # Working directory
dirs=$(ls ${wd}) # Working directory contents
goi_files=$(ls ${wd}/goi_homo_sequences) # Candidate homo sequence files

# CODE:

# If GOI  scripts directory doesn't exist, make it.
if [ ! -d ${wd}/goi_scripts ]
then
	mkdir ${wd}/goi_scripts
fi

# Iterates over every directory in the working directory. Finds species
# directories with existing BLAST databases and writes them to memory.
for i in ${dirs}
do
	# If the directory includes a species.nhr file,	i.e., if it is a species
	# directory and it has a BLAST database.
	if [ -f ${wd}/${i}/blast/${i}.nhr ]
	then
		# Appends this directory name to species array.
		species+="${i} "
	fi
done

# Iterates over every file in  homo sequences directory.
# Writes GOI gene name to memory.
for i in ${goi_files}
do
	# Writes GOI gene name to memory.
	# Requires specific format: species_gene-name.fasta
	goi=$(ls ${wd}/goi_homo_sequences/${i} | awk -F'_' '{print $4}' | awk -F'.' '{print $1}')

	# Makes directory for gene of interest outputs if one does not already exist.
	if [ ! -d ${wd}/goi_scripts/${goi} ]
	then
		mkdir ${wd}/goi_scripts/${goi}	
	fi 

	# Iterates over every species.
	for j in ${species}
	do
		# Variables of relevant paths.
		# Makes actual command shorter and easier for humans to parse.
		query="${wd}/goi_homo_sequences/${i}"
		database="${wd}/${j}/blast/${j}"
		outfile="${wd}/${j}/blast/${j}-${goi}-BLAST_output.txt"

		# If output file already exists, then move on to the next
		# iteration. This means there will be no annoying errors.
		if [ -f ${outfile} ]
		then
			continue
		fi

		# Conducts BLAST search for GOI.
		tblastn -query ${query} -db ${database} -out ${outfile} -outfmt 6 -evalue 1e-20

		# Displays a nice completion message.
		printf "BLAST search for $goi completed for $j\n"
	done
done

# Waits for background processes (i.e., BLAST searches) to finish before moving
# on. This is important because the following steps rely on finished BLAST
# searches.
wait

# Iterates over every species.
for i in ${species}
do
	# Path variables for ease of coding and human readability.
	species_dir="${wd}/${i}"
	output_files=$(ls ${species_dir}/blast/*BLAST_output.txt)

	# Iterates over every BLAST output file.
	for j in ${output_files}
	do
		# Grabs gene name from BLAST output file name and writes it to
		# memory.
		gene=$(printf "$j" | awk -F'-' '{print $2}')

		# Path variables for ease of coding and human readability.
		database="${species_dir}/blast/${i}"
		entry=$(head -n 1 ${j} | awk -F'\t' '{print $2}')
		outfile="${wd}/goi_scripts/${gene}/${i}_${gene}.fasta"

		# If BLAST output file is empty or if the FASTA output already
		# exists, move to the next iteration without doing anything.
		# This means no annoying errors will be produced.
		if [ -f ${outfile} ] 
		then
			continue
		elif [ ! -s ${j} ]
		then
			continue
		fi

		# Creates FASTA file from top BLAST output.
		blastdbcmd -db ${database} -entry ${entry} -out ${outfile}
	done	
done

# Waits for background processes to finish and displays a nice message.
wait
printf "\nBLAST to FASTA complete! hehe :)\n"