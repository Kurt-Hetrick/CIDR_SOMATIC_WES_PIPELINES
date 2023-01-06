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

	JAVA_1_8=$1
	LAB_QC_DIR=$2
	CORE_PATH=$3

	PROJECT=$4
	SAMPLE_SHEET=$5
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$6

START_LAB_PREP_METRICS=`date '+%s'` # capture time process starts for wall clock tracking purposes.

# Make a QC report just for a project in the sample sheet.

	(awk 1 ${SAMPLE_SHEET} \
		| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
		| head -n 1 ; \
	awk 1 ${SAMPLE_SHEET} \
		| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
		| awk 'BEGIN {FS=",";OFS=","} \
			$1=="'${PROJECT}'" \
			{print $0}') \
	>| ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SAMPLE_SHEET_NAME}_${START_LAB_PREP_METRICS}.csv

# Generates a QC report for lab specific metrics including Physique Report, Samples Table, Sequencer XML data, Pca and Phoenix. Does not check if samples are dropped.

# construct command line

	CMD="$JAVA_1_8/java -jar"
		CMD=${CMD}" ${LAB_QC_DIR}/EnhancedSequencingQCReport.jar"
	CMD=${CMD}" -lab_qc_metrics" \
		# [1] path_to_sample_sheet
		CMD=${CMD}" ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SAMPLE_SHEET_NAME}_${START_LAB_PREP_METRICS}.csv" \
		# [2] path_to_seq_proj (${CORE_PATH})
		CMD=${CMD}" ${CORE_PATH}" \
	# [3] path_to_output_file
	CMD=${CMD}" ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SAMPLE_SHEET_NAME}.LAB_PREP_METRICS.csv"

	# write command line to file and execute the command line

		echo ${CMD} >> ${CORE_PATH}/${PROJECT}/COMMAND_LINES/${PROJECT}_command_lines.txt
		echo >> ${CORE_PATH}/${PROJECT}/COMMAND_LINES/${PROJECT}_command_lines.txt
		echo ${CMD} | bash

	# check the exit signal at this point.

		SCRIPT_STATUS=`echo $?`

		# if exit does not equal 0 then exit with whatever the exit signal is at the end.
		# also write to file that this job failed

			if [ "${SCRIPT_STATUS}" -ne 0 ]
				then
					echo ${PROJECT} ${HOSTNAME} ${JOB_NAME} ${USER} ${SCRIPT_STATUS} ${SGE_STDERR_PATH} \
					>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt
					exit ${SCRIPT_STATUS}
			fi

END_LAB_PREP_METRICS=`date '+s'` # capture time process stops for wall clock tracking purposes.

# add a date stamp to output, so if reran, the latest information will be pulled out.

	(head -n 1 ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SAMPLE_SHEET_NAME}.LAB_PREP_METRICS.csv \
		| awk '{print $0 ",EPOCH_TIME"}' ; \
	awk 'NR>1 {print $0 "," "'${START_LAB_PREP_METRICS}'"}' \
	${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SAMPLE_SHEET_NAME}.LAB_PREP_METRICS.csv \
		| sort -k 1,1 ) \
	>| ${CORE_PATH}/${PROJECT}/REPORTS/LAB_PREP_REPORTS/${SAMPLE_SHEET_NAME}.LAB_PREP_METRICS.csv

# write wall clock times to file

	echo ${PROJECT},A01,LAB_QC_PREP_METRICS,${HOSTNAME},${START_LAB_PREP_METRICS},${END_LAB_PREP_METRICS} \
	>> ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.csv

# exit with the signal from the program

	exit ${SCRIPT_STATUS}
