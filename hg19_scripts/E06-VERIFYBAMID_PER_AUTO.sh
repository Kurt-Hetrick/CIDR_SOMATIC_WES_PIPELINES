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
# redirecting stderr/stdout to file as a log.

	set

	echo

# INPUT VARIABLES

	ALIGNMENT_CONTAINER=$1
	GATK_3_7_0_CONTAINER=$2
	CORE_PATH=$3

	PROJECT=$4
	SM_TAG=$5
	REF_GENOME=$6
	VERIFY_VCF=$7
	BAIT_BED=$8
		BAIT_BED_NAME=$(basename ${BAIT_BED} .bed)

	SAMPLE_SHEET=$9
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=${10}

# create loop, for now doing this serially as I don't want to play with bandwith issues by doing it in parallel

START_SELECT_VERIFYBAMID_VCF=`date '+%s'`

# function to call 

	SELECT_VERIFYBAMID_VCF_CHR ()
	{
		# construct command line
		# gatk 3.7 is used here b/c gatk 4 has a bug with --interval_set_rule INTERSECTION
		# when using intersection, it does not work with when one interval is specified as any 
		# chromosome 2 through 9

			CMD="singularity exec ${GATK_3_7_0_CONTAINER} java -jar"
				CMD=${CMD}" /usr/GenomeAnalysisTK.jar"
			CMD=${CMD}" --analysis_type SelectVariants"
				CMD=${CMD}" --reference_sequence ${REF_GENOME}"
				CMD=${CMD}" --intervals ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${BAIT_BED_NAME}.bed"
				CMD=${CMD}" --intervals chr${AUTOSOME}"
				CMD=${CMD}" --variant ${VERIFY_VCF}"
				CMD=${CMD}" --interval_set_rule INTERSECTION"
			CMD=${CMD}" --out ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.VerifyBamID.${AUTOSOME}.vcf"

		# write command line to file and execute the command line

			echo ${CMD} >> ${CORE_PATH}/${PROJECT}/COMMAND_LINES/${SM_TAG}_command_lines.txt
			echo >> ${CORE_PATH}/${PROJECT}/COMMAND_LINES/${SM_TAG}_command_lines.txt
			echo ${CMD} | bash
	}

	CALL_VERIFYBAMID_CHR ()
	{
		# construct command line

			CMD="singularity exec ${ALIGNMENT_CONTAINER} verifyBamID"
				CMD=${CMD}" --bam ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.bam"
				CMD=${CMD}" --vcf ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.VerifyBamID.${AUTOSOME}.vcf"
				CMD=${CMD}" --precise"
				CMD=${CMD}" --verbose"
				CMD=${CMD}" --maxDepth 2500"
			CMD=${CMD}" --out ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.${AUTOSOME}"

		# write command line to file and execute the command line

			echo ${CMD} >> ${CORE_PATH}/${PROJECT}/COMMAND_LINES/${SM_TAG}_command_lines.txt
			echo >> ${CORE_PATH}/${PROJECT}/COMMAND_LINES/${SM_TAG}_command_lines.txt
			echo ${CMD} | bash
	}

# generate array of chromosomes from bait bed file.
# exclude chromosomes X,Y and MT
# run select verifybamid vcf and verifybamid for each chromosome separately

	for AUTOSOME in $(sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
		${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${BAIT_BED_NAME}.bed \
			| sed -r 's/[[:space:]]+/\t/g' \
			| cut -f 1 \
			| sed 's/^chr//g' \
			| egrep "^[0-9]" \
			| sort -k 1,1n \
			| uniq \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				collapse 1 \
			| sed 's/,/ /g');
	do
		SELECT_VERIFYBAMID_VCF_CHR
		CALL_VERIFYBAMID_CHR
	done

	# check the exit signal at this point. not sure if this is effective at this point.
	# but keeping it in anyways

		SCRIPT_STATUS=`echo $?`

		# if exit does not equal 0 then exit with whatever the exit signal is at the end.
		# also write to file that this job failed

			if [ "${SCRIPT_STATUS}" -ne 0 ]
				then
					echo ${SM_TAG} ${HOSTNAME} ${JOB_NAME} ${USER} ${SCRIPT_STATUS} ${SGE_STDERR_PATH} \
					>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt
					exit ${SCRIPT_STATUS}
			fi

END_SELECT_VERIFYBAMID_VCF_CHR=`date '+%s'` # capture time process stops for wall clock tracking purposes.

# write out timing metrics to file

	echo ${SM_TAG}_${PROJECT}_BAM_REPORTS,E01,SELECT_VERIFYBAMID_${AUTOSOME},${HOSTNAME},$START_SELECT_VERIFYBAMID_VCF_CHR,$END_SELECT_VERIFYBAMID_VCF_CHR \
	>> ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.csv

# exit with the signal from the program

	exit ${SCRIPT_STATUS}
