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
	TUMOR_SM_TAG=$6
	NORMAL_SM_TAG=$7
	REF_GENOME=$8
	ALLELE_FRACTION_CUTOFF=$9
	SUBMIT_STAMP=${10}

## RUN FILTER MUTECT CALLS

START_FILTER_MUTECT2=$(date '+%s') # capture time process starts for wall clock tracking purposes.

	# construct command line

		CMD="singularity exec ${UMI_CONTAINER} java -jar"
			CMD=${CMD}" /gatk/gatk.jar"
		CMD=${CMD}" FilterMutectCalls"
			CMD=${CMD}" --reference ${REF_GENOME}"
			CMD=${CMD}" --variant ${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${NORMAL_SM_TAG}_MUTECT2_RAW.vcf.gz"
			CMD=${CMD}" --ob-priors ${CORE_PATH}/${TUMOR_PROJECT}/VCF/MUTECT2/READ_ORIENT_MODEL/${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${NORMAL_SM_TAG}_MUTECT2_FIR2.tar.gz"
			CMD=${CMD}" --stats ${CORE_PATH}/${TUMOR_PROJECT}/VCF/MUTECT2/STATS/${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${NORMAL_SM_TAG}_MUTECT2.stats"
			CMD=${CMD}" --tumor-segmentation  ${CORE_PATH}/${TUMOR_PROJECT}/REPORTS/GATK_CALC_TUMOR_CONTAM/${TUMOR_SM_TAG}.segments.table"
			CMD=${CMD}" --contamination-table ${CORE_PATH}/${TUMOR_PROJECT}/REPORTS/GATK_CALC_TUMOR_CONTAM/${TUMOR_SM_TAG}.calculatetumorcontamination.table"
			CMD=${CMD}" --min-allele-fraction ${ALLELE_FRACTION_CUTOFF}"
		CMD=${CMD}" --output ${CORE_PATH}/${TUMOR_PROJECT}/VCF/MUTECT2/${TUMOR_INDIVIDUAL}_${NORMAL_SM_TAG}_${TUMOR_SM_TAG}_MUTECT2.FILTERED.vcf.gz"

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

END_FILTER_MUTECT2=$(date '+%s') # capture time process starts for wall clock tracking purposes.

# write out timing metrics to file

	echo ${TUMOR_INDIVIDUAL}_${TUMOR_PROJECT}_${TUMOR_SM_TAG}_${NORMAL_SM_TAG},D01,FILTER_MUTECT2,${HOSTNAME},${START_FILTER_MUTECT2},${END_FILTER_MUTECT2} \
	>> ${CORE_PATH}/${TUMOR_PROJECT}/REPORTS/${TUMOR_PROJECT}_PAIRED_CALLING_WALL_CLOCK_TIMES.csv

# exit with the signal from samtools bam to cram

	exit ${SCRIPT_STATUS}
