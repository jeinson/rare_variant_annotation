# -*- sh -*-
#!/bin/bash
#$ -cwd
#$ -V
#$ -o /commons/groups/lappalainen_lab/jeinson/logfiles
#$ -e /commons/groups/lappalainen_lab/jeinson/logfiles  
#$ -l h_rt=5:00:00
#$ -l h_vmem=4G
#$ -N CADD_anno_new

#PURPOSE: Take a list of coordinate intervals from upstream, get all of the SNVs within that interval from the v7 VCF file, 
# and select each variant's annotation from the big CADD annotation file, selecting the relevant annotations from that. 
# This script will give you most of the annotations needed for the RIVER algorithm to run, which determines which types of
# varaints are likely to cause a change of expression.

# NEW: This script also takes into account the specific gene that we're looking at, so you don't end up getting an annotation 
# for a different gene than the one in question. i.e. you won't get a variant annotated as a stop-gained variant for a different
# gene than the one of interest

#USAGE: bash CADD_annotation_pipeline_new.sh gene_intervals_tx.bed output_name
# Where the input file is the output of 01_get_relevant_genes.sh

# Load required modules
module load vcftools/0.1.14
module load htslib/1.7

# Specify the interval in tabix format
interval_fp=$1
keep_fp=$2
output=$3 # A prefix for the output filename

# Paths for files that stay on the cluster
VCF_FP=/gpfs/commons/datasets/controlled/GTEx/dbgap_restricted/data/gtex/exchange/GTEx_phs000424/exchange/analysis_releases/GTEx_Analysis_2016-01-15_v7/genotypes/WGS/variant_calls/GTEx_Analysis_2016-01-15_v7_WholeGenomeSeq_652Ind_GATK_HaplotypeCaller.vcf.gz
CADD_FP=/gpfs/commons/groups/lappalainen_lab/data/cadd/whole_genome_SNVs_inclAnno.tsv.gz

# The column numbers for featues we want (specified from Nature Genetics Paper supplemental material)
fields="1,2,3,5,6,7,11,72,40,43,49,48,50,42,45,47,51,52,42,44,54,46,53,64,69,79,80,81,61,62,67,63,68,66,71,58,65,70,56,59,57,116,15,14,39,32,34,31,33,22,23,24,19,20,21,26,25,91,93"

while read gene
do
	# Make sure the script doesn't break at the header line
	if [[ $gene == "Gene"* ]]
	then continue
	fi
	
	# Get the coordinates for each SNV in the interval, and the gene name
	gene_id=$(echo $gene | cut -f1 -d" ")
	chr=$(echo $gene | cut -f4 -d" ")
	start=$(echo $gene | awk '{print $5 - 10000}')
	end=$(echo $gene | cut -f2 -d" ")
		
	tabix -h $VCF_FP "$chr:$start-$end" |
	
	# Filter the VCF using the same method as before
	vcftools\
		--vcf -\
		--remove-indels\
		--max-maf 0.005\
		--keep $keep_fp\
		--recode \
		--stdout |
		
	# Select the first five columns, which have the information about the SNV's location (all that's important)
	# and rows which are simple SNVs (This was causing problems before)
	awk '{OFS=" "} length($4) == 1 && length($5) == 1 {print $1, $2, $3, $4, $5}' > tmp_vcf$output

	while read vcf_line
	do
		vcf_chr=$(echo $vcf_line | cut -f1 -d " ")
		vcf_pos=$(echo $vcf_line | cut -f2 -d " ")
		alt=$(echo $vcf_line | cut -f5 -d " ")
		
		# Select specific variants which are in the original file
		
		tabix $CADD_FP "$vcf_chr:$vcf_pos-$vcf_pos" | awk -v ALT="$alt" '$5 == ALT {print}' #| grep $gene_id - | cut -f$fields -s >> $output;
	done < tmp_vcf$output
		
done < $interval_fp

# Clean up after yourself!
#rm tmp_vcf$output
