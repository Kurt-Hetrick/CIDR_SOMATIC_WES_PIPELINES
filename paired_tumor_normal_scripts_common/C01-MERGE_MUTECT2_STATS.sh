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
	ALIGNMENT_CONTAINER=$2
	QC_REPORT=$3
		QC_REPORT_NAME=$(basename ${QC_REPORT} .csv)
	CORE_PATH=$4
	TUMOR_PROJECT=$5
	TUMOR_INDIVIDUAL=$6
	TUMOR_SM_TAG=$7
	NORMAL_SM_TAG=$8
	BAIT_BED=$9
	SUBMIT_STAMP=${10}

## MERGE MUTECT2 STATS FILES TO BE USED IN FILTERING LATER

START_MERGE_MUTECT2_STATS=$(date '+%s') # capture time process starts for wall clock tracking purposes.

	# construct command line

		CMD="singularity exec ${UMI_CONTAINER} java -jar"
			CMD=${CMD}" /gatk/gatk.jar"
		CMD=${CMD}" MergeMutectStats"

		# loop through natural sorted chromosome list to concatentate gvcf files.

		for CHROMOSOME in $(sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' ${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${NORMAL_SM_TAG}_${BAIT_BED}.bed \
				| sed -r 's/[[:space:]]+/\t/g' \
				| sed 's/chr//g' \
				| egrep "^[0-9]|^X|^Y" \
				| cut -f 1 \
				| sort -V \
				| uniq \
				| awk '{print "chr"$1}' \
				| singularity exec ${ALIGNMENT_CONTAINER} datamash \
					collapse 1 \
				| sed 's/,/ /g');
		do
			CMD=${CMD}" --stats ${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${NORMAL_SM_TAG}_MUTECT2.${CHROMOSOME}.vcf.gz.stats"
		done

		CMD=${CMD}" --output ${CORE_PATH}/${TUMOR_PROJECT}/VCF/MUTECT2/STATS/${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${NORMAL_SM_TAG}_MUTECT2.stats"

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

END_MERGE_MUTECT2_STATS=$(date '+%s') # capture time process ends for wall clock tracking purposes.

# write out timing metrics to file

	echo ${TUMOR_INDIVIDUAL}_${TUMOR_PROJECT}_${TUMOR_SM_TAG}_${NORMAL_SM_TAG},C01,MERGE_MUTECT2_STATS,${HOSTNAME},${START_MERGE_MUTECT2_STATS},${END_MERGE_MUTECT2_STATS} \
	>> ${CORE_PATH}/${TUMOR_PROJECT}/REPORTS/${TUMOR_PROJECT}_PAIRED_CALLING_WALL_CLOCK_TIMES.csv

# exit with the signal from samtools bam to cram

	exit ${SCRIPT_STATUS}
