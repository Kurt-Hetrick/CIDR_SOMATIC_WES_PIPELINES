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
	ALIGNMENT_CONTAINER=$2
	CORE_PATH=$3

	PROJECT=$4
	SM_TAG=$5
	REF_GENOME=$6
	HC_BAIT_BED=$7
	SAMPLE_SHEET=$8
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$9

		BAIT_BED_NAME=$(basename ${HC_BAIT_BED} .bed)
			if [[ ${HC_BAIT_BED}="/mnt/research/active/M_Valle_MD_SeqWholeExome_120417_1/BED_Files/BAITS_Merged_S03723314_S06588914.bed" \
				|| ${HC_BAIT_BED}="/mnt/research/active/H_Cutting_CFTR_WGHum-SeqCustom_1_Reanalysis/BED_Files/H_Cutting_phase_1plus2_super_file.bed" ]];
			then
				CALL_BED_FILE=${HC_BAIT_BED}
			else
				CALL_BED_FILE=$(${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${BAIT_BED_NAME}.bed)
			fi

## -----CONCATENATE SCATTERED g.vcf FILES INTO A SINGLE GRCh37 reference sorted g.vcf file-----

START_HAPLOTYPE_CALLER_GATHER=`date '+%s'` # capture time process starts for wall clock tracking purposes.

# construct command line

	CMD="singularity exec ${GATK_3_7_0_CONTAINER} java -cp"
		CMD=${CMD}" /usr/GenomeAnalysisTK.jar"
	CMD=${CMD}" org.broadinstitute.gatk.tools.CatVariants"
		CMD=${CMD}" --reference ${REF_GENOME}"
		CMD=${CMD}" --assumeSorted"
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
			CMD=${CMD}" --variant ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.${CHROMOSOME}.g.vcf.gz"
		done

	CMD=${CMD}" --outputFile ${CORE_PATH}/${PROJECT}/GVCF/${SM_TAG}.g.vcf.gz"

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

END_HAPLOTYPE_CALLER_GATHER=`date '+%s'` # capture time process stops for wall clock tracking purposes.

# write out timing metrics to file

	echo ${SM_TAG},I01,HAPLOTYPE_CALLER_GATHER,${HOSTNAME},${START_HAPLOTYPE_CALLER_GATHER},${END_HAPLOTYPE_CALLER_GATHER} \
	>> ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.csv

# exit with the signal from the program

	exit ${SCRIPT_STATUS}
