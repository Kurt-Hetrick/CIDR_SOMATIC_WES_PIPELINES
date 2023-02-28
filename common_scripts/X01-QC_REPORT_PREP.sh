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

# INPUT PARAMETERS

	ALIGNMENT_CONTAINER=$1
	CORE_PATH=$2
	PROJECT=$3
	SM_TAG=$4
	SAMPLE_SHEET=$5
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$6

# next script will cat everything together and add the header.
# dirty validations count NF, if not X, then say haha you suck try again and don't write to cat file.

#########################################################################
### Grabbing the BAM header (for RG ID,PU,LB,etc) #######################
#########################################################################
### THIS IS THE HEADER ##################################################
### "SM_TAG","PROJECT","RG_PU","LIBRARY" ################################
### "LIBRARY_PLATE","LIBRARY_WELL","LIBRARY_ROW","LIBRARY_COLUMN" #######
### "HYB_PLATE","HYB_WELL","HYB_ROW","HYB_COLUMN" #######################
### "CRAM_PIPELINE_VERSION","SEQUENCING_PLATFORM","SEQUENCER_MODEL" #####
### "EXEMPLAR_DATE","BAIT_BED_FILE","TARGET_BED_FILE","TITV_BED_FILE" ###
#########################################################################

	if [ -f ${CORE_PATH}/${PROJECT}/REPORTS/RG_HEADER/${SM_TAG}.RG_HEADER.txt ]
	then
		cat ${CORE_PATH}/${PROJECT}/REPORTS/RG_HEADER/${SM_TAG}.RG_HEADER.txt \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				-s \
				-g 1,2 \
				collapse 3 \
				unique 4 \
				unique 5 \
				unique 6 \
				unique 7 \
				unique 8 \
				unique 9 \
				unique 10 \
				unique 11 \
				unique 12 \
				unique 13 \
				unique 14 \
				unique 15 \
				unique 16 \
				unique 17 \
				unique 18 \
				unique 19 \
			| sed 's/,/;/g' \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>| ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt

	elif [[ ! -f ${CORE_PATH}/${PROJECT}/REPORTS/RG_HEADER/${SM_TAG}.RG_HEADER.txt \
			&& -f ${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram ]];
	then

		# grab field number for SM_TAG

			SM_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools \
				view -H \
			${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram \
				| grep -m 1 ^@RG \
				| sed 's/\t/\n/g' \
				| cat -n \
				| sed 's/^ *//g' \
				| awk '$2~/^SM:/ \
					{print $1}'`)

		# grab field number for PLATFORM_UNIT_TAG

			PU_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools \
				view -H \
			${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram \
				| grep -m 1 ^@RG \
				| sed 's/\t/\n/g' \
				| cat -n \
				| sed 's/^ *//g' \
				| awk '$2~/^PU:/ \
					{print $1}'`)

		# grab field number for LIBRARY_TAG

			LB_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools \
				view -H \
			${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram \
				| grep -m 1 ^@RG \
				| sed 's/\t/\n/g' \
				| cat -n \
				| sed 's/^ *//g' \
				| awk '$2~/^LB:/ \
					{print $1}'`)

			# grab field number for CRAM_PROCESSING_VERSION (PG field)

				PG_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools \
					view -H \
				${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram \
					| grep -m 1 ^@RG \
					| sed 's/\t/\n/g' \
					| cat -n \
					| sed 's/^ *//g' \
					| awk '$2~/^PG:/ \
						{print $1}'`)

			# grab field number for PLATFORM_MODEL field (PG field)

				PM_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools \
					view -H \
				${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram \
					| grep -m 1 ^@RG \
					| sed 's/\t/\n/g' \
					| cat -n \
					| sed 's/^ *//g' \
					| awk '$2~/^PM:/ \
						{print $1}'`)

			# grab field number for LIMS_DATE

				DT_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools \
					view -H \
				${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram \
					| grep -m 1 ^@RG \
					| sed 's/\t/\n/g' \
					| cat -n \
					| sed 's/^ *//g' \
					| awk '$2~/^DT:/ \
						{print $1}'`)

			# grab field number for PLATFORM

				PL_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools \
					view -H \
				${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram \
					| grep -m 1 ^@RG \
					| sed 's/\t/\n/g' \
					| cat -n \
					| sed 's/^ *//g' \
					| awk '$2~/^PL:/ \
						{print $1}'`)

			# grab field number for BED FILES (DS field)

				DS_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools \
					view -H \
				${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram \
					| grep -m 1 ^@RG \
					| sed 's/\t/\n/g' \
					| cat -n \
					| sed 's/^ *//g' \
					| awk '$2~/^DS:/ \
						{print $1}'`)

		# Now grab the header and format
			# breaking out the library name into its parts is assuming that the format is...
			# fill in empty fields with NA thing (for loop in awk) is a lifesaver
			# https://unix.stackexchange.com/questions/53448/replacing-missing-value-blank-space-with-zero

				singularity exec ${ALIGNMENT_CONTAINER} samtools \
					view -H \
				${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram \
					| grep ^@RG \
					| awk \
						-v SM_FIELD="$SM_FIELD" \
						-v PU_FIELD="$PU_FIELD" \
						-v LB_FIELD="$LB_FIELD" \
						-v PG_FIELD="$PG_FIELD" \
						-v PM_FIELD="$PM_FIELD" \
						-v DT_FIELD="$DT_FIELD" \
						-v PL_FIELD="$PL_FIELD" \
						-v DS_FIELD="$DS_FIELD" \
						'BEGIN {OFS="\t"} \
						{split($SM_FIELD,SMtag,":"); \
						split($PU_FIELD,PU,":"); \
						split($LB_FIELD,Library,":"); \
						split(Library[2],Library_Unit,"_"); \
						split($PG_FIELD,PROGRAM,":"); \
						split($PL_FIELD,SEQ_PLATFORM,":"); \
						split($PM_FIELD,SEQ_MODEL,":"); \
						split($DT_FIELD,DT,":"); \
						split(DT[2],DATE,"T"); \
						split($DS_FIELD,DS,":"); \
						split(DS[2],BED_FILES,","); \
						print "'${PROJECT}'",\
							SMtag[2],\
							PU[2],\
							Library[2],\
							Library_Unit[1],\
							Library_Unit[2],\
							substr(Library_Unit[2],1,1),\
							substr(Library_Unit[2],2,2),\
							Library_Unit[3],\
							Library_Unit[4],\
							substr(Library_Unit[4],1,1),\
							substr(Library_Unit[4],2,2),\
							PROGRAM[2],\
							SEQ_PLATFORM[2],\
							SEQ_MODEL[2],\
							DATE[1],\
							BED_FILES[1],\
							BED_FILES[2],\
							BED_FILES[3]}' \
					| awk 'BEGIN { FS = OFS = "\t" } { for(i=1; i<=NF; i++) if($i ~ /^ *$/) $i = "NA" }; 1' \
					| singularity exec ${ALIGNMENT_CONTAINER} datamash \
						-s \
						-g 1,2 \
						collapse 3 \
						unique 4 \
						unique 5 \
						unique 6 \
						unique 7 \
						unique 8 \
						unique 9 \
						unique 10 \
						unique 11 \
						unique 12 \
						unique 13 \
						unique 14 \
						unique 15 \
						unique 16 \
						unique 17 \
						unique 18 \
						unique 19 \
					| sed 's/,/;/g' \
					| singularity exec ${ALIGNMENT_CONTAINER} datamash \
						transpose \
				>| ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	else
			echo -e "${PROJECT}\t${SM_TAG}\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA" \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
			>| ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	fi

#####################################################
### GENDER CHECK FROM ANEUPLOIDY CHECK ##############
#####################################################
### THIS IS THE HEADER ##############################
### "X_AVG_DP","X_NORM_DP","Y_AVG_DP","Y_NORM_DP" ###
#####################################################

	awk 'BEGIN {OFS="\t"} \
		$2=="X"&&$3=="whole" \
			{print "X",$6,$7} \
		$2=="Y"&&$3=="whole" \
			{print "Y",$6,$7}' \
	${CORE_PATH}/${PROJECT}/REPORTS/ANEUPLOIDY_CHECK/${SM_TAG}.chrom_count_report.txt \
		| paste - - \
		| awk 'BEGIN {OFS="\t"} \
			END {if ($1=="X"&&$4=="Y") \
				print $2,$3,$5,$6 ; \
			else if ($1=="X"&&$4=="") \
				print $2,$3,"NaN","NaN" ; \
			else if ($1=="Y"&&$4=="") \
				print "NaN","NaN",$5,$6 ; \
			else \
				print "NaN","NaN","NaN","NaN"}' \
		| singularity exec ${ALIGNMENT_CONTAINER} datamash \
			transpose \
	>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt

#####################################################################
### GRABBING CONCORDANCE ############################################
#####################################################################
### THIS IS THE HEADER ##############################################
### "COUNT_DISC_HOM","COUNT_CONC_HOM","PERCENT_CONC_HOM", ###########
### "COUNT_DISC_HET","COUNT_CONC_HET","PERCENT_CONC_HET", ###########
### "PERCENT_TOTAL_CONC","COUNT_HET_BEADCHIP","SENSITIVITY_2_HET" ###
#####################################################################

	if [ -f ${CORE_PATH}/${PROJECT}/REPORTS/CONCORDANCE/${SM_TAG}_concordance.csv ];
	then
		awk 1 ${CORE_PATH}/${PROJECT}/REPORTS/CONCORDANCE/${SM_TAG}_concordance.csv \
			| awk 'BEGIN {FS=",";OFS="\t"} \
				NR>1 \
				{print $5,$6,$7,$2,$3,$4,$8,$9,$10,$11}' \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	else
		echo -e "NaN\tNaN\tNaN\tNaN\tNaN\tNaN\tNaN\tNaN\tNaN\tNaN" \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	fi

#####################################################################################
### VERIFY BAM ID ###################################################################
#####################################################################################
### THIS IS THE HEADER ##############################################################
### "VERIFYBAM_FREEMIX","VERIFYBAM_#SNPS","VERIFYBAM_FREELK1","VERIFYBAM_FREELK0" ###
### "VERIFYBAM_DIFF_LK0_LK1","VERIFYBAM_AVG_DP" #####################################
#####################################################################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/REPORTS/VERIFYBAMID/${SM_TAG}.selfSM ]]
	then
		echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	else
		awk 'BEGIN {OFS="\t"} \
			NR>1 \
			{print $7*100,$4,$8,$9,($9-$8),$6}' \
		${CORE_PATH}/${PROJECT}/REPORTS/VERIFYBAMID/${SM_TAG}.selfSM \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	fi

#######################################################
### GATK CALCULATE TUMOR CONTAMINATION ################
#######################################################
### THIS IS THE HEADER ################################
### "GATK_TUMOR_CONTAM_PCT","GATK_TUMOR_CONTAM_ERR" ###
#######################################################

	if
		[[ ! -f ${CORE_PATH}/${PROJECT}/REPORTS/GATK_CALC_TUMOR_CONTAM/${SM_TAG}.calculatetumorcontamination.table ]]
	then
		echo -e NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	else
		awk 'BEGIN {OFS="\t"} \
			NR==2 \
			{print $2*100,$3*100}' \
		${CORE_PATH}/${PROJECT}/REPORTS/GATK_CALC_TUMOR_CONTAM/${SM_TAG}.calculatetumorcontamination.table \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	fi

######################################################################################################
##### INSERT SIZE ####################################################################################
######################################################################################################
##### THIS IS THE HEADER #############################################################################
##### "MEDIAN_INSERT_SIZE","MEAN_INSERT_SIZE","STANDARD_DEVIATION_INSERT_SIZE","MAD_INSERT_SIZE" #####
######################################################################################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/REPORTS/INSERT_SIZE/METRICS/${SM_TAG}.insert_size_metrics.txt ]]
	then
		echo -e NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	else
		awk 'BEGIN {OFS="\t"} \
			NR==8 \
			{print $1,$6,$7,$3}' \
		${CORE_PATH}/${PROJECT}/REPORTS/INSERT_SIZE/METRICS/${SM_TAG}.insert_size_metrics.txt \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	fi

#######################################################################################
### ALIGNMENT SUMMARY METRICS FOR READ 1 ##############################################
#######################################################################################
### THIS THE HEADER ###################################################################
### "PCT_PF_READS_ALIGNED_R1","PF_HQ_ALIGNED_READS_R1","PF_HQ_ALIGNED_Q20_BASES_R1" ###
### "PF_MISMATCH_RATE_R1","PF_HQ_ERROR_RATE_R1","PF_INDEL_RATE_R1" ####################
### "PCT_READS_ALIGNED_IN_PAIRS_R1","PCT_ADAPTER_R1" ##################################
#######################################################################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/REPORTS/ALIGNMENT_SUMMARY/${SM_TAG}.alignment_summary_metrics.txt ]]
	then
		echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
		| singularity exec ${ALIGNMENT_CONTAINER} datamash \
			transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	else
		awk 'BEGIN {OFS="\t"} \
			NR==8 \
			{if ($1=="UNPAIRED") \
				print "0","0","0","0","0","0","0","0"; \
			else \
				print $7*100,$9,$11,$13,$14,$15,$18*100,$24*100}' \
		${CORE_PATH}/${PROJECT}/REPORTS/ALIGNMENT_SUMMARY/${SM_TAG}.alignment_summary_metrics.txt \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	fi

#######################################################################################
### ALIGNMENT SUMMARY METRICS FOR READ 2 ##############################################
#######################################################################################
### THIS THE HEADER ###################################################################
### "PCT_PF_READS_ALIGNED_R2","PF_HQ_ALIGNED_READS_R2","PF_HQ_ALIGNED_Q20_BASES_R2" ###
### "PF_MISMATCH_RATE_R2","PF_HQ_ERROR_RATE_R2","PF_INDEL_RATE_R2" ####################
### "PCT_READS_ALIGNED_IN_PAIRS_R2","PCT_ADAPTER_R2" ##################################
#######################################################################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/REPORTS/ALIGNMENT_SUMMARY/${SM_TAG}.alignment_summary_metrics.txt ]]
	then
		echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	else

		awk 'BEGIN {OFS="\t"} NR==9 \
			{if ($1=="") \
				print "0","0","0","0","0","0","0","0" ; \
			else \
				print $7*100,$9,$11,$13,$14,$15,$18*100,$24*100}' \
		${CORE_PATH}/${PROJECT}/REPORTS/ALIGNMENT_SUMMARY/${SM_TAG}.alignment_summary_metrics.txt \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	fi

############################################################################################
### ALIGNMENT SUMMARY METRICS FOR PAIR #####################################################
############################################################################################
### THIS THE HEADER ########################################################################
### "TOTAL_READS","RAW_GIGS","PCT_PF_READS_ALIGNED_PAIR" ###################################
### "PF_MISMATCH_RATE_PAIR","PF_HQ_ERROR_RATE_PAIR","PF_INDEL_RATE_PAIR" ###################
### "PCT_READS_ALIGNED_IN_PAIRS_PAIR","STRAND_BALANCE_PAIR","PCT_CHIMERAS_PAIR" ############
### "PF_HQ_ALIGNED_Q20_BASES_PAIR","MEAN_READ_LENGTH","PCT_PF_READS_IMPROPER_PAIRS_PAIR" ###
############################################################################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/REPORTS/ALIGNMENT_SUMMARY/${SM_TAG}.alignment_summary_metrics.txt ]]
	then
		echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	else

		awk 'BEGIN {OFS="\t"} \
			NR==10 \
			{if ($1=="") \
				print "0","0","0","0","0","0","0","0","0","0","0","0" ; \
			else \
				print $2,($2*$16/1000000000),$7*100,$13,$14,$15,$18*100,$22,$23*100,$11,$16,$20*100}' \
		${CORE_PATH}/${PROJECT}/REPORTS/ALIGNMENT_SUMMARY/${SM_TAG}.alignment_summary_metrics.txt \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	fi

##############################################################################################################
### MARK DUPLICATES REPORT ###################################################################################
##############################################################################################################
### THIS IS THE HEADER #######################################################################################
### "UNMAPPED_READS","READ_PAIR_OPTICAL_DUPLICATES","PERCENT_DUPLICATION","ESTIMATED_LIBRARY_SIZE" ###########
### "SECONDARY_OR_SUPPLEMENTARY_READS","READ_PAIR_DUPLICATES","READ_PAIRS_EXAMINED","PAIRED_DUP_RATE" ########
### "UNPAIRED_READ_DUPLICATES","UNPAIRED_READS_EXAMINED","UNPAIRED_DUP_RATE","PERCENT_DUPLICATION_OPTICAL" ###
##############################################################################################################

	MAX_RECORD=$(grep -n "^$" ${CORE_PATH}/${PROJECT}/REPORTS/PICARD_DUPLICATES/${SM_TAG}_MARK_DUPLICATES.txt \
				| awk 'BEGIN {FS=":"} \
					NR==2 \
					{print $1}')

	if
		[[ ! -f ${CORE_PATH}/${PROJECT}/REPORTS/PICARD_DUPLICATES/${SM_TAG}_MARK_DUPLICATES.txt ]]
	then
		echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	elif
		[[ -f ${CORE_PATH}/${PROJECT}/REPORTS/PICARD_DUPLICATES/${SM_TAG}_MARK_DUPLICATES.txt \
		&& ${MAX_RECORD} -lt 7 ]]; \
	then
		echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	else
		awk 'BEGIN {OFS="\t"} \
			NR>7&&NR<'$MAX_RECORD' \
			{if ($10!~/[0-9]/) \
				print $5,$8,"NaN","NaN",$4,$7,$3,"NaN",$6,$2,"NaN" ; \
			else if ($10~/[0-9]/&&$2=="0") \
				print $5,$8,$9*100,$10,$4,$7,$3,($7/$3),$6,$2,"NaN" ; \
			else \
				print $5,$8,$9*100,$10,$4,$7,$3,($7/$3),$6,$2,($6/$2)}' \
		${CORE_PATH}/${PROJECT}/REPORTS/PICARD_DUPLICATES/${SM_TAG}_MARK_DUPLICATES.txt \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				sum 1 \
				sum 2 \
				mean 4 \
				sum 5 \
				sum 6 \
				sum 7 \
				sum 9 \
				sum 10 \
			| awk 'BEGIN {OFS="\t"} \
				{if ($3!~/[0-9]/) \
					print $1,$2,"NaN","NaN",$4,$5,$6,"NaN",$7,$8,"NaN","NaN" ; \
				else if ($3~/[0-9]/&&$1=="0") \
					print $1,$2,(($7+($5*2))/($8+($6*2)))*100,$3,$4,$5,$6,($5/$6),$7,$8,\
						"NaN",($2/$6)*100 ; \
				else if ($3~/[0-9]/&&$1!="0"&&$8=="0") \
					print $1,$2,(($7+($5*2))/($8+($6*2)))*100,$3,$4,$5,$6,($5/$6),$7,$8,\
						"NaN",($2/$6)*100 ; \
				else \
					print $1,$2,(($7+($5*2))/($8+($6*2)))*100,$3,$4,$5,$6,($5/$6),$7,$8,\
						($7/$8),($2/$6)*100}' \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	fi

################################################################################################
### UMI REPORT #################################################################################
################################################################################################
### THIS IS THE HEADER #########################################################################
### "MEAN_UMI_LENGTH","OBSERVED_UNIQUE_UMIS","INFERRED_UNIQUE_UMIS","OBSERVED_BASE_ERRORS" #####
### "DUPLICATE_SETS_IGNORING_UMI","DUPLICATE_SETS_WITH_UMI","OBSERVED_UMI_ENTROPY", ############
### "INFERRED_UMI_ENTROPY","UMI_BASE_QUALITIES","PCT_UMI_WITH_N" ###############################
################################################################################################

	if
		[[ ! -f ${CORE_PATH}/${PROJECT}/REPORTS/PICARD_DUPLICATES/${SM_TAG}_UMI_METRICS.txt ]]
	then
		echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	else
		awk 'BEGIN {OFS="\t"} \
			NR==8 \
			{print $2,$3,$4,$5,$6,$7,$8,$9,$10,$11*100}' \
		${CORE_PATH}/${PROJECT}/REPORTS/PICARD_DUPLICATES/${SM_TAG}_UMI_METRICS.txt \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	fi

########################################################################################################
### HYBRIDIZATION SELECTION REPORT #####################################################################
########################################################################################################
### THIS IS THE HEADER #################################################################################
### "GENOME_SIZE","BAIT_TERRITORY","TARGET_TERRITORY","PCT_PF_UQ_READS_ALIGNED","PF_UQ_GIGS_ALIGNED" ###
### "PCT_SELECTED_BASES","ON_BAIT_VS_SELECTED","MEAN_TARGET_COVERAGE" ##################################
### "MEDIAN_TARGET_COVERAGE","MAX_TARGET_COVERAGE","ZERO_CVG_TARGETS_PCT","PCT_EXC_MAPQ" ###############
### "PCT_EXC_ADAPTER","PCT_EXC_BASEQ","PCT_EXC_OVERLAP","PCT_EXC_OFF_TARGET","FOLD_80_BASE_PENALTY" ####
### "PCT_TARGET_BASES_1X","PCT_TARGET_BASES_2X","PCT_TARGET_BASES_10X","PCT_TARGET_BASES_20X" ##########
### "PCT_TARGET_BASES_30X","PCT_TARGET_BASES_40X","PCT_TARGET_BASES_50X","PCT_TARGET_BASES_100X" #######
### "HS_LIBRARY_SIZE","AT_DROPOUT","GC_DROPOUT","THEORETICAL_HET_SENSITIVITY","HET_SNP_Q" ##############
### "BAIT_SET","PCT_USABLE_BASES_ON_BAIT" ##############################################################
########################################################################################################

	# this will take when there are no reads in the file...but i don't think that it will handle when there are reads, but none fall on target
	# the next time i that happens i'll fix this to handle it.

		if
			[[ ! -f ${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt ]]
		then
			echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
				| singularity exec ${ALIGNMENT_CONTAINER} datamash \
					transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
		else
			# grab field numbers for metrics and store a variables.

				BAIT_SET=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="BAIT_SET") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				BAIT_TERRITORY=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="BAIT_TERRITORY") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				PCT_SELECTED_BASES=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="PCT_SELECTED_BASES") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				ON_BAIT_VS_SELECTED=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="ON_BAIT_VS_SELECTED") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				PCT_USABLE_BASES_ON_BAIT=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="PCT_USABLE_BASES_ON_BAIT") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				HS_LIBRARY_SIZE=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="HS_LIBRARY_SIZE") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				TARGET_TERRITORY=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="TARGET_TERRITORY") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				GENOME_SIZE=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="GENOME_SIZE") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				PF_UQ_BASES_ALIGNED=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="PF_UQ_BASES_ALIGNED") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				PCT_PF_UQ_READS_ALIGNED=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="PCT_PF_UQ_READS_ALIGNED") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				MEAN_TARGET_COVERAGE=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="MEAN_TARGET_COVERAGE") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				MEDIAN_TARGET_COVERAGE=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="MEDIAN_TARGET_COVERAGE") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				MAX_TARGET_COVERAGE=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="MAX_TARGET_COVERAGE") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				ZERO_CVG_TARGETS_PCT=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="ZERO_CVG_TARGETS_PCT") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				PCT_EXC_ADAPTER=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="PCT_EXC_ADAPTER") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				PCT_EXC_MAPQ=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="PCT_EXC_MAPQ") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				PCT_EXC_BASEQ=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="PCT_EXC_BASEQ") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				PCT_EXC_OVERLAP=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="PCT_EXC_OVERLAP") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				PCT_EXC_OFF_TARGET=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="PCT_EXC_OFF_TARGET") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				FOLD_80_BASE_PENALTY=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="FOLD_80_BASE_PENALTY") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				PCT_TARGET_BASES_1X=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="PCT_TARGET_BASES_1X") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				PCT_TARGET_BASES_2X=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="PCT_TARGET_BASES_2X") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				PCT_TARGET_BASES_10X=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="PCT_TARGET_BASES_10X") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				PCT_TARGET_BASES_20X=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="PCT_TARGET_BASES_20X") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				PCT_TARGET_BASES_30X=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="PCT_TARGET_BASES_30X") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				PCT_TARGET_BASES_40X=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="PCT_TARGET_BASES_40X") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				PCT_TARGET_BASES_50X=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="PCT_TARGET_BASES_50X") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				PCT_TARGET_BASES_100X=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="PCT_TARGET_BASES_100X") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				AT_DROPOUT=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="AT_DROPOUT") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				GC_DROPOUT=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="GC_DROPOUT") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				HET_SNP_SENSITIVITY=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="HET_SNP_SENSITIVITY") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

				HET_SNP_Q=$(awk 'NR==7 {for (i=1; i<=NF; ++i) {if ($i=="HET_SNP_Q") print i}}' \
					${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt)

			# this was supposed to be
			## if there are no reads, then print x
			## if there are no reads in the target area, the print y
			## else the data is fine and do as you intended.
			## however i no longer have anything to test this on...

				awk \
					-v BAIT_SET="$BAIT_SET" \
					-v BAIT_TERRITORY="$BAIT_TERRITORY" \
					-v PCT_SELECTED_BASES="$PCT_SELECTED_BASES" \
					-v ON_BAIT_VS_SELECTED="$ON_BAIT_VS_SELECTED" \
					-v PCT_USABLE_BASES_ON_BAIT="$PCT_USABLE_BASES_ON_BAIT" \
					-v HS_LIBRARY_SIZE="$HS_LIBRARY_SIZE" \
					-v TARGET_TERRITORY="$TARGET_TERRITORY" \
					-v GENOME_SIZE="$GENOME_SIZE" \
					-v PF_UQ_BASES_ALIGNED="$PF_UQ_BASES_ALIGNED" \
					-v PCT_PF_UQ_READS_ALIGNED="$PCT_PF_UQ_READS_ALIGNED" \
					-v MEAN_TARGET_COVERAGE="$MEAN_TARGET_COVERAGE" \
					-v MEDIAN_TARGET_COVERAGE="$MEDIAN_TARGET_COVERAGE" \
					-v MAX_TARGET_COVERAGE="$MAX_TARGET_COVERAGE" \
					-v ZERO_CVG_TARGETS_PCT="$ZERO_CVG_TARGETS_PCT" \
					-v PCT_EXC_ADAPTER="$PCT_EXC_ADAPTER" \
					-v PCT_EXC_MAPQ="$PCT_EXC_MAPQ" \
					-v PCT_EXC_BASEQ="$PCT_EXC_BASEQ" \
					-v PCT_EXC_OVERLAP="$PCT_EXC_OVERLAP" \
					-v PCT_EXC_OFF_TARGET="$PCT_EXC_OFF_TARGET" \
					-v FOLD_80_BASE_PENALTY="$FOLD_80_BASE_PENALTY" \
					-v PCT_TARGET_BASES_1X="$PCT_TARGET_BASES_1X" \
					-v PCT_TARGET_BASES_2X="$PCT_TARGET_BASES_2X" \
					-v PCT_TARGET_BASES_10X="$PCT_TARGET_BASES_10X" \
					-v PCT_TARGET_BASES_20X="$PCT_TARGET_BASES_20X" \
					-v PCT_TARGET_BASES_30X="$PCT_TARGET_BASES_30X" \
					-v PCT_TARGET_BASES_40X="$PCT_TARGET_BASES_40X" \
					-v PCT_TARGET_BASES_50X="$PCT_TARGET_BASES_50X" \
					-v PCT_TARGET_BASES_100X="$PCT_TARGET_BASES_100X" \
					-v AT_DROPOUT="$AT_DROPOUT" \
					-v GC_DROPOUT="$GC_DROPOUT" \
					-v HET_SNP_SENSITIVITY="$HET_SNP_SENSITIVITY" \
					-v HET_SNP_Q="$HET_SNP_Q" \
				'BEGIN {FS="\t";OFS="\t"} \
					NR==8 \
					{if ($PCT_PF_UQ_READS_ALIGNED=="?"&&$HS_LIBRARY_SIZE=="") \
					print $GENOME_SIZE,$BAIT_TERRITORY,$TARGET_TERRITORY,"NaN",\
						($PF_UQ_BASES_ALIGNED/1000000000),"NaN","NaN",\
						$MEAN_TARGET_COVERAGE,$MEDIAN_TARGET_COVERAGE,$MAX_TARGET_COVERAGE,\
						$ZERO_CVG_TARGETS_PCT*100,"NaN","NaN","NaN",\
						"NaN","NaN","NaN",\
						$PCT_TARGET_BASES_1X*100,$PCT_TARGET_BASES_2X*100,$PCT_TARGET_BASES_10X*100,\
						$PCT_TARGET_BASES_20X*100,$PCT_TARGET_BASES_30X*100,$PCT_TARGET_BASES_40X*100,\
						$PCT_TARGET_BASES_50X*100,$PCT_TARGET_BASES_100X*100,"NaN",$AT_DROPOUT,\
						$GC_DROPOUT,$HET_SNP_SENSITIVITY,$HET_SNP_Q,$BAIT_SET,"NaN" ; \
					else if ($PCT_PF_UQ_READS_ALIGNED!="?"&&$HS_LIBRARY_SIZE=="") \
					print $GENOME_SIZE,$BAIT_TERRITORY,$TARGET_TERRITORY,$PCT_PF_UQ_READS_ALIGNED*100,\
						($PF_UQ_BASES_ALIGNED/1000000000),$PCT_SELECTED_BASES*100,$ON_BAIT_VS_SELECTED,\
						$MEAN_TARGET_COVERAGE,$MEDIAN_TARGET_COVERAGE,$MAX_TARGET_COVERAGE,\
						$ZERO_CVG_TARGETS_PCT*100,$PCT_EXC_MAPQ*100,$PCT_EXC_BASEQ*100,$PCT_EXC_OVERLAP*100,\
						$PCT_EXC_OFF_TARGET*100,$PCT_EXC_ADAPTER,$FOLD_80_BASE_PENALTY,\
						$PCT_TARGET_BASES_1X*100,$PCT_TARGET_BASES_2X*100,$PCT_TARGET_BASES_10X*100,\
						$PCT_TARGET_BASES_20X*100,$PCT_TARGET_BASES_30X*100,$PCT_TARGET_BASES_40X*100,\
						$PCT_TARGET_BASES_50X*100,$PCT_TARGET_BASES_100X*100,"NaN",$AT_DROPOUT,\
						$GC_DROPOUT,$HET_SNP_SENSITIVITY,$HET_SNP_Q,$BAIT_SET,$PCT_USABLE_BASES_ON_BAIT*100 ; \
					else \
					print $GENOME_SIZE,$BAIT_TERRITORY,$TARGET_TERRITORY,$PCT_PF_UQ_READS_ALIGNED*100,\
						($PF_UQ_BASES_ALIGNED/1000000000),$PCT_SELECTED_BASES*100,$ON_BAIT_VS_SELECTED,\
						$MEAN_TARGET_COVERAGE,$MEDIAN_TARGET_COVERAGE,$MAX_TARGET_COVERAGE,\
						$ZERO_CVG_TARGETS_PCT*100,$PCT_EXC_MAPQ*100,$PCT_EXC_BASEQ*100,$PCT_EXC_OVERLAP*100,\
						$PCT_EXC_OFF_TARGET*100,$PCT_EXC_ADAPTER,$FOLD_80_BASE_PENALTY,\
						$PCT_TARGET_BASES_1X*100,$PCT_TARGET_BASES_2X*100,$PCT_TARGET_BASES_10X*100,\
						$PCT_TARGET_BASES_20X*100,$PCT_TARGET_BASES_30X*100,$PCT_TARGET_BASES_40X*100,\
						$PCT_TARGET_BASES_50X*100,$PCT_TARGET_BASES_100X*100,$HS_LIBRARY_SIZE,$AT_DROPOUT,\
						$GC_DROPOUT,$HET_SNP_SENSITIVITY,$HET_SNP_Q,$BAIT_SET,$PCT_USABLE_BASES_ON_BAIT*100}' \
				${CORE_PATH}/${PROJECT}/REPORTS/HYB_SELECTION/${SM_TAG}_hybridization_selection_metrics.txt \
					| singularity exec ${ALIGNMENT_CONTAINER} datamash \
						transpose \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
		fi

##########################################
### BAIT BIAS REPORT FOR Cref and Gref ###
##########################################
### THIS IS THE HEADER ###################
### "Cref_Q","Gref_Q" ####################
##########################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/REPORTS/BAIT_BIAS/SUMMARY/${SM_TAG}.bait_bias_summary_metrics.txt ]]
	then
		echo -e NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	else
		grep -v "^#" ${CORE_PATH}/${PROJECT}/REPORTS/BAIT_BIAS/SUMMARY/${SM_TAG}.bait_bias_summary_metrics.txt \
			| sed '/^$/d' \
			| awk 'BEGIN {OFS="\t"} \
				$12=="Cref"||$12=="Gref" \
				{print $5}' \
			| paste - - \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				collapse 1 \
				collapse 2 \
			| sed 's/,/;/g' \
			| awk 'BEGIN {OFS="\t"} \
				{print $0}' \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	fi

########################################################
### PRE-ADAPTER BIAS REPORT FOR Deamination and OxoG ###
########################################################
### THIS IS THE HEADER #################################
### "Deamination_Q","OxoG_Q" ###########################
########################################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/REPORTS/PRE_ADAPTER/SUMMARY/${SM_TAG}.pre_adapter_summary_metrics.txt ]]
	then
		echo -e NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
			transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	else
		grep -v "^#" ${CORE_PATH}/${PROJECT}/REPORTS/PRE_ADAPTER/SUMMARY/${SM_TAG}.pre_adapter_summary_metrics.txt \
			| sed '/^$/d' \
			| awk 'BEGIN {OFS="\t"} \
				$12=="Deamination"||$12=="OxoG" \
				{print $5}' \
			| paste - - \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash collapse 1 collapse 2 \
			| sed 's/,/;/g' \
			| awk 'BEGIN {OFS="\t"} {print $0}' \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	fi

#######################################################
### BASE DISTRIBUTION REPORT AVERAGE FROM PER CYCLE ###
#######################################################
### THIS IS THE HEADER ################################
### "PCT_A","PCT_C","PCT_G","PCT_T","PCT_N" ###########
#######################################################

	BASE_DISTIBUTION_BY_CYCLE_ROW_COUNT=$(wc -l ${CORE_PATH}/${PROJECT}/REPORTS/BASE_DISTRIBUTION_BY_CYCLE/METRICS/${SM_TAG}.base_distribution_by_cycle_metrics.txt \
			| awk '{print $1}')

	if
		[[ ! -f ${CORE_PATH}/${PROJECT}/REPORTS/BASE_DISTRIBUTION_BY_CYCLE/METRICS/${SM_TAG}.base_distribution_by_cycle_metrics.txt ]]
	then
		echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	elif
		[[ -f ${CORE_PATH}/${PROJECT}/REPORTS/BASE_DISTRIBUTION_BY_CYCLE/METRICS/${SM_TAG}.base_distribution_by_cycle_metrics.txt \
			&& ${BASE_DISTIBUTION_BY_CYCLE_ROW_COUNT} -lt 8 ]]
	then
		echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	else
		sed '/^$/d' ${CORE_PATH}/${PROJECT}/REPORTS/BASE_DISTRIBUTION_BY_CYCLE/METRICS/${SM_TAG}.base_distribution_by_cycle_metrics.txt \
			| awk 'NR>6' \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				mean 3 \
				mean 4 \
				mean 5 \
				mean 6 \
				mean 7 \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	fi

##############################################
### BASE SUBSTITUTION RATE ###################
##############################################
### THIS IS THE HEADER #######################
### "PCT_A_to_C","PCT_A_to_G","PCT_A_to_T" ###
### "PCT_C_to_A","PCT_C_to_G","PCT_C_to_T" ###
##############################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/REPORTS/ERROR_SUMMARY/${SM_TAG}.error_summary_metrics.txt ]]
	then
		echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	else
		sed '/^$/d' ${CORE_PATH}/${PROJECT}/REPORTS/ERROR_SUMMARY/${SM_TAG}.error_summary_metrics.txt \
			| awk 'NR>6 \
				{print $6*100}' \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	fi

################################################################################################
### VCF METRICS FOR BAIT BED FILE ##############################################################
################################################################################################
### THIS IS THE HEADER #########################################################################
### "BAIT_HET_HOMVAR_RATIO","BAIT_PCT_GQ0_VARIANT","BAIT_TOTAL_GQ0_VARIANT" ####################
### "BAIT_TOTAL_HET_DEPTH_SNV","BAIT_TOTAL_SNV","BAIT_NUM_IN_DBSNP_138_SNV","BAIT_NOVEL_SNV" ###
### "BAIT_FILTERED_SNV","BAIT_PCT_DBSNP_138_SNV","BAIT_TOTAL_INDEL","BAIT_NOVEL_INDEL" #########
### "BAIT_FILTERED_INDEL","BAIT_PCT_DBSNP_138_INDEL","BAIT_NUM_IN_DBSNP_138_INDEL" #############
### "BAIT_DBSNP_138_INS_DEL_RATIO","BAIT_NOVEL_INS_DEL_RATIO","BAIT_TOTAL_MULTIALLELIC_SNV" ####
### "BAIT_NUM_IN_DBSNP_138_MULTIALLELIC_SNV","BAIT_TOTAL_COMPLEX_INDEL" ########################
### "BAIT_NUM_IN_DBSNP_138_COMPLEX_INDEL","BAIT_SNP_REFERENCE_BIAS","BAIT_NUM_SINGLETONS" ######
################################################################################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/REPORTS/VCF_METRICS/SINGLE_SAMPLE/BAIT/${SM_TAG}_BAIT.variant_calling_detail_metrics.txt ]]
	then
		echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	else
		awk 'BEGIN {OFS="\t"} \
			$1=="'${SM_TAG}'" \
			{print $2,$3*100,$4,$5,$6,$7,$8,$9,$10*100,$13,$14,$15,$16*100,\
				$17,$18,$19,$20,$21,$22,$23,$24,$25}' \
		${CORE_PATH}/${PROJECT}/REPORTS/VCF_METRICS/SINGLE_SAMPLE/BAIT/${SM_TAG}_BAIT.variant_calling_detail_metrics.txt \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	fi

#####################################################################################################
### VCF METRICS FOR TARGET BED FILE #################################################################
#####################################################################################################
### THIS IS THE HEADER ##############################################################################
### "TARGET_HET_HOMVAR_RATIO","TARGET_PCT_GQ0_VARIANT","TARGET_TOTAL_GQ0_VARIANT" ###################
### "TARGET_TOTAL_HET_DEPTH_SNV","TARGET_TOTAL_SNV","TARGET_NUM_IN_DBSNP_138_SNV" ###################
### "TARGET_NOVEL_SNV","TARGET_FILTERED_SNV","TARGET_PCT_DBSNP_138_SNV","TARGET_TOTAL_INDEL" ########
### "TARGET_NOVEL_INDEL","TARGET_FILTERED_INDEL","TARGET_PCT_DBSNP_138_INDEL" #######################
### "TARGET_NUM_IN_DBSNP_138_INDEL","TARGET_DBSNP_138_INS_DEL_RATIO","TARGET_NOVEL_INS_DEL_RATIO" ###
### "TARGET_TOTAL_MULTIALLELIC_SNP","TARGET_NUM_IN_DBSNP_138_MULTIALLELIC" ##########################
### "TARGET_TOTAL_COMPLEX_INDELS,"TARGET_NUM_IN_DBSNP_138_COMPLEX_INDEL" ############################
### "TARGET_SNP_REFERENCE_BIAS","TARGET_NUM_SINGLETONS" #############################################
#####################################################################################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/REPORTS/VCF_METRICS/SINGLE_SAMPLE/TARGET/${SM_TAG}_TARGET.variant_calling_detail_metrics.txt ]]
	then
		echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	else
		awk 'BEGIN {OFS="\t"} \
			$1=="'${SM_TAG}'" \
			{print $2,$3*100,$4,$5,$6,$7,$8,$9,$10*100,$13,$14,$15,$16*100,\
				$17,$18,$19,$20,$21,$22,$23,$24,$25}' \
			${CORE_PATH}/${PROJECT}/REPORTS/VCF_METRICS/SINGLE_SAMPLE/TARGET/${SM_TAG}_TARGET.variant_calling_detail_metrics.txt \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	fi

########################################################################################################
### VCF METRICS FOR TITV BED FILE ######################################################################
########################################################################################################
### THIS IS THE HEADER #################################################################################
### "CODING_HET_HOMVAR_RATIO","CODING_PCT_GQ0_VARIANT","CODING_TOTAL_GQ0_VARIANT" ######################
### "CODING_TOTAL_HET_DEPTH_SNV","CODING_TOTAL_SNV","CODING_NUM_IN_DBSNP_129_SNV","CODING_NOVEL_SNV" ###
### "CODING_FILTERED_SNV","CODING_PCT_DBSNP_129_SNV","CODING_DBSNP_129_TITV" ###########################
### "CODING_NOVEL_TITV","CODING_TOTAL_INDEL","CODING_NOVEL_INDEL","CODING_FILTERED_INDEL" ##############
### "CODING_PCT_DBSNP_129_INDEL","CODING_NUM_IN_DBSNP_129_INDEL","CODING_DBSNP_129_INS_DEL_RATIO" ######
### "CODING_NOVEL_INS_DEL_RATIO","CODING_TOTAL_MULTIALLELIC_SNV" #######################################
### "CODING_NUM_IN_DBSNP_129_MULTIALLELIC_SNV","CODING_TOTAL_COMPLEX_INDEL" ############################
### "CODING_NUM_IN_DBSNP_129_COMPLEX_INDEL","CODING_SNP_REFERENCE_BIAS","CODING_NUM_SINGLETONS" ########
########################################################################################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/REPORTS/VCF_METRICS/SINGLE_SAMPLE/TITV/${SM_TAG}_TITV.variant_calling_detail_metrics.txt ]]
	then
		echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	else
		awk 'BEGIN {OFS="\t"} \
			$1=="'${SM_TAG}'" \
			{print $2,$3*100,$4,$5,$6,$7,$8,$9,$10*100,$11,$12,$13,$14,$15,$16*100,\
				$17,$18,$19,$20,$21,$22,$23,$24,$25}' \
			${CORE_PATH}/${PROJECT}/REPORTS/VCF_METRICS/SINGLE_SAMPLE/TITV/${SM_TAG}_TITV.variant_calling_detail_metrics.txt \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt
	fi

####################################################################################
### see how many libraries are in the samples ######################################
### not sure if I should be testing this against the cram header, rg header stub ###
### I think that there are going to be caveats no matter how i do it ###############
####################################################################################

	MULTIPLE_LIBRARY=$(grep -v "^#" ${CORE_PATH}/${PROJECT}/REPORTS/BAIT_BIAS/SUMMARY/${SM_TAG}.bait_bias_summary_metrics.txt \
		| sed '/^$/d' \
		| awk 'BEGIN {OFS="\t"} \
			$12=="Cref"||$12=="Gref" \
			{print $5}' \
		| paste - - \
		| awk 'END {print NR}')

		# if exit does not equal 0 then exit with whatever the exit signal is at the end.

			if [[ ${MULTIPLE_LIBRARY} -eq 0 ]]
			then
				echo ${SM_TAG} \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_TOTAL_FAILURES.txt
			elif [[ ${MULTIPLE_LIBRARY} -gt 1 ]]
			then
				grep -v ^# ${CORE_PATH}/${PROJECT}/REPORTS/BAIT_BIAS/SUMMARY/${SM_TAG}.bait_bias_summary_metrics.txt \
					| sed '/^$/d' \
					| awk 'NR>1 \
						{print $1 "\t" $2}' \
					| sort \
					| uniq \
					| singularity exec ${ALIGNMENT_CONTAINER} datamash \
						-g 1 \
						collapse 2 \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_MULTIPLE_LIBS.txt
			fi

##################################
### tranpose from rows to list ###
##################################

	cat ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_REPORT_TEMP.txt \
		| singularity exec ${ALIGNMENT_CONTAINER} datamash \
			transpose \
	>| ${CORE_PATH}/${PROJECT}/REPORTS/QC_REPORT_PREP/${SM_TAG}.QC_REPORT_PREP.txt

###########################################
### check the exit signal at this point ###
###########################################

	SCRIPT_STATUS=`echo $?`

	# -eq and -ne are used for integer comparisons
	# = and != are string comparisons

	# if exit does not equal 0 then exit with whatever the exit signal is at the end.
	# if the exit does equal zero then check to see if there is only one library, if so then exit 0
	# if exit is zero and there is multiple libraries then exit = 3. this will get pushed out to the sge accounting db so that 
		# there is an indication that there are multiple libraries, which could be due to a sample sheet screw-up.
	# a sample with a total failure should receive and exit status of 4

			if [ "${SCRIPT_STATUS}" -ne 0 ]
			then
				exit ${SCRIPT_STATUS}
			elif [ "${MULTIPLE_LIBRARY}" -eq 1 ]
			then
				exit 0
			elif [ "${MULTIPLE_LIBRARY}" -eq 0 ]
			then
				# total failures get an exit code of 4
				exit 4
			else
				# multiple libraries get an exit code of 3
				exit 3
			fi
