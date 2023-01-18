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

	JAVA_1_8=$1
	CIDRSEQSUITE_7_5_0_DIR=$2
	VERACODE_CSV=$3
	
	CORE_PATH=$4
	PROJECT=$5
	SM_TAG=$6
	TARGET_BED=$7
		TARGET_BED_NAME=$(basename ${TARGET_BED} .bed)
	SAMPLE_SHEET=$8
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$9

####################################################################
##### SCAN PROJECT DIRECTORY FOR A FINAL REPORT FOR THE SAMPLE #####
####################################################################

START_CONCORDANCE=`date '+%s'` # capture time process starts for wall clock tracking purposes.

# look for a final report and store it as a variable. if there are multiple ones, then take the newest one

	FINAL_REPORT_FILE_TEST=$(ls -tr ${CORE_PATH}/${PROJECT}/Pretesting/Final_Genotyping_Reports/*${SM_TAG}* \
		| tail -n 1)

# if final report exists containing the full sm-tag, then cidrseqsuite magic

	if [[ ! -z "${FINAL_REPORT_FILE_TEST}" ]]
		then
			FINAL_REPORT=${FINAL_REPORT_FILE_TEST}

	# if it does not exist, and if the $SM_TAG does not begin with an integer then split $SM_TAG On a @ or _ or -
	# look for a final report that contains that that first element of the $SM_TAG
	# bonus feature. if this first tests true but the file still does not exist then cidrseqsuite magic files b/c no file exists

	elif [[ ${SM_TAG} != [0-9]* ]]
		then
			# note that underscore has to be before dash in bash regular expression
			HAPMAP=${SM_TAG%%[@_-]*}

			FINAL_REPORT=$(ls ${CORE_PATH}/${PROJECT}/Pretesting/Final_Genotyping_Reports/*${HAPMAP}* \
				| head -n 1)

			# if there is no report for a hapmap sample then exit program with code 1

			if [[ -z "${FINAL_REPORT}" ]]
			then

				echo
				echo At this time, you are looking for a final report that does not exist or fails to meet the current logic for finding a final report.
				echo Please talk to Kurt, because he loves to talk.
				echo

				SCRIPT_STATUS="1"

				echo ${SM_TAG} ${HOSTNAME} ${JOB_NAME} ${USER} ${SCRIPT_STATUS} ${SGE_STDERR_PATH} \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt

				exit 1

			fi

	else

	# both conditions fails then echo the below message and send info to error reprot
	# exit with 1

		echo
		echo At this time, you are looking for a final report that does not exist or fails to meet the current logic for finding a final report.
		echo Please talk to Kurt, because he loves to talk.
		echo

		SCRIPT_STATUS="1"

		echo ${SM_TAG} ${HOSTNAME} ${JOB_NAME} ${USER} ${SCRIPT_STATUS} ${SGE_STDERR_PATH} \
		>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt

		exit 1

	fi

###########################################################
##### IF A FINAL REPORT IS FOUND THEN RUN CONCORDANCE #####
###########################################################

# -single_sample_concordance
# Performs concordance between one vcf file and one final report. The vcf must be single sample.

	CMD="${JAVA_1_8}/java -jar"
		CMD=${CMD}" ${CIDRSEQSUITE_7_5_0_DIR}/CIDRSeqSuite.jar"
		CMD=${CMD}" -single_sample_concordance"
		# [1] path_to_vcf_file
		CMD=${CMD}" ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}_QC_OnTarget_SNV.hg19.vcf"
		CMD=${CMD}" ${FINAL_REPORT}"
		# [3] path_to_bed_file
		CMD=${CMD}" ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${TARGET_BED_NAME}.lift.hg19.bed"
		# [4] path_to_liftover_file
		CMD=${CMD}" ${VERACODE_CSV}"
	# [5] path_to_output_directory
	CMD=${CMD}" ${CORE_PATH}/${PROJECT}/REPORTS/CONCORDANCE/"

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

END_CONCORDANCE=`date '+%s'` # capture time process stops for wall clock tracking purposes.

# write out timing metrics to file

	echo ${SM_TAG},L01,CONCORDANCE,${HOSTNAME},${START_CONCORDANCE},${END_CONCORDANCE} \
	>> ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.csv

# exit with the signal from the program

	exit ${SCRIPT_STATUS}
