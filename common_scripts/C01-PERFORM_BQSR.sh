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
	KNOWN_INDEL_1=$6
	KNOWN_INDEL_2=$7
	DBSNP=$8
	BAIT_BED=${9}
		BAIT_BED_NAME=$(basename ${BAIT_BED} .bed)
	SAMPLE_SHEET=${10}
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=${11}

## --BQSR using data only from the baited intervals

START_PERFORM_BQSR=`date '+%s'` # capture time process starts for wall clock tracking purposes.

# construct command line

	CMD="singularity exec ${ALIGNMENT_CONTAINER} java -jar"
		CMD=${CMD}" /gatk/gatk.jar"
	CMD=${CMD}" BaseRecalibrator"
		CMD=${CMD}" --use-original-qualities"
		CMD=${CMD}" --input ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.dup.bam"
		CMD=${CMD}" --reference ${REF_GENOME}"
		CMD=${CMD}" --known-sites ${KNOWN_INDEL_1}"
		CMD=${CMD}" --known-sites ${KNOWN_INDEL_2}"
		CMD=${CMD}" --known-sites ${DBSNP}"
		CMD=${CMD}" --intervals ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${BAIT_BED_NAME}.bed"
	CMD=${CMD}" --output ${CORE_PATH}/${PROJECT}/REPORTS/COUNT_COVARIATES/${SM_TAG}_PERFORM_BQSR.bqsr"

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

END_PERFORM_BQSR=`date '+%s'` # capture time process stops for wall clock tracking purposes.

# write wall clock times to file

	echo ${SM_TAG},C01,PERFORM_BQSR,${HOSTNAME},${START_PERFORM_BQSR},${END_PERFORM_BQSR} \
	>> ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.csv

# exit with the signal from the program

	exit ${SCRIPT_STATUS}
