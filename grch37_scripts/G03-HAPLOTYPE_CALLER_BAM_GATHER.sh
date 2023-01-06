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
	HC_BAIT_BED=$5
	SAMPLE_SHEET=$6
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$7

		BAIT_BED_NAME=$(basename ${HC_BAIT_BED} .bed)
			if [[ ${HC_BAIT_BED}="/mnt/research/active/M_Valle_MD_SeqWholeExome_120417_1/BED_Files/BAITS_Merged_S03723314_S06588914.bed" \
				|| ${HC_BAIT_BED}="/mnt/research/active/H_Cutting_CFTR_WGHum-SeqCustom_1_Reanalysis/BED_Files/H_Cutting_phase_1plus2_super_file.bed" ]];
			then
				CALL_BED_FILE=${HC_BAIT_BED}
			else
				CALL_BED_FILE=$(${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${BAIT_BED_NAME}.bed)
			fi

## --GATHER HC BAM FILES IN NATURAL SORTED ORDER--

START_HC_BAM_GATHER=`date '+%s'` # capture time process starts for wall clock tracking purposes.

# construct command line

	CMD="singularity exec ${ALIGNMENT_CONTAINER} java -jar"
		CMD=${CMD}" /gatk/picard.jar"
	CMD=${CMD}" GatherBamFiles"
		# loop through natural sorted chromosome list to concatentate gvcf files.

		for CHROMOSOME in $(sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' ${CALL_BED_FILE} \
				| sed -r 's/[[:space:]]+/\t/g' \
				| sed 's/chr//g' \
				| egrep "^[0-9]|^X|^Y" \
				| cut -f 1 \
				| sort -V \
				| uniq \
				| singularity exec ${ALIGNMENT_CONTAINER} datamash \
					collapse 1 \
				| sed 's/,/ /g');
		do
			CMD=${CMD}" INPUT=${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.HC.${CHROMOSOME}.bam"
		done

		CMD=${CMD}" VALIDATION_STRINGENCY=SILENT"
		CMD=${CMD}" CREATE_INDEX=true"
	CMD=${CMD}" OUTPUT=${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.HC.bam"

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

END_HC_BAM_GATHER=`date '+%s'` # capture time process stops for wall clock tracking purposes.

# write out timing metrics to file

	echo ${SM_TAG},I01,MERGE_HC_BAM,${HOSTNAME},${START_HC_BAM_GATHER},${END_HC_BAM_GATHER} \
	>> ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.csv

# exit with the signal from the program

	exit ${SCRIPT_STATUS}
