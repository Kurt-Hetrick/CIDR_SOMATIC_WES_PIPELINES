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
	B37_TO_HG19_CHAIN=$6
	SAMPLE_SHEET=$7
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$8

# Start running Many Picard sequencing metrics for the QC report

START_LIFTOVER_SNV_TARGET_PASS_VCF_HG19=$(date '+%s') # capture time process starts for wall clock tracking purposes.

	# construct command line

		CMD="singularity exec ${PICARD_LIFTOVER_CONTAINER} java -jar"
			CMD=${CMD}" /picard/picard.jar"
		CMD=${CMD}" LiftoverVcf"
			CMD=${CMD}" INPUT=${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}_QC_PASS_OnTarget_SNV.vcf"
			CMD=${CMD}" REFERENCE_SEQUENCE=${HG19_REF}"
			CMD=${CMD}" CHAIN=${B37_TO_HG19_CHAIN}"
		CMD=${CMD}" OUTPUT=${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}_QC_PASS_OnTarget_SNV_LIFTOVER_HG19.vcf.gz"
		CMD=${CMD}" REJECT=${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}_QC_PASS_OnTarget_SNV_LIFTOVER_HG19_REJECTED.vcf.gz"

	# write command line to file and execute the command line

		echo ${CMD} >> ${CORE_PATH}/${PROJECT}/COMMAND_LINES/${SM_TAG}_command_lines.txt
		echo >> ${CORE_PATH}/${PROJECT}/COMMAND_LINES/${SM_TAG}_command_lines.txt
		echo ${CMD} | bash

	# check the exit signal at this point.

		SCRIPT_STATUS=$(echo $?)

		# if exit does not equal 0 then exit with whatever the exit signal is at the end.
		# also write to file that this job failed

			if [ "${SCRIPT_STATUS}" -ne 0 ]
				then
					echo ${SM_TAG} ${HOSTNAME} ${JOB_NAME} ${USER} ${SCRIPT_STATUS} ${SGE_STDERR_PATH} \
					>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt
					exit ${SCRIPT_STATUS}
			fi

END_LIFTOVER_SNV_TARGET_PASS_VCF_HG19=$(date '+%s') # capture time process stops for wall clock tracking purposes.

# write out timing metrics to file

	echo ${SM_TAG},J01,LIFTOVER_SNV_TARGET_PASS_VCF_HG19,${HOSTNAME},${START_LIFTOVER_SNV_TARGET_PASS_VCF_HG19},${END_LIFTOVER_SNV_TARGET_PASS_VCF_HG19} \
	>> ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.csv


# exit with the signal from the program

	exit ${SCRIPT_STATUS}
