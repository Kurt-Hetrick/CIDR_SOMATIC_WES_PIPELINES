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
	REF_GENOME=$5
	DBSNP=$6
	TARGET_BED=$7
		TARGET_BED_NAME=$(basename ${TARGET_BED} .bed)
	SAMPLE_SHEET=$8
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$9

# Start running Many Picard sequencing metrics for the QC report

START_COLLECT_MULTIPLE_METRICS=`date '+%s'` # capture time process starts for wall clock tracking purposes.

	# construct command line

		CMD="singularity exec ${ALIGNMENT_CONTAINER} java -jar"
			CMD=${CMD}" /gatk/picard.jar"
		CMD=${CMD}" CollectMultipleMetrics"
			CMD=${CMD}" INPUT=${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram"
			CMD=${CMD}" REFERENCE_SEQUENCE=${REF_GENOME}"
			CMD=${CMD}" DB_SNP=${DBSNP}"
			CMD=${CMD}" INTERVALS=${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${TARGET_BED_NAME}-picard.bed"
			CMD=${CMD}" PROGRAM=CollectGcBiasMetrics"
			CMD=${CMD}" PROGRAM=CollectSequencingArtifactMetrics"
			CMD=${CMD}" PROGRAM=CollectQualityYieldMetrics"
		CMD=${CMD}" OUTPUT=${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}"
		##### MOVE AND RENAME OUTPUTS
		# Move and rename bait bais metrics/summary files to the reports directory and add a txt extension
		CMD=${CMD}" &&"
			CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.bait_bias_detail_metrics"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/BAIT_BIAS/METRICS/${SM_TAG}.bait_bias_detail_metrics.txt"
		CMD=${CMD}" &&"
			CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.bait_bias_summary_metrics"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/BAIT_BIAS/SUMMARY/${SM_TAG}.bait_bias_summary_metrics.txt"
		# Move and rename pre adapter metrics/summary files to the reports directory and add a txt extension
		CMD=${CMD}" &&"
			CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.pre_adapter_detail_metrics"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/PRE_ADAPTER/METRICS/${SM_TAG}.pre_adapter_detail_metrics.txt"
		CMD=${CMD}" &&"
			CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.pre_adapter_summary_metrics"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/PRE_ADAPTER/SUMMARY/${SM_TAG}.pre_adapter_summary_metrics.txt"
		# move the results from collect alignment summary metrics to the reports folder
		CMD=${CMD}" &&"
			CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.alignment_summary_metrics"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/ALIGNMENT_SUMMARY/${SM_TAG}.alignment_summary_metrics.txt"
		# move the base distribution by cycle reports into the report directory
		CMD=${CMD}" &&"
			CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.base_distribution_by_cycle.pdf"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/BASE_DISTRIBUTION_BY_CYCLE/PDF/${SM_TAG}.base_distribution_by_cycle.pdf"
		CMD=${CMD}" &&"
			CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.base_distribution_by_cycle_metrics"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/BASE_DISTRIBUTION_BY_CYCLE/METRICS/${SM_TAG}.base_distribution_by_cycle_metrics.txt"
		# move the insert size reports into the report directory
		CMD=${CMD}" &&"
			CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.insert_size_histogram.pdf"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/INSERT_SIZE/PDF/${SM_TAG}.insert_size_histogram.pdf"
		CMD=${CMD}" &&"
			CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.insert_size_metrics"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/INSERT_SIZE/METRICS/${SM_TAG}.insert_size_metrics.txt"
		# move the mean quality by cycle into the report directory
		CMD=${CMD}" &&"
			CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.quality_by_cycle.pdf"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/MEAN_QUALITY_BY_CYCLE/PDF/${SM_TAG}.quality_by_cycle.pdf"
		CMD=${CMD}" &&"
			CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.quality_by_cycle_metrics"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/MEAN_QUALITY_BY_CYCLE/METRICS/${SM_TAG}.quality_by_cycle_metrics.txt"
		# move the basecall by q score into the report directory
		CMD=${CMD}" &&"
			CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.quality_distribution.pdf"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/BASECALL_Q_SCORE_DISTRIBUTION/PDF/${SM_TAG}.quality_distribution.pdf"
		CMD=${CMD}" &&"
			CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.quality_distribution_metrics"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/BASECALL_Q_SCORE_DISTRIBUTION/METRICS/${SM_TAG}.quality_distribution_metrics.txt"
		# move the gc bias reports into the report directory
		CMD=${CMD}" &&"
			CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.gc_bias.pdf"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/GC_BIAS/PDF/${SM_TAG}.gc_bias.pdf"
		CMD=${CMD}" &&"
			CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.gc_bias.detail_metrics"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/GC_BIAS/METRICS/${SM_TAG}.gc_bias.detail_metrics.txt"
		CMD=${CMD}" &&"
			CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.gc_bias.summary_metrics"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/GC_BIAS/SUMMARY/${SM_TAG}.gc_bias.summary_metrics.txt"
		# move the quality yield report into the report directory
		CMD=${CMD}" &&"
			CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.quality_yield_metrics"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/QUALITY_YIELD/${SM_TAG}.quality_yield_metrics.txt"
		# move the error summary report into the report directory
		CMD=${CMD}" &&"
			CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.error_summary_metrics"
			CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/ERROR_SUMMARY/${SM_TAG}.error_summary_metrics.txt"

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

END_COLLECT_MULTIPLE_METRICS=`date '+%s'` # capture time process stops for wall clock tracking purposes.

# write out timing metrics to file

	echo ${SM_TAG},E01,COLLECT_MULTIPLE_METRICS,${HOSTNAME},${START_COLLECT_MULTIPLE_METRICS},${END_COLLECT_MULTIPLE_METRICS} \
	>> ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.csv


# exit with the signal from the program

	exit ${SCRIPT_STATUS}
