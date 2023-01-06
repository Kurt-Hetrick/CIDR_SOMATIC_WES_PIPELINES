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
	CORE_PATH=$2

	PROJECT=$3
	SM_TAG=$4
	REF_DICT=$5
	DBSNP_129=$6
	TITV_BED=$7
		TITV_BED_NAME=$(basename ${TITV_BED} .bed)
	SAMPLE_SHEET=$8
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$9

# FILTER INDEL AND MIXED VARIANTS

START_VCF_METRICS_TITV=`date '+%s'` # capture time process starts for wall clock tracking purposes.

	# construct command line

		CMD="singularity exec ${ALIGNMENT_CONTAINER} java -jar"
			CMD=${CMD}" /gatk/gatk.jar"
		CMD=${CMD}" CollectVariantCallingMetrics"
			CMD=${CMD}" --SEQUENCE_DICTIONARY ${REF_DICT}"
			CMD=${CMD}" --DBSNP ${DBSNP_129}"
			CMD=${CMD}" --THREAD_COUNT 4"
			CMD=${CMD}" --TARGET_INTERVALS $CORE_PATH/$PROJECT/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${TITV_BED_NAME}-picard.bed"
			CMD=${CMD}" --INPUT ${CORE_PATH}/${PROJECT}/VCF/SINGLE_SAMPLE/${SM_TAG}.QC.vcf.gz"
		CMD=${CMD}" --OUTPUT ${CORE_PATH}/${PROJECT}/REPORTS/VCF_METRICS/SINGLE_SAMPLE/TITV/${SM_TAG}_TITV"
		CMD=${CMD}" &&"
		CMD=${CMD}" mv -v"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/VCF_METRICS/SINGLE_SAMPLE/TITV/${SM_TAG}_TITV.variant_calling_detail_metrics"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/VCF_METRICS/SINGLE_SAMPLE/TITV/${SM_TAG}_TITV.variant_calling_detail_metrics.txt"
		CMD=${CMD}" &&"
		CMD=${CMD}" mv -v"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/VCF_METRICS/SINGLE_SAMPLE/TITV/${SM_TAG}_TITV.variant_calling_summary_metrics"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/VCF_METRICS/SINGLE_SAMPLE/TITV/${SM_TAG}_TITV.variant_calling_summary_metrics.txt"

	# write command line to file and execute the command line

		echo ${CMD} >> ${CORE_PATH}/${PROJECT}/COMMAND_LINES/${SM_TAG}_command_lines.txt
		echo >> ${CORE_PATH}/${PROJECT}/COMMAND_LINES/${SM_TAG}_command_lines.txt
		echo ${CMD} | bash

	# check the exit signal at this point.

		SCRIPT_STATUS=`echo $?`

		# if exit does not equal 0 then exit with whatever the exit signal is at the end.
		# also write to file that this job failed

			if [ "${SCRIPT_STATUS}" -ne 0 ]
				then
					echo ${SM_TAG} ${HOSTNAME} ${JOB_NAME} ${USER} ${SCRIPT_STATUS} ${SGE_STDERR_PATH} \
					>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt
					exit ${SCRIPT_STATUS}
			fi

END_VCF_METRICS_TITV=`date '+%s'` # capture time process stops for wall clock tracking purposes.

# write out timing metrics to file

	echo ${SM_TAG},K01,VCF_METRICS_TITV,${HOSTNAME},${START_VCF_METRICS_TITV},${END_VCF_METRICS_TITV} \
	>> ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.csv

# exit with the signal from the program

	exit ${SCRIPT_STATUS}
