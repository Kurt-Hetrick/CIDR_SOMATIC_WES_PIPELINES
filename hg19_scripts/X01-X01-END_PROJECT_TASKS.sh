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

	CORE_PATH=$1
	ALIGNMENT_CONTAINER=$2

	PROJECT=$3
	SAMPLE_SHEET=$4
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMITTER_SCRIPT_PATH=$5
	SUBMITTER_ID=$6
	SUBMIT_STAMP=$7

		TIMESTAMP=$(date '+%F.%H-%M-%S')

######################################################################
##### MAKE A QC REPORT FOR ALL SAMPLES GENERATED FOR THE PROJECT #####
######################################################################

	###################################################################################
	### CONCATENATE ALL THE INDIVIDUAL QC REPORTS FOR PROJECT AND ADDING THE HEADER ###
	###################################################################################

		cat ${CORE_PATH}/${PROJECT}/REPORTS/QC_REPORT_PREP/*.QC_REPORT_PREP.txt \
			| sort -k 2,2 \
			| awk 'BEGIN {print "PROJECT",\
				"SM_TAG",\
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
		>| ${CORE_PATH}/${PROJECT}/TEMP/${PROJECT}.QC_REPORT.${TIMESTAMP}.TEMP.csv

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

		(cat  ${CORE_PATH}/${PROJECT}/REPORTS/LAB_PREP_REPORTS/*LAB_PREP_METRICS.csv \
			| head -n 1 ; \
		cat ${CORE_PATH}/${PROJECT}/REPORTS/LAB_PREP_REPORTS/*LAB_PREP_METRICS.csv \
			| grep -v "^SM_TAG" \
			| sort \
				-t',' \
				-k 1,1 \
				-k 61,61n) \
		| awk 'BEGIN {FS=",";OFS=","} \
			!x[$1]++ \
			{print $0}' \
		| join \
			-t , \
			-1 2 \
			-2 1 \
			${CORE_PATH}/${PROJECT}/TEMP/${PROJECT}.QC_REPORT.${TIMESTAMP}.TEMP.csv \
			/dev/stdin \
		>| ${CORE_PATH}/${PROJECT}/REPORTS/QC_REPORTS/${PROJECT}.QC_REPORT.${TIMESTAMP}.csv

###########################################################################
##### MAKE A QC REPORT FOR JUST THE SAMPLES IN THE BATCH PER PROJECT  #####
###########################################################################

	##################################################################################
	### CONCATENATE INDIVIDUAL QC REPORTS FOR JUST THE SAMPLES IN THE SAMPLE SHEET ###
	##################################################################################

		# Create the headers for the new files using the header from the all project samples QC report

			head -n 1 ${CORE_PATH}/${PROJECT}/TEMP/${PROJECT}.QC_REPORT.${TIMESTAMP}.TEMP.csv \
			>| ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}.QC_REPORT.csv

		# generate a list of all samples in the sample sheet

			CREATE_SAMPLE_ARRAY ()
			{
				SAMPLE_ARRAY=(`awk 1 ${SAMPLE_SHEET} \
					| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
					| awk 'BEGIN {FS=","} \
						$8=="'${SM_TAG}'" \
						{print $8}' \
					| sort \
					| uniq`)

				#  8  SM_Tag=sample ID

					SM_TAG=${SAMPLE_ARRAY[0]}
			}

		# for all samples in the sample sheet extract those samples from the all project samples QC report

			for SM_TAG in $(awk 'BEGIN {FS=","} \
				$1=="'${PROJECT}'" \
				{print $8}' ${SAMPLE_SHEET} \
					| sort \
					| uniq );
			do
				CREATE_SAMPLE_ARRAY

				cat ${CORE_PATH}/${PROJECT}/REPORTS/QC_REPORT_PREP/${SM_TAG}.QC_REPORT_PREP.txt \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}.QC_REPORT.${TIMESTAMP}.txt
			done

		# convert tabs to comma delimited for final batch qc report

			sed 's/\t/,/g' ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}.QC_REPORT.${TIMESTAMP}.txt \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}.QC_REPORT.csv

	########################################################################################
	### JOIN SEQUENCING METRICS BATCH REPORT WITH LAB QC PREP METRICS AT THE BATCH LEVEL ###
	########################################################################################

		(head -n 1 ${CORE_PATH}/${PROJECT}/REPORTS/LAB_PREP_REPORTS/${SAMPLE_SHEET_NAME}.LAB_PREP_METRICS.csv ; \
		awk 'NR>1' ${CORE_PATH}/${PROJECT}/REPORTS/LAB_PREP_REPORTS/${SAMPLE_SHEET_NAME}.LAB_PREP_METRICS.csv \
			| sort -t',' -k 1,1 ) \
				| join -t , -1 2 -2 1 \
					${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}.QC_REPORT.csv \
					/dev/stdin \
		>| ${CORE_PATH}/${PROJECT}/REPORTS/QC_REPORTS/${SAMPLE_SHEET_NAME}.QC_REPORT.csv

#######################################################
##### CONCATENATE ALL ANEUPLOIDY REPORTS TOGETHER #####
#######################################################

	( cat ${CORE_PATH}/${PROJECT}/REPORTS/ANEUPLOIDY_CHECK/*.chrom_count_report.txt \
		| grep "^SM_TAG" \
		| uniq ; \
	cat ${CORE_PATH}/${PROJECT}/REPORTS/ANEUPLOIDY_CHECK/*.chrom_count_report.txt \
		| grep -v "SM_TAG" ) \
			| sed 's/\t/,/g' \
	>| ${CORE_PATH}/${PROJECT}/REPORTS/QC_REPORTS/${PROJECT}.ANEUPLOIDY_CHECK.${TIMESTAMP}.csv

#####################################################################
##### CONCATENATE ALL PER AUTOSOME VERIFYBAMID REPORTS TOGETHER #####
#####################################################################

	( cat ${CORE_PATH}/${PROJECT}/REPORTS/VERIFYBAMID_CHR/*.VERIFYBAMID.PER_CHR.txt \
		| grep "^#" \
		| uniq ; \
	cat ${CORE_PATH}/${PROJECT}/REPORTS/VERIFYBAMID_CHR/*.VERIFYBAMID.PER_CHR.txt \
		| grep -v "^#" ) \
			| sed 's/\t/,/g' \
	>| ${CORE_PATH}/${PROJECT}/REPORTS/QC_REPORTS/${PROJECT}.PER_CHR_VERIFYBAMID.${TIMESTAMP}.csv

##############################################################
##### SEND EMAIL NOTIFICATION SUMMARIES WHEN DONE ############
##### CLEAN-UP OR NOT DEPENDING ON IF JOBS FAILED OR NOT #####
##############################################################

	# grab email addy

		SEND_TO=$(cat ${SUBMITTER_SCRIPT_PATH}/email_lists.txt)

	# grab submitter's name

		PERSON_NAME=$(getent passwd \
			| awk 'BEGIN {FS=":"} \
				$1=="'${SUBMITTER_ID}'" \
				{print $5}')

	# IF THERE ARE NO FAILED JOBS SEND EMAIL NOTIFICATION AND THEN DELETE TEMP FILES FOR THIS BATCH
	if [[ ! -f ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt ]]
	then
		if [[ -f ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_MULTIPLE_LIBS.txt ]]
		then # note that there are samples with multiple libraries, but no errors.
			printf "THIS RUN COMPLETED SUCCESSFULLY WITH NO ERRORS.\n \
			SO THE TEMP FILES HAVE BEEN DELETED FOR THIS BATCH.\n \
			${PERSON_NAME} Was The Submitter\n \
			THIS BATCH HAS SAMPLES WITH MULTIPLE LIBRARIES. SEE BELOW FOR THE LIST OF SAMPLES\n \
			REPORTS ARE AT:\n ${CORE_PATH}/${PROJECT}/REPORTS/QC_REPORTS\n\n \
			BATCH QC REPORT:\n ${SAMPLE_SHEET_NAME}.QC_REPORT.csv\n\n \
			FULL PROJECT QC REPORT:\n ${PROJECT}.QC_REPORT.${TIMESTAMP}.csv\n\n \
			ANEUPLOIDY REPORT:\n ${PROJECT}.ANEUPLOIDY_CHECK.${TIMESTAMP}.csv\n\n \
			BY CHROMOSOME VERIFYBAMID REPORT:\n ${PROJECT}.PER_CHR_VERIFYBAMID.${TIMESTAMP}.csv\n" \
			>| ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "SAMPLES THAT CONTAIN MULTIPLE LIBRARIES:\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			cat ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_MULTIPLE_LIBS.txt \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			mail -s "NO ERRORS: ${SAMPLE_SHEET} FOR ${PROJECT} has finished processing CIDR.WES.QC.SUBMITTER.HG19.sh" \
				${SEND_TO}	\
			< ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt
		else # send vanilla email. no exceptions noted.
			printf "THIS RUN COMPLETED SUCCESSFULLY WITH NO ERRORS.\n \
			SO THE TEMP FILES HAVE BEEN DELETED FOR THIS BATCH.\n \
			${PERSON_NAME} Was The Submitter\n \
			REPORTS ARE AT:\n ${CORE_PATH}/${PROJECT}/REPORTS/QC_REPORTS\n\n \
			BATCH QC REPORT:\n ${SAMPLE_SHEET_NAME}.QC_REPORT.csv\n\n \
			FULL PROJECT QC REPORT:\n ${PROJECT}.QC_REPORT.${TIMESTAMP}.csv\n\n \
			ANEUPLOIDY REPORT:\n ${PROJECT}.ANEUPLOIDY_CHECK.${TIMESTAMP}.csv\n\n \
			BY CHROMOSOME VERIFYBAMID REPORT:\n ${PROJECT}.PER_CHR_VERIFYBAMID.${TIMESTAMP}.csv\n" \
			| mail -s "NO ERRORS: ${SAMPLE_SHEET} FOR ${PROJECT} has finished processing CIDR.WES.QC.SUBMITTER.HG19.sh" \
				${SEND_TO}
		fi
		# delete temp files
			echo rm -rf ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/
			rm -rf ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/
	# ELSE IF: JOBS FAILED, BUT ONLY CONCORDANCE JOBS, THEN DELETE AND SUMMARIZE WHAT SAMPLES FAILED CONCORDANCE
	elif [[ "`awk 'BEGIN {OFS="\t"} \
				NF==6 \
				{print $0}' \
			${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
				| egrep -v "CONCORDANCE" \
				| wc -l`" -eq 0 ]];
	then # construct email message for batch that only had concordance jobs fail.
		if [[ -f ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_MULTIPLE_LIBS.txt ]]
		then # message when concordance failed and there are samples with multiple libraries.
			printf "THIS RUN COMPLETED WITH ONLY HAVING ERRORS FOR CONCORDANCE JOBS.\n \
			SO THE TEMP FILES HAVE BEEN DELETED FOR THIS BATCH.\n \
			${PERSON_NAME} Was The Submitter\n \
			THIS BATCH HAS SAMPLES WITH MULTIPLE LIBRARIES. SEE BELOW FOR THE LIST OF SAMPLES\n \
			REPORTS ARE AT:\n ${CORE_PATH}/${PROJECT}/REPORTS/QC_REPORTS\n\n \
			BATCH QC REPORT:\n ${SAMPLE_SHEET_NAME}.QC_REPORT.csv\n\n \
			FULL PROJECT QC REPORT:\n ${PROJECT}.QC_REPORT.${TIMESTAMP}.csv\n\n \
			ANEUPLOIDY REPORT:\n ${PROJECT}.ANEUPLOIDY_CHECK.${TIMESTAMP}.csv\n\n \
			BY CHROMOSOME VERIFYBAMID REPORT:\n ${PROJECT}.PER_CHR_VERIFYBAMID.${TIMESTAMP}.csv\n" \
			>| ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "BELOW ARE THE SAMPLES THAT FAILED CONCORDANCE:\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			awk 'BEGIN {OFS="\t"} \
				NF==6 {print $0}' \
			${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
				| grep CONCORDANCE \
				| awk '{print $1}' \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "SAMPLES THAT CONTAIN MULTIPLE LIBRARIES:\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			cat ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_MULTIPLE_LIBS.txt \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			sleep 2s

			mail -s "CONCORDANCE FAILURES ONLY: ${SAMPLE_SHEET} FOR ${PROJECT} has finished processing CIDR.WES.QC.SUBMITTER.HG19.sh" \
				${SEND_TO} \
			< ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt
		else # message when concordance failed and there are no samples with multiple libraries
			printf "THIS RUN COMPLETED WITH ONLY HAVING ERRORS FOR CONCORDANCE JOBS.\n \
			SO THE TEMP FILES HAVE BEEN DELETED FOR THIS BATCH.\n \
			${PERSON_NAME} Was The Submitter\n \
			REPORTS ARE AT:\n ${CORE_PATH}/${PROJECT}/REPORTS/QC_REPORTS\n\n \
			BATCH QC REPORT:\n ${SAMPLE_SHEET_NAME}.QC_REPORT.csv\n\n \
			FULL PROJECT QC REPORT:\n ${PROJECT}.QC_REPORT.${TIMESTAMP}.csv\n\n \
			ANEUPLOIDY REPORT:\n ${PROJECT}.ANEUPLOIDY_CHECK.${TIMESTAMP}.csv\n\n \
			BY CHROMOSOME VERIFYBAMID REPORT:\n ${PROJECT}.PER_CHR_VERIFYBAMID.${TIMESTAMP}.csv\n" \
			>| ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "BELOW ARE THE SAMPLES THAT FAILED CONCORDANCE:\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			awk 'BEGIN {OFS="\t"} \
				NF==6 {print $0}' \
			${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
				| grep CONCORDANCE \
				| awk '{print $1}' \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			sleep 2s

			mail -s "CONCORDANCE FAILURES ONLY: ${SAMPLE_SHEET} FOR ${PROJECT} has finished processing CIDR.WES.QC.SUBMITTER.HG19.sh" \
				${SEND_TO} \
			< ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt
		fi
		# delete temp files
			echo rm -rf ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/
			rm -rf ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/
	# ELSE; CRUCIAL JOBS FAILED. DON'T DELETE ANYTHING BUT SUMMARIZE WHAT FAILED.
	else # construct email message for batch that had jobs failed other than concordance jobs
		if [[ -f ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_MULTIPLE_LIBS.txt \
			&& ! -f ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_TOTAL_FAILURES.txt ]]
		then # message when there are samples with multiple libraries, BUT NO TOTAL FAILURES.
			printf "SO BAD THINGS HAPPENED AND THE TEMP FILES WILL NOT BE DELETED FOR BATCH.\n \
			${PERSON_NAME} Was The Submitter\n \
			THIS BATCH HAS SAMPLES WITH MULTIPLE LIBRARIES. SEE BELOW FOR THE LIST OF SAMPLES\n \
			REPORTS ARE AT:\n ${CORE_PATH}/${PROJECT}/REPORTS/QC_REPORTS\n\n \
			BATCH QC REPORT:\n ${SAMPLE_SHEET_NAME}.QC_REPORT.csv\n\n \
			FULL PROJECT QC REPORT:\n ${PROJECT}.QC_REPORT.${TIMESTAMP}.csv\n\n \
			ANEUPLOIDY REPORT:\n ${PROJECT}.ANEUPLOIDY_CHECK.${TIMESTAMP}.csv\n\n \
			BY CHROMOSOME VERIFYBAMID REPORT:\n ${PROJECT}.PER_CHR_VERIFYBAMID.${TIMESTAMP}.csv\n" \
			>| ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "SOMEWHAT FULL LISTING OF FAILED JOBS ARE HERE:\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "BELOW ARE THE SAMPLES AND THE MINIMUM NUMBER OF JOBS THAT FAILED PER SAMPLE (EXCLUDING CONCORDANCE):\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			egrep -v CONCORDANCE ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
				| awk 'BEGIN {OFS="\t"} \
					NF==6 \
					{print $1}' \
				| sort \
				| singularity exec ${ALIGNMENT_CONTAINER} datamash \
					-g 1 \
					count 1 \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "FOR THE SAMPLES THAT HAVE FAILED JOBS, THIS IS ROUGHLY THE FIRST JOB THAT FAILED FOR EACH SAMPLE (EXCLUDING CONCORDANCE):\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "SM_TAG NODE JOB_NAME USER EXIT LOG_FILE\n" \
				| sed 's/ /\t/g' \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			for sample in $(grep -v CONCORDANCE ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
					| awk 'BEGIN {OFS="\t"} \
						NF==6 \
						{print $1}' \
					| sort \
					| uniq);
			do
				awk '$1=="'${sample}'" \
					{print $0 "\n" "\n"}' \
				${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
					| head -n 1 \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt
			done

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "FOR GIGGLES, HERE ARE THE SAMPLES THAT FAILED CONCORDANCE:\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			grep CONCORDANCE ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
				| awk 'BEGIN {OFS="\t"} \
					NF==6 \
					{print $1}' \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "SAMPLES THAT CONTAIN MULTIPLE LIBRARIES:\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			cat ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_MULTIPLE_LIBS.txt \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			sleep 2s

			mail -s "FAILED JOBS: ${SAMPLE_SHEET} FOR ${PROJECT} has finished processing CIDR.WES.QC.SUBMITTER.HG19.sh" \
				${SEND_TO} \
			< ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt
		elif [[ ! -f ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_MULTIPLE_LIBS.txt \
			&& -f ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_TOTAL_FAILURES.txt ]]
		then # message for no samples with multiple libraries, but samples that were total failures
			printf "SO BAD THINGS HAPPENED AND THE TEMP FILES WILL NOT BE DELETED FOR BATCH.\n \
			${PERSON_NAME} Was The Submitter\n \
			THIS BATCH HAS SAMPLES THAT WERE TOTAL FAILURES. SEE BELOW FOR THE LIST OF SAMPLES\n \
			REPORTS ARE AT:\n ${CORE_PATH}/${PROJECT}/REPORTS/QC_REPORTS\n\n \
			BATCH QC REPORT:\n ${SAMPLE_SHEET_NAME}.QC_REPORT.csv\n\n \
			FULL PROJECT QC REPORT:\n ${PROJECT}.QC_REPORT.${TIMESTAMP}.csv\n\n \
			ANEUPLOIDY REPORT:\n ${PROJECT}.ANEUPLOIDY_CHECK.${TIMESTAMP}.csv\n\n \
			BY CHROMOSOME VERIFYBAMID REPORT:\n ${PROJECT}.PER_CHR_VERIFYBAMID.${TIMESTAMP}.csv\n" \
			>| ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "SAMPLES THAT WERE TOTAL FAILURES:\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			cat ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_TOTAL_FAILURES.txt \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "SOMEWHAT FULL LISTING OF FAILED JOBS ARE HERE:\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "BELOW ARE THE SAMPLES AND THE MINIMUM NUMBER OF JOBS THAT FAILED PER SAMPLE (EXCLUDING CONCORDANCE):\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			egrep -v CONCORDANCE ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
				| awk 'BEGIN {OFS="\t"} \
					NF==6 \
					{print $1}' \
				| sort \
				| singularity exec ${ALIGNMENT_CONTAINER} datamash \
					-g 1 \
					count 1 \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "FOR THE SAMPLES THAT HAVE FAILED JOBS, THIS IS ROUGHLY THE FIRST JOB THAT FAILED FOR EACH SAMPLE (EXCLUDING CONCORDANCE):\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "SM_TAG NODE JOB_NAME USER EXIT LOG_FILE\n" \
				| sed 's/ /\t/g' \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			for sample in $(grep -v CONCORDANCE ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
					| awk 'BEGIN {OFS="\t"} \
						NF==6 \
						{print $1}' \
					| sort \
					| uniq);
			do
				awk '$1=="'${sample}'" \
					{print $0 "\n" "\n"}' \
				${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
					| head -n 1 \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt
			done

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "FOR GIGGLES, HERE ARE THE SAMPLES THAT FAILED CONCORDANCE:\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			grep CONCORDANCE ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
				| awk 'BEGIN {OFS="\t"} \
					NF==6 \
					{print $1}' \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			sleep 2s

			mail -s "FAILED JOBS: ${SAMPLE_SHEET} FOR ${PROJECT} has finished processing CIDR.WES.QC.SUBMITTER.HG19.sh" \
				${SEND_TO} \
			< ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt
		elif [[ -f ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_MULTIPLE_LIBS.txt \
			&& -f ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_TOTAL_FAILURES.txt ]]
		then # message when there are samples with multiple libraries and samples that are total failures
			printf "SO BAD THINGS HAPPENED AND THE TEMP FILES WILL NOT BE DELETED FOR BATCH.\n \
			${PERSON_NAME} Was The Submitter\n \
			THIS BATCH HAS SAMPLES THAT WERE TOTAL FAILURES. SEE BELOW FOR THE LIST OF SAMPLES\n \
			THIS BATCH HAS SAMPLES WITH MULITPLE LIBRARIES. SEE BELOW FOR THE LIST OF SAMPLES\n \
			REPORTS ARE AT:\n ${CORE_PATH}/${PROJECT}/REPORTS/QC_REPORTS\n\n \
			BATCH QC REPORT:\n ${SAMPLE_SHEET_NAME}.QC_REPORT.csv\n\n \
			FULL PROJECT QC REPORT:\n ${PROJECT}.QC_REPORT.${TIMESTAMP}.csv\n\n \
			ANEUPLOIDY REPORT:\n ${PROJECT}.ANEUPLOIDY_CHECK.${TIMESTAMP}.csv\n\n \
			BY CHROMOSOME VERIFYBAMID REPORT:\n ${PROJECT}.PER_CHR_VERIFYBAMID.${TIMESTAMP}.csv\n" \
			>| ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "SAMPLES THAT WERE TOTAL FAILURES:\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			cat ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_TOTAL_FAILURES.txt \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "SOMEWHAT FULL LISTING OF FAILED JOBS ARE HERE:\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "BELOW ARE THE SAMPLES AND THE MINIMUM NUMBER OF JOBS THAT FAILED PER SAMPLE (EXCLUDING CONCORDANCE):\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			egrep -v CONCORDANCE ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
				| awk 'BEGIN {OFS="\t"} \
					NF==6 \
					{print $1}' \
				| sort \
				| singularity exec ${ALIGNMENT_CONTAINER} datamash \
					-g 1 \
					count 1 \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "FOR THE SAMPLES THAT HAVE FAILED JOBS, THIS IS ROUGHLY THE FIRST JOB THAT FAILED FOR EACH SAMPLE (EXCLUDING CONCORDANCE):\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "SM_TAG NODE JOB_NAME USER EXIT LOG_FILE\n" \
				| sed 's/ /\t/g' \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			for sample in $(grep -v CONCORDANCE ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
					| awk 'BEGIN {OFS="\t"} \
						NF==6 \
						{print $1}' \
					| sort \
					| uniq);
			do
				awk '$1=="'${sample}'" \
					{print $0 "\n" "\n"}' \
				${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
					| head -n 1 \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt
			done

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "FOR GIGGLES, HERE ARE THE SAMPLES THAT FAILED CONCORDANCE:\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			grep CONCORDANCE ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
				| awk 'BEGIN {OFS="\t"} \
					NF==6 \
					{print $1}' \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "SAMPLES THAT CONTAIN MULTIPLE LIBRARIES:\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			cat ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_MULTIPLE_LIBS.txt \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			sleep 2s

			mail -s "FAILED JOBS: ${SAMPLE_SHEET} FOR ${PROJECT} has finished processing CIDR.WES.QC.SUBMITTER.HG19.sh" \
				${SEND_TO} \
			< ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt
		else # message when there are no samples with multiple libraries or total failures
			printf "SO BAD THINGS HAPPENED AND THE TEMP FILES WILL NOT BE DELETED FOR BATCH.\n \
			${PERSON_NAME} Was The Submitter\n \
			REPORTS ARE AT:\n ${CORE_PATH}/${PROJECT}/REPORTS/QC_REPORTS\n\n \
			BATCH QC REPORT:\n ${SAMPLE_SHEET_NAME}.QC_REPORT.csv\n\n \
			FULL PROJECT QC REPORT:\n ${PROJECT}.QC_REPORT.${TIMESTAMP}.csv\n\n \
			ANEUPLOIDY REPORT:\n ${PROJECT}.ANEUPLOIDY_CHECK.${TIMESTAMP}.csv\n\n \
			BY CHROMOSOME VERIFYBAMID REPORT:\n ${PROJECT}.PER_CHR_VERIFYBAMID.${TIMESTAMP}.csv\n" \
			>| ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "SOMEWHAT FULL LISTING OF FAILED JOBS ARE HERE:\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "BELOW ARE THE SAMPLES AND THE MINIMUM NUMBER OF JOBS THAT FAILED PER SAMPLE (EXCLUDING CONCORDANCE):\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			egrep -v CONCORDANCE ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
				| awk 'BEGIN {OFS="\t"} \
					NF==6 \
					{print $1}' \
				| sort \
				| singularity exec ${ALIGNMENT_CONTAINER} datamash \
					-g 1 \
					count 1 \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "FOR THE SAMPLES THAT HAVE FAILED JOBS, THIS IS ROUGHLY THE FIRST JOB THAT FAILED FOR EACH SAMPLE (EXCLUDING CONCORDANCE):\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "SM_TAG NODE JOB_NAME USER EXIT LOG_FILE\n" \
				| sed 's/ /\t/g' \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			for sample in $(grep -v CONCORDANCE ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
					| awk 'BEGIN {OFS="\t"} \
						NF==6 \
						{print $1}' \
					| sort \
					| uniq);
			do
				awk '$1=="'${sample}'" \
					{print $0 "\n" "\n"}' \
				${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
					| head -n 1 \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt
			done

			printf "###################################################################\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			printf "FOR GIGGLES, HERE ARE THE SAMPLES THAT FAILED CONCORDANCE:\n" \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			grep CONCORDANCE ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt \
				| awk 'BEGIN {OFS="\t"} \
					NF==6 \
					{print $1}' \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt

			sleep 2s

			mail -s "FAILED JOBS: ${SAMPLE_SHEET} FOR ${PROJECT} has finished processing CIDR.WES.QC.SUBMITTER.HG19.sh" \
				${SEND_TO} \
			< ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_EMAIL_SUMMARY.txt
		fi
	fi

	sleep 2s

####################################################
##### Clean up the Wall Clock minutes tracker. #####
####################################################

	# clean up records that are malformed
	# only keep jobs that ran longer than 3 minutes

		awk 'BEGIN {FS=",";OFS=","} \
			$1~/^[A-Z 0-9]/&&$2!=""&&$3!=""&&$4!=""&&$5!=""&&$6!=""&&$7==""&&$5!~/A-Z/&&$6!~/A-Z/&&($6-$5)>180 \
			{print $1,"'${PROJECT}'",$2,$3,$4,$5,$6,($6-$5)/60,\
				strftime("%F",$5),strftime("%F",$6),strftime("%F.%H-%M-%S",$5),strftime("%F.%H-%M-%S",$6)}' \
		${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.csv \
			| sed 's/_'"${PROJECT}"'/,'"${PROJECT}"'/g' \
			| awk 'BEGIN {print "SAMPLE,PROJECT,TASK_GROUP,TASK,HOST,EPOCH_START,EPOCH_END,\
					WC_MIN,START_DATE,END_DATE,TIMESTAMP_START,TIMESTAMP_END"} \
				{print $0}' \
		>| ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.FIXED.csv

#############################################################
##### Summarize Wall Clock times ############################
#############################################################

	# summarize by sample by taking the max times per concurrent task group and summing them up

		sed 's/,/\t/g' ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.FIXED.csv \
			| awk 'NR>1' \
			| sed 's/_BAM_REPORTS//g' \
			| sort -k 1,1 -k 2,2 -k 3,3 -k 4,4 \
			| awk 'BEGIN {OFS="\t"} {print $0,($7-$6),($7-$6)/60,($7-$6)/3600}' \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				-s \
				-g 1,2,3 \
				max 13 \
				max 14 \
				max 15 \
			| tee ${CORE_PATH}/${PROJECT}/TEMP/WALL.CLOCK.TIMES.BY.GROUP.txt \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				-g 1,2 \
				sum 4 \
				sum 5 \
				sum 6 \
			| awk 'BEGIN \
				{print "SAMPLE","PROJECT","WALL_CLOCK_SECONDS","WALL_CLOCK_MINUTES","WALL_CLOCK_HOURS"} \
				{print $0}' \
			| sed -r 's/[[:space:]]+/,/g' \
		>| ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.BY_SAMPLE.csv

	# break down by the longest task within a group per sample

		sed 's/\t/,/g' ${CORE_PATH}/${PROJECT}/TEMP/WALL.CLOCK.TIMES.BY.GROUP.txt \
			| awk 'BEGIN {print "SAMPLE","PROJECT","TASK_GROUP","WALL_CLOCK_SECONDS","WALL_CLOCK_MINUTES","WALL_CLOCK_HOURS"} {print $0}' \
			| sed -r 's/[[:space:]]+/,/g' \
		>| ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.BY_SAMPLE_GROUP.csv

# put a stamp as to when the run was done

	echo Project finished at `date` >> ${CORE_PATH}/${PROJECT}/REPORTS/PROJECT_START_END_TIMESTAMP.txt
