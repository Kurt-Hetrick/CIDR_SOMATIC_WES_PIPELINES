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
	SEQUENCER_MODEL=$5
	SAMPLE_SHEET=$6
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$7

	INPUT_BAM_FILE_STRING=$8
		INPUT=`echo ${INPUT_BAM_FILE_STRING} | sed 's/,/ /g'`

## If NovaSeq is contained in the description field of the sample sheet then set the pixel distance appropriately
## Assumption: all read groups come from some sequencer model. otherwise pixel distance would be set to NovaSeq
## If mixing NovaSeq and non-NovaSeq then this workflow would need to change.

	if [[ ${SEQUENCER_MODEL} == *"NovaSeq"* ]]
		then
			PIXEL_DISTANCE="2500"
		else
			PIXEL_DISTANCE="100"
	fi

## Merge files and Mark Duplicates with Picard, write a duplicate report
## do coordinate sorting with sambamba

START_MARK_DUPLICATES=`date '+%s'` # capture time process starts for wall clock tracking purposes.

# if any part of pipe fails set exit to non-zero

	set -o pipefail

# construct command line

	CMD="singularity exec ${ALIGNMENT_CONTAINER} java -jar"
		CMD=${CMD}" -Xmx16g"
		CMD=${CMD}" -XX:ParallelGCThreads=4"
		CMD=${CMD}" /gatk/picard.jar"
	CMD=${CMD}" MarkDuplicates"
		CMD=${CMD}" ASSUME_SORT_ORDER=queryname"
		CMD=${CMD}" ${INPUT}"
		CMD=${CMD}" VALIDATION_STRINGENCY=SILENT"
		CMD=${CMD}" COMPRESSION_LEVEL=0"
		CMD=${CMD}" OPTICAL_DUPLICATE_PIXEL_DISTANCE=${PIXEL_DISTANCE}"
	CMD=${CMD}" METRICS_FILE=${CORE_PATH}/${PROJECT}/REPORTS/PICARD_DUPLICATES/${SM_TAG}_MARK_DUPLICATES.txt"
	CMD=${CMD}" OUTPUT=/dev/stdout"
	CMD=${CMD}" | singularity exec ${ALIGNMENT_CONTAINER} sambamba"
		CMD=${CMD}" sort"
		CMD=${CMD}" -t 4"
	CMD=${CMD}" -o ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.dup.bam"
		CMD=${CMD}" /dev/stdin"

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

END_MARK_DUPLICATES=`date '+%s'` # capture time process stops for wall clock tracking purposes.

# write wall clock times to file

	echo ${SM_TAG},B01,MARK_DUPLICATES,${HOSTNAME},${START_MARK_DUPLICATES},${END_MARK_DUPLICATES} \
	>> ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.csv

# exit with the signal from the program

	exit ${SCRIPT_STATUS}
