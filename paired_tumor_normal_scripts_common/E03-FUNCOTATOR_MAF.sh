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
	REF_GENOME=$7
	FUNCOTATOR_DATASOURCE=$8
	SUBMIT_STAMP=$9

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

## RUN MUTECT2

START_FUNCOTATOR_MAF=$(date '+%s') # capture time process starts for wall clock tracking purposes.

	# construct command line

		CMD="singularity exec ${UMI_CONTAINER} java -jar"
			CMD=${CMD}" /gatk/gatk.jar"
		CMD=${CMD}" Funcotator"
			CMD=${CMD}" --reference ${REF_GENOME}"
			CMD=${CMD}" --ref-version hg38"
			CMD=${CMD}" --variant ${CORE_PATH}/${TUMOR_PROJECT}/VCF/MUTECT2/${TUMOR_INDIVIDUAL}_${NORMAL_SM_TAG}_${TUMOR_SM_TAG}_MUTECT2.FILTERED.vcf.gz"
			CMD=${CMD}" --remove-filtered-variants"
			CMD=${CMD}" --data-sources-path ${FUNCOTATOR_DATASOURCE}"
			CMD=${CMD}" --output-file-format MAF"
		CMD=${CMD}" --output  ${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}_${NORMAL_SM_TAG}_${TUMOR_SM_TAG}_FUNCOTATOR.maf"

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

	# modify MAF so that the tumor and subject ID fields are populated with the appropriate SM tags

		(grep "^#" \
			${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}_${NORMAL_SM_TAG}_${TUMOR_SM_TAG}_FUNCOTATOR.maf ; \
		grep -m 1 "^Hugo_Symbol" \
		${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}_${NORMAL_SM_TAG}_${TUMOR_SM_TAG}_FUNCOTATOR.maf ; \
		egrep -v "^#|^Hugo_Symbol" \
		${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}_${NORMAL_SM_TAG}_${TUMOR_SM_TAG}_FUNCOTATOR.maf \
			| awk 'BEGIN {FS="\t";OFS="\t"} {$16="'${TUMOR_SM_TAG}'";$17="'${NORMAL_SM_TAG}'";}1') \
		>| ${CORE_PATH}/${TUMOR_PROJECT}/REPORTS/MAF/${TUMOR_INDIVIDUAL}_${NORMAL_SM_TAG}_${TUMOR_SM_TAG}_FUNCOTATOR.maf

END_FUNCOTATOR_MAF=$(date '+%s') # capture time process starts for wall clock tracking purposes.

# write out timing metrics to file

	echo ${TUMOR_INDIVIDUAL}_${TUMOR_PROJECT}_${TUMOR_SM_TAG}_${NORMAL_SM_TAG},D01,FUNCOTATOR_MAF,${HOSTNAME},${START_FUNCOTATOR_MAF},${END_FUNCOTATOR_MAF} \
	>> ${CORE_PATH}/${TUMOR_PROJECT}/REPORTS/${TUMOR_PROJECT}_PAIRED_CALLING_WALL_CLOCK_TIMES.csv

# exit with the signal from samtools bam to cram

	exit ${SCRIPT_STATUS}
