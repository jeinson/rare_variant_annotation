# -*- sh -*-
#!/bin/bash
#$ -cwd
#$ -V
#$ -o /commons/groups/lappalainen_lab/jeinson/logfiles
#$ -e /commons/groups/lappalainen_lab/jeinson/logfiles  
#$ -l h_rt=3:00:00
#$ -l h_vmem=1G
#$ -N TX_VCF

#PURPOSE: Subset the huge GTEx v7 VCF file gene by gene to only include variants inside the gene body 

# USAGE: bash vcf_to_012_bed_rare_indel.sh *gene_intervals_tx.bed sample_to_keep.txt

# In the original paper, they look at SNPs and indels, but we'll have to save this for later. Right now, I just want to
# see that I can use the output for downstream analysis in R
# 6/6/2018

# ------------ User defined options -------------- #
interval_fp=$1 # the interval filepath, produced by the previous script
keep_fp=$2 # A list of sample names to keep, when recalculating minor allele frequencies
out=$3 # Output name, which will be a prefix for the 012 matrix files
MAF=$4

module load vcftools/0.1.14
module load htslib/1.7

VCF_FP=/gpfs/commons/datasets/controlled/GTEx/dbgap_restricted/data/gtex/exchange/GTEx_phs000424/exchange/analysis_releases/GTEx_Analysis_2016-01-15_v7/genotypes/WGS/variant_calls/GTEx_Analysis_2016-01-15_v7_WholeGenomeSeq_652Ind_GATK_HaplotypeCaller.vcf.gz

mkdir $out

# First subset the huge VCF file with just the regions we want using tabix
while read gene
do 
	# Make sure the script doesn't break at the header line
	if [[ $gene == "Gene"* ]]
	then continue
	fi

	gene_id=$(echo $gene | cut -f1 -d" ")
	chr=$(echo $gene | cut -f4 -d" ")
	start=$(echo $gene | awk '{print $5 - 10000}')
	end=$(echo $gene | cut -f2 -d" ")
	
	# Set a name for the individual gene 012 matrix
	outGene="$out/$gene_id"
	
	echo "$chr:$start-$end"
	
	# subset it from the big vcf
	tabix -h $VCF_FP "$chr:$start-$end"  |
	 
	# Keep only the individuals used in the SNV analysis, and recompute MAFs with just those individuals
	vcftools\
		--vcf -\
		--remove-indels\
		--keep $keep_fp\
		--recode\
		--recode-INFO AF\
		--stdout |
	
	# Then convert to 012 format with VCF tools
	vcftools\
		--vcf -\
		--max-maf $MAF\
		--out $outGene --012
	
	# Transpose the output to make it easier to read in R
	module load python/3.6.4
	
	input="$outGene.012"
	
	python -c "import sys; print('\n'.join(' '.join(c) for c in zip(*(l.split() for l in sys.stdin.readlines() if l.strip()))))" < $input > "$input.t"

	# clean up the useless file
	rm "$outGene.012"
	
done < $interval_fp