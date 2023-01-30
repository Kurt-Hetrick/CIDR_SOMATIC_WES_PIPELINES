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
	CORE_PATH=$2

	PROJECT=$3
	SM_TAG=$4
	REF_GENOME=$5
	POPULATION_FREQUENCIES=$6
	TARGET_BED=$7
		TARGET_BED_NAME=$(basename ${TARGET_BED} .bed)
	SAMPLE_SHEET=$8
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=$9

# Run Collect HS metrics which generates hybridization metrics for the qc report
## Also generates a per target interval coverage summary

START_GET_PILEUP_SUMMARY=$(date '+%s')

	# construct command line

		CMD="singularity exec ${UMI_CONTAINER} java -jar"
			CMD=${CMD}" /gatk/gatk.jar"
		CMD=${CMD}" GetPileupSummaries"
			CMD=${CMD}" --input ${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram"
			CMD=${CMD}" --reference ${REF_GENOME}"
			CMD=${CMD}" --variant ${POPULATION_FREQUENCIES}" # NAMING IT THIS BECAUSE I MIGHT SWITCH BETWEEN EXAC, GNOMAD, ETC.
			CMD=${CMD}" --intervals ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${TARGET_BED_NAME}.bed"
		CMD=${CMD}" --output ${CORE_PATH}/${PROJECT}/REPORTS/GATK_CALC_TUMOR_CONTAM/${SM_TAG}.getpileupsummaries.table"

	# write command line to file and execute the command line

		echo ${CMD} >> ${CORE_PATH}/${PROJECT}/COMMAND_LINES/${SM_TAG}_command_lines.txt
		echo >> ${CORE_PATH}/${PROJECT}/COMMAND_LINES/${SM_TAG}_command_lines.txt
		echo ${CMD} | bash

	# check the exit signal at this point.

		SCRIPT_STATUS=$(echo $?)

		# if exit does not equal 0 then exit with whatever the exit signal is at the end.
		# also write to file that this job failed

			if
				[ "${SCRIPT_STATUS}" -ne 0 ]
			then
				echo ${SM_TAG} ${HOSTNAME} ${JOB_NAME} ${USER} ${SCRIPT_STATUS} ${SGE_STDERR_PATH} \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt
				exit ${SCRIPT_STATUS}
			fi

END_GET_PILEUP_SUMMARY=$(date '+%s') # capture time process stops for wall clock tracking purposes.

# write out timing metrics to file

	echo ${SM_TAG}_${PROJECT}_BAM_REPORTS,F01,GET_PILEUP_SUMMARIES,${HOSTNAME},${START_GET_PILEUP_SUMMARY},${END_GET_PILEUP_SUMMARY} \
	>> ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.csv

# exit with the signal from the program

	exit ${SCRIPT_STATUS}
