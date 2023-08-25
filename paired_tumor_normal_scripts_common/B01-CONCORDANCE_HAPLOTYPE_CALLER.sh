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

	UMI_CONTAINER=$1
	QC_REPORT=$2
		QC_REPORT_NAME=$(basename ${QC_REPORT} .csv)
	CORE_PATH=$3
	TUMOR_PROJECT=$4
	TUMOR_INDIVIDUAL=$5
		NORMAL_SUBJECT_ID=$(echo ${TUMOR_INDIVIDUAL}_N)
	TUMOR_SM_TAG=$6
	TARGET_BED=$7
		TARGET_BED_NAME=$(basename ${TARGET_BED} .bed)
	SUBMIT_STAMP=$8

# GRAB NORMAL SM TAG, PROJECT FROM QC REPORT

	PROJECT_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="PROJECT") print i}}' ${QC_REPORT})

	SUBJECT_ID_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="Subject_ID") print i}}' ${QC_REPORT})

	SM_TAG_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="SM_TAG") print i}}' ${QC_REPORT})

		NORMAL_SM_TAG=$(awk \
			-v PROJECT_COLUMN_POSITION="$PROJECT_COLUMN_POSITION" \
			-v SUBJECT_ID_COLUMN_POSITION="$SUBJECT_ID_COLUMN_POSITION" \
			-v SM_TAG_COLUMN_POSITION="$SM_TAG_COLUMN_POSITION" \
			'BEGIN {FS=",";OFS="\t"} \
			$SUBJECT_ID_COLUMN_POSITION=="'${NORMAL_SUBJECT_ID}'" \
			{print $SM_TAG_COLUMN_POSITION}' \
		${QC_REPORT} \
			| sort \
			| uniq)

		NORMAL_PROJECT=$(awk \
			-v PROJECT_COLUMN_POSITION="$PROJECT_COLUMN_POSITION" \
			-v SUBJECT_ID_COLUMN_POSITION="$SUBJECT_ID_COLUMN_POSITION" \
			-v SM_TAG_COLUMN_POSITION="$SM_TAG_COLUMN_POSITION" \
			'BEGIN {FS=",";OFS="\t"} \
			$SUBJECT_ID_COLUMN_POSITION=="'${NORMAL_SUBJECT_ID}'" \
			{print $PROJECT_COLUMN_POSITION}' \
		${QC_REPORT} \
			| sort \
			| uniq)

## DO CONCORDANCE BETWEEN THE SEQUENCING QC VCFs FROM THE TUMOR TO IT'S MATCHED NORMAL

START_HAPLOTYPE_CALLER_CONCORDANCE=$(date '+%s') # capture time process starts for wall clock tracking purposes.

	# construct command line
	# note that the bed file here is not a bed file b/c it is 1-based. so that's neat.

		CMD="singularity exec ${UMI_CONTAINER} java -jar"
			CMD=${CMD}" /picard/picard.jar"
		CMD=${CMD}" GenotypeConcordance"
			CMD=${CMD}" TRUTH_VCF=${CORE_PATH}/${NORMAL_PROJECT}/VCF/SINGLE_SAMPLE/${NORMAL_SM_TAG}.QC.vcf.gz"
			CMD=${CMD}" TRUTH_SAMPLE=${NORMAL_SM_TAG}"
			CMD=${CMD}" CALL_VCF=${CORE_PATH}/${TUMOR_PROJECT}/VCF/SINGLE_SAMPLE/${TUMOR_SM_TAG}.QC.vcf.gz"
			CMD=${CMD}" CALL_SAMPLE=${TUMOR_SM_TAG}"
		CMD=${CMD}" INTERVALS=${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}-${TUMOR_SM_TAG}-${TARGET_BED}-picard.bed"
		CMD=${CMD}" O=${CORE_PATH}/${TUMOR_PROJECT}/REPORTS/CONCORDANCE_PAIRED/${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${NORMAL_SM_TAG}_TARGET"

	# write command line to file and execute the command line

		echo ${CMD} >> ${CORE_PATH}/${TUMOR_PROJECT}/COMMAND_LINES/${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${NORMAL_SM_TAG}_command_lines.txt
		echo >> ${CORE_PATH}/${TUMOR_PROJECT}/COMMAND_LINES/${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${NORMAL_SM_TAG}_command_lines.txt
		echo ${CMD} | bash

	# check the exit signal at this point.

		SCRIPT_STATUS=$(echo $?)

		# if exit does not equal 0 then exit with whatever the exit signal is at the end.
		# also write to file that this job failed

			if
				[ "${SCRIPT_STATUS}" -ne 0 ]
			then
				echo ${TUMOR_INDIVIDUAL} ${TUMOR_SM_TAG} ${NORMAL_SM_TAG} ${HOSTNAME} ${JOB_NAME} ${USER} ${SCRIPT_STATUS} ${SGE_STDERR_PATH} \
				>> ${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}_${SUBMIT_STAMP}_ERRORS.txt
				exit ${SCRIPT_STATUS}
			fi

END_HAPLOTYPE_CALLER_CONCORDANCE=$(date '+%s') # capture time process ends for wall clock tracking purposes.

# write out timing metrics to file

	echo ${TUMOR_INDIVIDUAL}_${TUMOR_PROJECT}_${TUMOR_SM_TAG}_${NORMAL_SM_TAG},B01,HAPLOTYPE_CALLER_CONCORDANCE,${HOSTNAME},${START_HAPLOTYPE_CALLER_CONCORDANCE},${END_HAPLOTYPE_CALLER_CONCORDANCE} \
	>> ${CORE_PATH}/${TUMOR_PROJECT}/REPORTS/${TUMOR_PROJECT}_PAIRED_CALLING_WALL_CLOCK_TIMES.csv

# exit with the signal from samtools bam to cram

	exit ${SCRIPT_STATUS}
