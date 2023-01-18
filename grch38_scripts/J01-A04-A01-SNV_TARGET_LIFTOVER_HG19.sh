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

	PICARD_LIFTOVER_CONTAINER=$1
	
	CORE_PATH=$2
	PROJECT=$3
	SM_TAG=$4
	HG19_REF=$5
	HG38_TO_HG19_CHAIN=$6
	SAMPLE_SHEET=$7
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$8

# liftover from hg38 to hg19

START_LIFTOVER_SNV_TARGET_PASS=`date '+%s'`

	# construct command line

		CMD="singularity exec ${PICARD_LIFTOVER_CONTAINER} java -jar"
			CMD=${CMD}" /picard/picard.jar"
		CMD=${CMD}" LiftoverVcf"
			CMD=${CMD}" INPUT=${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}_QC_PASS_OnTarget_SNV.vcf"
			CMD=${CMD}" REJECT=${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}_QC_OnTarget_SNV.hg19.reject.vcf"
			CMD=${CMD}" REFERENCE_SEQUENCE=${HG19_REF}"
			CMD=${CMD}" CHAIN=${HG38_TO_HG19_CHAIN}"
		CMD=${CMD}" OUTPUT=${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}_QC_OnTarget_SNV.hg19.temp.vcf"
		CMD=${CMD}" &&"
		# remove loci that start with chrUn because cidrseqsuite will crash
		CMD=${CMD}" zegrep -v \"^chrUn\" ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}_QC_OnTarget_SNV.hg19.temp.vcf"
		CMD=${CMD}" >| ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}_QC_OnTarget_SNV.hg19.vcf"

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

END_LIFTOVER_SNV_TARGET_PASS=`date '+%s'`

# write out timing metrics to file

	echo ${SM_TAG},L01,LIFTOVER_SNV_TARGET_PASS,${HOSTNAME},${START_LIFTOVER_SNV_TARGET_PASS},${END_LIFTOVER_SNV_TARGET_PASS} \
	>> ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.csv

# exit with the signal from the program

	exit ${SCRIPT_STATUS}
