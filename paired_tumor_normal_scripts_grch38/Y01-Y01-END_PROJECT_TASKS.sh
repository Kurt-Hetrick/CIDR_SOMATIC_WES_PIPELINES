# ---qsub parameter settings---
# --these can be overrode at qsub invocation--

# tell sge to execute in bash
#$ -S /bin/bash

# tell sge that you are in the users current working directory
#$ -cwd

# tell sge to export the users environment variables
#$ -V

# tell sge to submit at this priority setting
#$ -p -10

# tell sge to output both stderr and stdout to the same file
#$ -j y

# export all variables, useful to find out what compute node the program was executed on

	set

	echo

# INPUT VARIABLES

	ALIGNMENT_CONTAINER=$1
	QC_REPORT=$2
		QC_REPORT_NAME=$(basename ${QC_REPORT} .csv)
	CORE_PATH=$3
	SEQ_PROJECT=$4
	ALLELE_FRACTION_CUTOFF=$5
	SUBMITTER_SCRIPT_PATH=$6
	SUBMITTER_ID=$7
	SUBMIT_STAMP=$8
	SEND_TO=$9

		TIMESTAMP=$(date '+%F.%H-%M-%S')

######################################################################
##### MAKE A QC REPORT FOR ALL SAMPLES GENERATED FOR THE PROJECT #####
######################################################################

	###################################################################################
	### CONCATENATE ALL THE INDIVIDUAL QC REPORTS FOR PROJECT AND ADDING THE HEADER ###
	###################################################################################

		cat ${CORE_PATH}/${SEQ_PROJECT}/REPORTS/QC_REPORT_PREP_PAIRED/*.PAIRED_QC_REPORT_PREP.txt \
			| sort -k 2,2 \
			| awk 'BEGIN {print "PROJECT",\
				"INDIVIDUAL",\
				"SM_TAG",\
				"SAMPLE_TYPE",\
				"RG_PU",\
				"LIBRARY",\
				"LIBRARY_PLATE",\
				"LIBRARY_WELL",\
				"LIBRARY_ROW",\
				"LIBRARY_COLUMN",\
				"HYB_PLATE",\
				"HYB_WELL",\
				"HYB_ROW",\
				"HYB_COLUMN",\
				"CRAM_PIPELINE_VERSION",\
				"SEQUENCING_PLATFORM",\
				"SEQUENCER_MODEL",\
				"EXEMPLAR_DATE",\
				"BAIT_BED_FILE",
				"TARGET_BED_FILE",\
				"TITV_BED_FILE",\
				"SOMATIC_TOTAL_SNPS_ON_BAIT",\
				"SOMATIC_NUM_IN_DB_SNP_ON_BAIT",\
				"SOMATIC_NOVEL_SNPS_ON_BAIT",\
				"SOMATIC_FILTERED_SNPS_ON_BAIT",\
				"SOMATIC_PCT_DBSNP_ON_BAIT",\
				"SOMATIC_TOTAL_INDELS_ON_BAIT",\
				"SOMATIC_NOVEL_INDELS_ON_BAIT",\
				"SOMATIC_FILTERED_INDELS_ON_BAIT",\
				"SOMATIC_PCT_DBSNP_INDELS_ON_BAIT",\
				"SOMATIC_NUM_IN_DB_SNP_INDELS_ON_BAIT",\
				"SOMATIC_TOTAL_MULTIALLELIC_SNPS_ON_BAIT",\
				"SOMATIC_NUM_IN_DB_SNP_MULTIALLELIC_ON_BAIT",\
				"SOMATIC_TOTAL_COMPLEX_INDELS_ON_BAIT",\
				"SOMATIC_NUM_IN_DB_SNP_COMPLEX_INDELS_ON_BAIT",\
				"SOMATIC_SNP_REFERENCE_BIAS_ON_BAIT",\
				"SOMATIC_TOTAL_SNPS_ON_TARGET",\
				"SOMATIC_NUM_IN_DB_SNP_ON_TARGET",\
				"SOMATIC_NOVEL_SNPS_ON_TARGET",\
				"SOMATIC_FILTERED_SNPS_ON_TARGET",\
				"SOMATIC_PCT_DBSNP_ON_TARGET",\
				"SOMATIC_TOTAL_INDELS_ON_TARGET",\
				"SOMATIC_NOVEL_INDELS_ON_TARGET",\
				"SOMATIC_FILTERED_INDELS_ON_TARGET",\
				"SOMATIC_PCT_DBSNP_INDELS_ON_TARGET",\
				"SOMATIC_NUM_IN_DB_SNP_INDELS_ON_TARGET",\
				"SOMATIC_TOTAL_MULTIALLELIC_SNPS_ON_TARGET",\
				"SOMATIC_NUM_IN_DB_SNP_MULTIALLELIC_ON_TARGET",\
				"SOMATIC_TOTAL_COMPLEX_INDELS_ON_TARGET",\
				"SOMATIC_NUM_IN_DB_SNP_COMPLEX_INDELS_ON_TARGET",\
				"SOMATIC_SNP_REFERENCE_BIAS_ON_TARGET",\
				"PAIRED_SNV_HET_SENSITIVITY",\
				"PAIRED_SNV_HET_PPV",\
				"PAIRED_SNV_HOMVAR_SENSITIVITY",\
				"PAIRED_SNV_HOMVAR_PPV",\
				"PAIRED_SNV_VAR_SENSITIVITY",\
				"PAIRED_SNV_VAR_PPV",\
				"PAIRED_SNV_VAR_SPECIFICITY",\
				"PAIRED_SNV_GENOTYPE_CONCORDANCE",\
				"PAIRED_SNV_NON_REF_GENOTYPE_CONCORDANCE",\
				"PAIRED_SNV_TP_COUNT",\
				"PAIRED_SNV_TN_COUNT",\
				"PAIRED_SNV_FP_COUNT",\
				"PAIRED_SNV_FN_COUNT",\
				"PAIRED_SNV_EMPTY_COUNT",\
				"PAIRED_INDEL_HET_SENSITIVITY",\
				"PAIRED_INDEL_HET_PPV",\
				"PAIRED_INDEL_HOMVAR_SENSITIVITY",\
				"PAIRED_INDEL_HOMVAR_PPV",\
				"PAIRED_INDEL_VAR_SENSITIVITY",\
				"PAIRED_INDEL_VAR_PPV",\
				"PAIRED_INDEL_VAR_SPECIFICITY",\
				"PAIRED_INDEL_GENOTYPE_CONCORDANCE",\
				"PAIRED_INDEL_NON_REF_GENOTYPE_CONCORDANCE",\
				"PAIRED_INDEL_TP_COUNT",\
				"PAIRED_INDEL_TN_COUNT",\
				"PAIRED_INDEL_FP_COUNT",\
				"PAIRED_INDEL_FN_COUNT",\
				"PAIRED_INDEL_EMPTY_COUNT",\
				"X_AVG_DP",\
				"X_NORM_DP",\
				"Y_AVG_DP",\
				"Y_NORM_DP",\
				"COUNT_DISC_HOM",\
				"COUNT_CONC_HOM",\
				"PERCENT_CONC_HOM",\
				"COUNT_DISC_HET",\
				"COUNT_CONC_HET",\
				"PERCENT_CONC_HET",\
				"PERCENT_TOTAL_CONC",\
				"COUNT_HET_BEADCHIP",\
				"SENSITIVITY_2_HET",\
				"SNP_ARRAY",\
				"VERIFYBAM_FREEMIX_PCT",\
				"VERIFYBAM_#SNPS",\
				"VERIFYBAM_FREELK1",\
				"VERIFYBAM_FREELK0",\
				"VERIFYBAM_DIFF_LK0_LK1",\
				"VERIFYBAM_AVG_DP",\
				"GATK_TUMOR_CONTAM_PCT",\
				"GATK_TUMOR_CONTAM_ERR",\
				"MEDIAN_INSERT_SIZE",\
				"MEAN_INSERT_SIZE",\
				"STANDARD_DEVIATION_INSERT_SIZE",\
				"MAD_INSERT_SIZE",\
				"PCT_PF_READS_ALIGNED_R1",\
				"PF_HQ_ALIGNED_READS_R1",\
				"PF_HQ_ALIGNED_Q20_BASES_R1",\
				"PF_MISMATCH_RATE_R1",\
				"PF_HQ_ERROR_RATE_R1",\
				"PF_INDEL_RATE_R1",\
				"PCT_READS_ALIGNED_IN_PAIRS_R1",\
				"PCT_ADAPTER_R1",\
				"PCT_PF_READS_ALIGNED_R2",\
				"PF_HQ_ALIGNED_READS_R2",\
				"PF_HQ_ALIGNED_Q20_BASES_R2",\
				"PF_MISMATCH_RATE_R2",\
				"PF_HQ_ERROR_RATE_R2",\
				"PF_INDEL_RATE_R2",\
				"PCT_READS_ALIGNED_IN_PAIRS_R2",\
				"PCT_ADAPTER_R2",\
				"TOTAL_READS",\
				"RAW_GIGS",\
				"PCT_PF_READS_ALIGNED_PAIR",\
				"PF_MISMATCH_RATE_PAIR",\
				"PF_HQ_ERROR_RATE_PAIR",\
				"PF_INDEL_RATE_PAIR",\
				"PCT_READS_ALIGNED_IN_PAIRS_PAIR",\
				"STRAND_BALANCE_PAIR",\
				"PCT_CHIMERAS_PAIR",\
				"PF_HQ_ALIGNED_Q20_BASES_PAIR",\
				"MEAN_READ_LENGTH",\
				"PCT_PF_READS_IMPROPER_PAIRS_PAIR",\
				"UNMAPPED_READS",\
				"READ_PAIR_OPTICAL_DUPLICATES",\
				"PERCENT_DUPLICATION",\
				"ESTIMATED_LIBRARY_SIZE",\
				"SECONDARY_OR_SUPPLEMENTARY_READS",\
				"READ_PAIR_DUPLICATES",\
				"READ_PAIRS_EXAMINED",\
				"PAIRED_DUP_RATE",\
				"UNPAIRED_READ_DUPLICATES",\
				"UNPAIRED_READS_EXAMINED",\
				"UNPAIRED_DUP_RATE",\
				"PERCENT_DUPLICATION_OPTICAL",\
				"MEAN_UMI_LENGTH",\
				"OBSERVED_UNIQUE_UMIS",\
				"INFERRED_UNIQUE_UMIS",\
				"OBSERVED_BASE_ERRORS",\
				"DUPLICATE_SETS_IGNORING_UMI",\
				"DUPLICATE_SETS_WITH_UMI",\
				"OBSERVED_UMI_ENTROPY",\
				"INFERRED_UMI_ENTROPY",\
				"UMI_BASE_QUALITIES",\
				"PCT_UMI_WITH_N",\
				"GENOME_SIZE",\
				"BAIT_TERRITORY",\
				"TARGET_TERRITORY",\
				"PCT_PF_UQ_READS_ALIGNED",\
				"PF_UQ_GIGS_ALIGNED",\
				"PCT_SELECTED_BASES",\
				"ON_BAIT_VS_SELECTED",\
				"MEAN_TARGET_COVERAGE",\
				"MEDIAN_TARGET_COVERAGE",\
				"MAX_TARGET_COVERAGE",\
				"ZERO_CVG_TARGETS_PCT",\
				"PCT_EXC_MAPQ",\
				"PCT_EXC_BASEQ",\
				"PCT_EXC_OVERLAP",\
				"PCT_EXC_OFF_TARGET",\
				"PCT_EXC_ADAPTER",\
				"FOLD_80_BASE_PENALTY",\
				"PCT_TARGET_BASES_1X",\
				"PCT_TARGET_BASES_2X",\
				"PCT_TARGET_BASES_10X",\
				"PCT_TARGET_BASES_20X",\
				"PCT_TARGET_BASES_30X",\
				"PCT_TARGET_BASES_40X",\
				"PCT_TARGET_BASES_50X",\
				"PCT_TARGET_BASES_100X",\
				"HS_LIBRARY_SIZE",\
				"AT_DROPOUT",\
				"GC_DROPOUT",\
				"THEORETICAL_HET_SENSITIVITY",\
				"HET_SNP_Q",\
				"BAIT_SET",\
				"PCT_USABLE_BASES_ON_BAIT",\
				"Cref_Q",\
				"Gref_Q",\
				"DEAMINATION_Q",\
				"OxoG_Q",\
				"PCT_A",\
				"PCT_C",\
				"PCT_G",\
				"PCT_T",\
				"PCT_N",\
				"PCT_A_to_C",\
				"PCT_A_to_G",\
				"PCT_A_to_T",\
				"PCT_C_to_A",\
				"PCT_C_to_G",\
				"PCT_C_to_T",\
				"BAIT_HET_HOMVAR_RATIO",\
				"BAIT_PCT_GQ0_VARIANT",\
				"BAIT_TOTAL_GQ0_VARIANT",\
				"BAIT_TOTAL_HET_DEPTH_SNV",\
				"BAIT_TOTAL_SNV",\
				"BAIT_NUM_IN_DBSNP_138_SNV",\
				"BAIT_NOVEL_SNV",\
				"BAIT_FILTERED_SNV",\
				"BAIT_PCT_DBSNP_138_SNV",\
				"BAIT_TOTAL_INDEL",\
				"BAIT_NOVEL_INDEL",\
				"BAIT_FILTERED_INDEL",\
				"BAIT_PCT_DBSNP_138_INDEL",\
				"BAIT_NUM_IN_DBSNP_138_INDEL",\
				"BAIT_DBSNP_138_INS_DEL_RATIO",\
				"BAIT_NOVEL_INS_DEL_RATIO",\
				"BAIT_TOTAL_MULTIALLELIC_SNV",\
				"BAIT_NUM_IN_DBSNP_138_MULTIALLELIC_SNV",\
				"BAIT_TOTAL_COMPLEX_INDEL",\
				"BAIT_NUM_IN_DBSNP_138_COMPLEX_INDEL",\
				"BAIT_SNP_REFERENCE_BIAS",\
				"BAIT_NUM_SINGLETONS",\
				"TARGET_HET_HOMVAR_RATIO",\
				"TARGET_PCT_GQ0_VARIANT",\
				"TARGET_TOTAL_GQ0_VARIANT",\
				"TARGET_TOTAL_HET_DEPTH_SNV",\
				"TARGET_TOTAL_SNV",\
				"TARGET_NUM_IN_DBSNP_138_SNV",\
				"TARGET_NOVEL_SNV",\
				"TARGET_FILTERED_SNV",\
				"TARGET_PCT_DBSNP_138_SNV",\
				"TARGET_TOTAL_INDEL",\
				"TARGET_NOVEL_INDEL",\
				"TARGET_FILTERED_INDEL",\
				"TARGET_PCT_DBSNP_138_INDEL",\
				"TARGET_NUM_IN_DBSNP_138_INDEL",\
				"TARGET_DBSNP_138_INS_DEL_RATIO",\
				"TARGET_NOVEL_INS_DEL_RATIO",\
				"TARGET_TOTAL_MULTIALLELIC_SNV",\
				"TARGET_NUM_IN_DBSNP_138_MULTIALLELIC_SNV",\
				"TARGET_TOTAL_COMPLEX_INDEL",\
				"TARGET_NUM_IN_DBSNP_138_COMPLEX_INDEL",\
				"TARGET_SNP_REFERENCE_BIAS",\
				"TARGET_NUM_SINGLETONS",\
				"CODING_HET_HOMVAR_RATIO",\
				"CODING_PCT_GQ0_VARIANT",\
				"CODING_TOTAL_GQ0_VARIANT",\
				"CODING_TOTAL_HET_DEPTH_SNV",\
				"CODING_TOTAL_SNV",\
				"CODING_NUM_IN_DBSNP_129_SNV",\
				"CODING_NOVEL_SNV",\
				"CODING_FILTERED_SNV",\
				"CODING_PCT_DBSNP_129_SNV",\
				"CODING_DBSNP_129_TITV",\
				"CODING_NOVEL_TITV",\
				"CODING_TOTAL_INDEL",\
				"CODING_NOVEL_INDEL",\
				"CODING_FILTERED_INDEL",\
				"CODING_PCT_DBSNP_129_INDEL",\
				"CODING_NUM_IN_DBSNP_129_INDEL",\
				"CODING_DBSNP_129_INS_DEL_RATIO",\
				"CODING_NOVEL_INS_DEL_RATIO",\
				"CODING_TOTAL_MULTIALLELIC_SNV",\
				"CODING_NUM_IN_DBSNP_129_MULTIALLELIC_SNV",\
				"CODING_TOTAL_COMPLEX_INDEL",\
				"CODING_NUM_IN_DBSNP_129_COMPLEX_INDEL",\
				"CODING_SNP_REFERENCE_BIAS",\
				"CODING_NUM_SINGLETONS"} \
				{print $0}' \
			| sed 's/ /,/g' \
			| sed 's/\t/,/g' \
		>| ${CORE_PATH}/${SEQ_PROJECT}/REPORTS/QC_REPORTS/${SEQ_PROJECT}.PAIRED_QC_REPORT.${TIMESTAMP}.csv

	#####################################################################################################
	### ADD LAB PREP METRICS TO SEQUENCING METRICS ######################################################
	#####################################################################################################
	### Take all of the lab prep metrics and meta data reports generated to date ########################
	##### grab the header ###############################################################################
	##### cat all of the records (removing the header) ##################################################
	##### sort on the sm_tag and reverse numerical sort on epoch time (newest time comes first) #########
	##### when sm_tag is duplicated take the first record (the last time that sample was generated) #####
	##### join with the newest all project qc report on sm_tag ##########################################
	#####################################################################################################

	# FOR NOW NOT DOING THIS

		# (cat  ${CORE_PATH}/${SEQ_PROJECT}/REPORTS/LAB_PREP_REPORTS/*LAB_PREP_METRICS.csv \
		# 	| head -n 1 ; \
		# cat ${CORE_PATH}/${SEQ_PROJECT}/REPORTS/LAB_PREP_REPORTS/*LAB_PREP_METRICS.csv \
		# 	| grep -v "^SM_TAG" \
		# 	| sort \
		# 		-t',' \
		# 		-k 1,1 \
		# 		-k 40,40nr) \
		# | awk 'BEGIN {FS=",";OFS=","} \
		# 	!x[$1]++ \
		# 	{print $0}' \
		# | join \
		# 	-t , \
		# 	-1 2 \
		# 	-2 1 \
		# 	${CORE_PATH}/${SEQ_PROJECT}/TEMP/${SEQ_PROJECT}.QC_REPORT.${TIMESTAMP}.TEMP.csv \
		# 	/dev/stdin \
		# >| ${CORE_PATH}/${SEQ_PROJECT}/REPORTS/QC_REPORTS/${SEQ_PROJECT}.QC_REPORT.${TIMESTAMP}.csv

###########################################################################
##### MAKE A QC REPORT FOR JUST THE SAMPLES IN THE BATCH PER PROJECT  #####
###########################################################################

	##########################################################
	##### GRAB COLUMN POSITIONS FOR HEADERS IN QC REPORT #####
	##########################################################

		INDIVIDUAL_ID_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="Individual_ID") print i}}' ${QC_REPORT})

		NORMAL_SM_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="Normal_SM") print i}}' ${QC_REPORT})

		TUMOR_SM_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="Tumor_SM") print i}}' ${QC_REPORT})

		NORMAL_PROJECT_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="Normal_Project") print i}}' ${QC_REPORT})

		TUMOR_PROJECT_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="Tumor_Project") print i}}' ${QC_REPORT})

		BAIT_BED_FILE_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="BAIT_BED_FILE") print i}}' ${QC_REPORT})

		TARGET_BED_FILE_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="TARGET_BED_FILE") print i}}' ${QC_REPORT})

		NORMAL_DNA_SOURCE_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="Normal_DNA_source") print i}}' ${QC_REPORT})

		TUMOR_DNA_SOURCE_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="Tumor_DNA_source") print i}}' ${QC_REPORT})

	###############################################################################
	### CONCATENATE INDIVIDUAL QC REPORTS FOR JUST THE SAMPLES IN THE QC REPORT ###
	###############################################################################

		# Create the headers for the new files using the header from the all project samples QC report

			head -n 1 ${CORE_PATH}/${SEQ_PROJECT}/REPORTS/QC_REPORTS/${SEQ_PROJECT}.PAIRED_QC_REPORT.${TIMESTAMP}.csv \
			>| ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}/${QC_REPORT_NAME}.QC_REPORT.csv
			
		# for all tumor samples in the sample sheet extract those samples from the all project samples QC report

			for TUMOR_SM_TAG in $(awk 1 ${QC_REPORT} \
				| awk \
					-v TUMOR_SM_COLUMN_POSITION="$TUMOR_SM_COLUMN_POSITION" \
					'BEGIN {FS=","} \
					NR>1 \
					{print $TUMOR_SM_COLUMN_POSITION}' \
				| sort \
				| uniq);
			do
				awk 'BEGIN {FS=",";OFS=","} \
					$3=="'${TUMOR_SM_TAG}'" \
					{print $0}' \
				${CORE_PATH}/${SEQ_PROJECT}/REPORTS/QC_REPORTS/${SEQ_PROJECT}.PAIRED_QC_REPORT.${TIMESTAMP}.csv \
				>> ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}/${QC_REPORT_NAME}.QC_REPORT.csv
			done

		# for all tumor samples in the sample sheet extract those samples from the all project samples QC report

			for NORMAL_SM_TAG in $(awk 1 ${QC_REPORT} \
				| awk \
					-v NORMAL_SM_COLUMN_POSITION="$NORMAL_SM_COLUMN_POSITION" \
					'BEGIN {FS=","} \
					NR>1 \
					{print $NORMAL_SM_COLUMN_POSITION}' \
				| sort \
				| uniq);
			do
				awk 'BEGIN {FS=",";OFS=","} \
					$3=="'${NORMAL_SM_TAG}'" \
					{print $0}' \
				${CORE_PATH}/${SEQ_PROJECT}/REPORTS/QC_REPORTS/${SEQ_PROJECT}.PAIRED_QC_REPORT.${TIMESTAMP}.csv \
				>> ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}/${QC_REPORT_NAME}.QC_REPORT.csv
			done

		# sort and unique in case there are duplicate normal rows

			(head -n 1 ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}/${QC_REPORT_NAME}.QC_REPORT.csv ; \
			awk 'NR>1' ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}/${QC_REPORT_NAME}.QC_REPORT.csv \
				| sort \
				| uniq) \
			>| ${CORE_PATH}/${SEQ_PROJECT}/REPORTS/QC_REPORTS/${QC_REPORT_NAME}.PAIRED_QC_REPORT.csv

	########################################################################################
	### JOIN SEQUENCING METRICS BATCH REPORT WITH LAB QC PREP METRICS AT THE BATCH LEVEL ###
	########################################################################################

	# FOR NOW NOT DOING THIS

		# (head -n 1 ${CORE_PATH}/${SEQ_PROJECT}/REPORTS/LAB_PREP_REPORTS/${SAMPLE_SHEET_NAME}.LAB_PREP_METRICS.csv ; \
		# awk 'NR>1' ${CORE_PATH}/${SEQ_PROJECT}/REPORTS/LAB_PREP_REPORTS/${SAMPLE_SHEET_NAME}.LAB_PREP_METRICS.csv \
		# 	| sort -t',' -k 1,1 ) \
		# 		| join -t , -1 2 -2 1 \
		# 			${CORE_PATH}/${SEQ_PROJECT}/TEMP/${SAMPLE_SHEET_NAME}.QC_REPORT.csv \
		# 			/dev/stdin \
		# >| ${CORE_PATH}/${SEQ_PROJECT}/REPORTS/QC_REPORTS/${SAMPLE_SHEET_NAME}.QC_REPORT.csv

##############################################################
##### SEND EMAIL NOTIFICATION SUMMARIES WHEN DONE ############
##### CLEAN-UP OR NOT DEPENDING ON IF JOBS FAILED OR NOT #####
##############################################################

	# grab submitter's name

		PERSON_NAME=$(getent passwd \
			| awk 'BEGIN {FS=":"} \
				$1=="'${SUBMITTER_ID}'" \
				{print $5}')

	# IF THERE ARE NO FAILED JOBS SEND EMAIL NOTIFICATION AND THEN DELETE TEMP FILES FOR THIS BATCH
	if
		[[ ! -f ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_ERRORS.txt ]]
	then
		printf "THIS RUN COMPLETED SUCCESSFULLY WITH NO ERRORS.\n \
		SO THE TEMP FILES HAVE BEEN DELETED FOR THIS BATCH.\n \
		${PERSON_NAME} Was The Submitter\n \
		ALLELE FRACTION CUTOFF IS:\n ${ALLELE_FRACTION_CUTOFF}\n\n \
		REPORTS ARE AT:\n ${CORE_PATH}/${SEQ_PROJECT}/REPORTS/QC_REPORTS\n\n \
		BATCH QC REPORT:\n ${QC_REPORT_NAME}.PAIRED_QC_REPORT.csv\n\n \
		FULL PROJECT QC REPORT:\n ${SEQ_PROJECT}.PAIRED_QC_REPORT.${TIMESTAMP}.csv\n" \
		| mail -s "NO ERRORS: ${QC_REPORT} FOR ${SEQ_PROJECT} has finished processing CIDR_NGS_CAPTURE_PAIRED_TUMOR_NORMAL_SUBMITTER_GRCH38.sh" \
			${SEND_TO}
		# delete temp files
			echo rm -rf ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}/
			rm -rf ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}/
	else # message when there are no samples with multiple libraries or total failures
		printf "SO BAD THINGS HAPPENED AND THE TEMP FILES WILL NOT BE DELETED FOR BATCH.\n \
		${PERSON_NAME} Was The Submitter\n \
		ALLELE FRACTION CUTOFF IS:\n ${ALLELE_FRACTION_CUTOFF}\n\n \
		REPORTS ARE AT:\n ${CORE_PATH}/${SEQ_PROJECT}/REPORTS/QC_REPORTS\n\n \
		BATCH QC REPORT:\n ${QC_REPORT_NAME}.PAIRED_QC_REPORT.csv\n\n \
		FULL PROJECT QC REPORT:\n ${SEQ_PROJECT}.PAIRED_QC_REPORT.${TIMESTAMP}.csv\n" \
		>| ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

		printf "###################################################################\n" \
			>> ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

		printf "SOMEWHAT FULL LISTING OF FAILED JOBS ARE HERE:\n" \
			>> ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

		printf "${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_ERRORS.txt\n" \
			>> ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

		printf "###################################################################\n" \
			>> ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

		printf "BELOW ARE THE SAMPLES AND THE MINIMUM NUMBER OF JOBS THAT FAILED PER SAMPLE:\n" \
			>> ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

		printf "###################################################################\n" \
			>> ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			awk 'BEGIN {OFS="\t"} \
				NF==6 \
				{print $1}' \
			${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_ERRORS.txt\
				| sort \
				| singularity exec ${ALIGNMENT_CONTAINER} datamash \
					-g 1 \
					count 1 \
			>> ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

		printf "###################################################################\n" \
			>> ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

		printf "FOR THE SAMPLES THAT HAVE FAILED JOBS, THIS IS ROUGHLY THE FIRST JOB THAT FAILED FOR EACH SAMPLE:\n" \
			>> ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

		printf "###################################################################\n" \
			>> ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

		printf "SM_TAG NODE JOB_NAME USER EXIT LOG_FILE\n" \
			| sed 's/ /\t/g' \
		>> ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

		for sample in $(awk 'BEGIN {OFS="\t"} \
					NF==6 \
					{print $1}' \
				${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_ERRORS.txt
				| sort \
				| uniq);
		do
			awk '$1=="'${sample}'" \
				{print $0 "\n" "\n"}' \
			${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
				| head -n 1 \
			>> ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt
		done

		sleep 2s

		mail -s "FAILED JOBS: ${QC_REPORT_NAME} FOR ${SEQ_PROJECT} has finished processing CIDR_SOMATIC_CAPTURE_SUBMITTER_GRCH38.sh" \
			${SEND_TO} \
		< ${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt
	fi

	sleep 2s

####################################################
##### Clean up the Wall Clock minutes tracker. #####
####################################################

	# # clean up records that are malformed
	# # only keep jobs that ran longer than 3 minutes

	# 	awk 'BEGIN {FS=",";OFS=","} \
	# 		$1~/^[A-Z 0-9]/&&$2!=""&&$3!=""&&$4!=""&&$5!=""&&$6!=""&&$7==""&&$5!~/A-Z/&&$6!~/A-Z/&&($6-$5)>180 \
	# 		{print $1,"'${SEQ_PROJECT}'",$2,$3,$4,$5,$6,($6-$5)/60,\
	# 			strftime("%F",$5),strftime("%F",$6),strftime("%F.%H-%M-%S",$5),strftime("%F.%H-%M-%S",$6)}' \
	# 	${CORE_PATH}/${SEQ_PROJECT}/REPORTS/${SEQ_PROJECT}.WALL.CLOCK.TIMES.csv \
	# 		| sed 's/_'"${SEQ_PROJECT}"'/,'"${SEQ_PROJECT}"'/g' \
	# 		| awk 'BEGIN {print "SAMPLE,PROJECT,TASK_GROUP,TASK,HOST,EPOCH_START,EPOCH_END,\
	# 				WC_MIN,START_DATE,END_DATE,TIMESTAMP_START,TIMESTAMP_END"} \
	# 			{print $0}' \
	# 	>| ${CORE_PATH}/${SEQ_PROJECT}/REPORTS/${SEQ_PROJECT}.WALL.CLOCK.TIMES.FIXED.csv

#############################################################
##### Summarize Wall Clock times ############################
#############################################################

	# # summarize by sample by taking the max times per concurrent task group and summing them up

	# 	sed 's/,/\t/g' ${CORE_PATH}/${SEQ_PROJECT}/REPORTS/${SEQ_PROJECT}.WALL.CLOCK.TIMES.FIXED.csv \
	# 		| awk 'NR>1' \
	# 		| sed 's/_BAM_REPORTS//g' \
	# 		| sort -k 1,1 -k 2,2 -k 3,3 -k 4,4 \
	# 		| awk 'BEGIN {OFS="\t"} {print $0,($7-$6),($7-$6)/60,($7-$6)/3600}' \
	# 		| singularity exec ${ALIGNMENT_CONTAINER} datamash \
	# 			-s \
	# 			-g 1,2,3 \
	# 			max 13 \
	# 			max 14 \
	# 			max 15 \
	# 		| tee ${CORE_PATH}/${SEQ_PROJECT}/TEMP/WALL.CLOCK.TIMES.BY.GROUP.txt \
	# 		| singularity exec ${ALIGNMENT_CONTAINER} datamash \
	# 			-g 1,2 \
	# 			sum 4 \
	# 			sum 5 \
	# 			sum 6 \
	# 		| awk 'BEGIN \
	# 			{print "SAMPLE","PROJECT","WALL_CLOCK_SECONDS","WALL_CLOCK_MINUTES","WALL_CLOCK_HOURS"} \
	# 			{print $0}' \
	# 		| sed -r 's/[[:space:]]+/,/g' \
	# 	>| ${CORE_PATH}/${SEQ_PROJECT}/REPORTS/${SEQ_PROJECT}.WALL.CLOCK.TIMES.BY_SAMPLE.csv

	# # break down by the longest task within a group per sample

	# 	sed 's/\t/,/g' ${CORE_PATH}/${SEQ_PROJECT}/TEMP/WALL.CLOCK.TIMES.BY.GROUP.txt \
	# 		| awk 'BEGIN {print "SAMPLE","PROJECT","TASK_GROUP","WALL_CLOCK_SECONDS","WALL_CLOCK_MINUTES","WALL_CLOCK_HOURS"} {print $0}' \
	# 		| sed -r 's/[[:space:]]+/,/g' \
	# 	>| ${CORE_PATH}/${SEQ_PROJECT}/REPORTS/${SEQ_PROJECT}.WALL.CLOCK.TIMES.BY_SAMPLE_GROUP.csv
