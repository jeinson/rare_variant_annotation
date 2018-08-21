# rare_variant_annotatio

These scripts are used to query all rare variant annotations near a set of genes specified in the input. 

1. `01_get_relevant_genes.sh` Takes a list individual gene pairs with significance scores, and outputs a list of all genes which are significant (p < .05) in at least one individual. 
2. `02_vcf_to_012_rare_snvs.sh` uses the output of the last script to query a big VCF file and return all rare (MAF < .01) variants which are in between 10kb upstream of the gene's TSS, and within the gene body. It outputs these variants in the simple 012 format. (https://vcftools.github.io/man_latest.html#OUTPUT OPTIONS) 
3. `03_CADD_annotation_pipeline.sh` uses the output of 1 as well to get all of the annotations for the the variants recorded in step 2. 

The output of all three of these scripts are combined in R to make an input file used for RIVER.  
