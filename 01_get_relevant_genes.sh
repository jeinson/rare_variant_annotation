#!/bin/bash
# Finding relevant genes at a certain significance level

# PIPELINE: This is the first script in the pipeline

# PURPOSE: To take a list of coordinate-gene pairs with corresponding outlier significance scores, and generate a file containing the up and downstream coordinates of all genes which are significant in at least one individual

# USAGE: 01_get_relevant_genes.sh gene_coord_file.txt sig_level (a number between 0 and 1) > sig_gene_coords.txt

sig_level=$2
gene_file=$1
TSS=/gpfs/commons/datasets/controlled/GTEx/dbgap_restricted/data/gtex/exchange/GTEx_phs000424/exchange/analysis_releases/GTEx_Analysis_2015-01-12/eqtl_data/GTEx_Analysis_2015-01-12_eQTLInputFiles_genePositions.txt

awk -v sig="$sig_level" '$NF < sig {print $2}' $gene_file | sort | uniq | grep -f - $TSS | awk 'OFS = "\t" {print $1, $2, $3, $3 - 10000, $3 + 10000}' | sed 's/\.[[:digit:]]\+//g' 
