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

	GATK_3_7_0_CONTAINER=$1
	CORE_PATH=$2

	PROJECT=$3
	SM_TAG=$4
	REF_GENOME=$5
	SAMPLE_SHEET=$6
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$7

# Filter to just on SNVS

START_FILTER_SNV=`date '+%s'` # capture time process starts for wall clock tracking purposes.

	# construct command line

		CMD="singularity exec ${GATK_3_7_0_CONTAINER} java -jar"
			CMD=${CMD}" /usr/GenomeAnalysisTK.jar"
		CMD=${CMD}" --analysis_type VariantFiltration"
			CMD=${CMD}" --reference_sequence ${REF_GENOME}"
			CMD=${CMD}" --filterExpression 'QD < 2.0'"
			CMD=${CMD}" --filterName 'QD'"
			CMD=${CMD}" --filterExpression 'MQ < 30.0'"
			CMD=${CMD}" --filterName 'MQ'"
			CMD=${CMD}" --filterExpression 'FS > 40.0'"
			CMD=${CMD}" --filterName 'FS_SNV'"
			CMD=${CMD}" --filterExpression 'MQRankSum < -12.5'"
			CMD=${CMD}" --filterName 'MQRankSum'"
			CMD=${CMD}" --filterExpression 'ReadPosRankSum < -8.0'"
			CMD=${CMD}" --filterName 'ReadPosRankSum_SNV'"
			CMD=${CMD}" --filterExpression 'DP < 8.0'"
			CMD=${CMD}" --filterName 'low_DP'"
			CMD=${CMD}" --logging_level ERROR"
			CMD=${CMD}" --variant ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.QC_RAW_SNV.vcf.gz"
		CMD=${CMD}" --out ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.FILTERED.SNV.vcf.gz"

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

END_FILTER_SNV=`date '+%s'` # capture time process stops for wall clock tracking purposes.

# write out timing metrics to file

	echo ${SM_TAG},J01,FILTER_SNV,${HOSTNAME},${START_FILTER_SNV},${END_FILTER_SNV} \
	>> ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.csv

# exit with the signal from the program

	exit ${SCRIPT_STATUS}
