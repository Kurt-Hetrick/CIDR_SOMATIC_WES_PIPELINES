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
# redirecting stderr/stdout to file as a log.

	set

	echo

# INPUT VARIABLES

	GATK_3_7_0_CONTAINER=$1
	CORE_PATH=$2

	PROJECT=$3
	SM_TAG=$4
	REF_GENOME=$5
	GENE_LIST=$6
	TARGET_BED=$7
		TARGET_BED_NAME=$(basename ${TARGET_BED} .bed)
	SAMPLE_SHEET=$8
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$9

### --Depth of Coverage On Target--

START_DOC_TARGET=`date '+%s'` # capture time process starts for wall clock tracking purposes.

# construct command line

	CMD="singularity exec ${GATK_3_7_0_CONTAINER} java -jar"
		CMD=${CMD}" /usr/GenomeAnalysisTK.jar"
	CMD=${CMD}" --analysis_type DepthOfCoverage"
		CMD=${CMD}" --disable_auto_index_creation_and_locking_when_reading_rods"
		CMD=${CMD}" --reference_sequence ${REF_GENOME}"
		CMD=${CMD}" --input_file ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.bam"
		CMD=${CMD}" --calculateCoverageOverGenes:REFSEQ ${GENE_LIST}"
		CMD=${CMD}" --intervals ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${TARGET_BED_NAME}.bed"
		CMD=${CMD}" --minMappingQuality 20"
		CMD=${CMD}" --minBaseQuality 10"
		CMD=${CMD}" --outputFormat csv"
		CMD=${CMD}" --omitDepthOutputAtEachBase"
		CMD=${CMD}" --summaryCoverageThreshold 10"
		CMD=${CMD}" --summaryCoverageThreshold 15"
		CMD=${CMD}" --summaryCoverageThreshold 20"
		CMD=${CMD}" --summaryCoverageThreshold 30"
		CMD=${CMD}" --summaryCoverageThreshold 50"
	CMD=${CMD}" --out ${CORE_PATH}/${PROJECT}/REPORTS/DEPTH_OF_COVERAGE/TARGET/${SM_TAG}.TARGET_BED"
	##### MOVE AND RENAME OUTPUTS
	# COUNT OF BASES AT "X" LEVEL OF COVERAGE
	CMD=${CMD}" &&"
		CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/REPORTS/DEPTH_OF_COVERAGE/TARGET/${SM_TAG}.TARGET_BED.sample_cumulative_coverage_counts"
		CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/DEPTH_OF_COVERAGE/TARGET/${SM_TAG}.TARGET_BED.sample_cumulative_coverage_counts.csv"
	# FRACTION OF BASES AT "X" LEVEL OF COVERAGE
	CMD=${CMD}" &&"
		CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/REPORTS/DEPTH_OF_COVERAGE/TARGET/${SM_TAG}.TARGET_BED.sample_cumulative_coverage_proportions"
		CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/DEPTH_OF_COVERAGE/TARGET/${SM_TAG}.TARGET_BED.sample_cumulative_coverage_proportions.csv"
	# SUMMARY COVERAGE STATISTICS FOR EACH GENE WHERE PADDED CODING BED FILE OVERLAPS GENE LIST
	CMD=${CMD}" &&"
		CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/REPORTS/DEPTH_OF_COVERAGE/TARGET/${SM_TAG}.TARGET_BED.sample_gene_summary"
		CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/DEPTH_OF_COVERAGE/TARGET/${SM_TAG}.TARGET_BED.sample_gene_summary.csv"
	# COUNT OF INTERVALS COVERAGE BY AT LEAST "X" LEVEL OF COVERAGE
	CMD=${CMD}" &&"
		CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/REPORTS/DEPTH_OF_COVERAGE/TARGET/${SM_TAG}.TARGET_BED.sample_interval_statistics"
		CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/DEPTH_OF_COVERAGE/TARGET/${SM_TAG}.TARGET_BED.sample_interval_statistics.csv"
	# SUMMARY STATISTICS FOR EACH INTERVAL IN PADDED CODING BED FILE.
	CMD=${CMD}" &&"
		CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/REPORTS/DEPTH_OF_COVERAGE/TARGET/${SM_TAG}.TARGET_BED.sample_interval_summary"
		CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/DEPTH_OF_COVERAGE/TARGET/${SM_TAG}.TARGET_BED.sample_interval_summary.csv"
	# NOT SURE WHAT THIS IS AT THE MOMENT
	CMD=${CMD}" &&"
		CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/REPORTS/DEPTH_OF_COVERAGE/TARGET/${SM_TAG}.TARGET_BED.sample_statistics" \
		CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/DEPTH_OF_COVERAGE/TARGET/${SM_TAG}.TARGET_BED.sample_statistics.csv"
	# SAMPLE COVERAGE SUMMARY STATISTICS FOR SAMPLE IN PADDED CODING BED FILE.
	CMD=${CMD}" &&"
		CMD=${CMD}" mv -v ${CORE_PATH}/${PROJECT}/REPORTS/DEPTH_OF_COVERAGE/TARGET/${SM_TAG}.TARGET_BED.sample_summary"
		CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/DEPTH_OF_COVERAGE/TARGET/${SM_TAG}.TARGET_BED.sample_summary.csv"

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

END_DOC_TARGET=`date '+%s'` # capture time process stops for wall clock tracking purposes.

# write out timing metrics to file

	echo ${SM_TAG},E01,DOC_TARGET,${HOSTNAME},${START_DOC_TARGET},${END_DOC_TARGET} \
	>> ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.csv

# exit with the signal from the program

	exit ${SCRIPT_STATUS}
