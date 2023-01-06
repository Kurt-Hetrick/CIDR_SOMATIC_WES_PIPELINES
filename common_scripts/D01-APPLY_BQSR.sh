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
	SAMPLE_SHEET=$6
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$7

## --write out bam file with a 4 bin qscore scheme, remove indel Q scores, emit original Q scores
# have to change the way to specify this jar file eventually. gatk 4 devs are monsters.

START_FINAL_BAM=`date '+%s'` # capture time process starts for wall clock tracking purposes.

# construct command line

	CMD="singularity exec ${ALIGNMENT_CONTAINER} java -jar"
		CMD=${CMD}" /gatk/gatk.jar"
	CMD=${CMD}" ApplyBQSR"
		CMD=${CMD}" --add-output-sam-program-record"
		CMD=${CMD}" --use-original-qualities"
		CMD=${CMD}" --emit-original-quals"
		CMD=${CMD}" --reference ${REF_GENOME}"
		CMD=${CMD}" --input ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.dup.bam"
		CMD=${CMD}" --bqsr-recal-file ${CORE_PATH}/${PROJECT}/REPORTS/COUNT_COVARIATES/${SM_TAG}_PERFORM_BQSR.bqsr"
		CMD=${CMD}" --static-quantized-quals 10"
		CMD=${CMD}" --static-quantized-quals 20"
		CMD=${CMD}" --static-quantized-quals 30"
	CMD=${CMD}" --output ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.bam"

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

END_FINAL_BAM=`date '+%s'` # capture time process stops for wall clock tracking purposes.

# write out timing metrics to file

	echo ${SM_TAG},D01,APPLY_BQSR,${HOSTNAME},${START_APPLY_BQSR},${END_APPLY_BQSR} \
	>> ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.csv

# exit with the signal from the program

	exit ${SCRIPT_STATUS}
