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
	HC_BAIT_BED=$6
	CHROMOSOME=$7
	SAMPLE_SHEET=$8
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$9

		BAIT_BED_NAME=$(basename ${HC_BAIT_BED} .bed)
			if [[ ${HC_BAIT_BED}="/mnt/research/active/M_Valle_MD_SeqWholeExome_120417_1/BED_Files/BAITS_Merged_S03723314_S06588914.bed" ]];
			then
				CALL_BED_FILE=${HC_BAIT_BED}
			else
				CALL_BED_FILE=$(${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${BAIT_BED_NAME}.bed)
			fi

## -----Haplotype Caller-----

## Call on Bait

START_HAPLOTYPE_CALLER=`date '+%s'` # capture time process starts for wall clock tracking purposes.

# Setting read_filter overclipped. this is in broad's wdl.
# https://software.broadinstitute.org/gatk/documentation/tooldocs/current/org_broadinstitute_hellbender_engine_filters_OverclippedReadFilter.php

# I'm pushing the freemix value to the contamination fraction

	FREEMIX=$(awk 'NR==2 \
			{print $7}' \
		${CORE_PATH}/${PROJECT}/REPORTS/VERIFYBAMID/${SM_TAG}.selfSM)

# construct command line

	CMD="singularity exec ${GATK_3_7_0_CONTAINER} java -jar"
		CMD=${CMD}" /usr/GenomeAnalysisTK.jar"
	CMD=${CMD}" --analysis_type HaplotypeCaller"
		CMD=${CMD}" --reference_sequence ${REF_GENOME}"
		CMD=${CMD}" --input_file ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.bam"
		CMD=${CMD}" --intervals ${CALL_BED_FILE}"
		CMD=${CMD}" --intervals ${CHROMOSOME}"
		CMD=${CMD}" --interval_set_rule INTERSECTION"
		CMD=${CMD}" --contamination_fraction_to_filter ${FREEMIX}"
		CMD=${CMD}" --variant_index_type LINEAR"
		CMD=${CMD}" --variant_index_parameter 128000"
		CMD=${CMD}" -pairHMM VECTOR_LOGLESS_CACHING"
		CMD=${CMD}" --max_alternate_alleles 3"
		CMD=${CMD}" --emitRefConfidence GVCF"
		CMD=${CMD}" --read_filter OverclippedRead"
		CMD=${CMD}" --annotation AS_BaseQualityRankSumTest"
		CMD=${CMD}" --annotation AS_FisherStrand"
		CMD=${CMD}" --annotation AS_InbreedingCoeff"
		CMD=${CMD}" --annotation AS_MappingQualityRankSumTest"
		CMD=${CMD}" --annotation AS_RMSMappingQuality"
		CMD=${CMD}" --annotation AS_ReadPosRankSumTest"
		CMD=${CMD}" --annotation AS_StrandOddsRatio"
		CMD=${CMD}" --annotation FractionInformativeReads"
		CMD=${CMD}" --annotation StrandBiasBySample"
		CMD=${CMD}" --annotation StrandAlleleCountsBySample"
		CMD=${CMD}" --annotation GCContent"
		CMD=${CMD}" --annotation AlleleBalanceBySample"
		CMD=${CMD}" --annotation AlleleBalance"
		CMD=${CMD}" --annotation LikelihoodRankSumTest"
	CMD=${CMD}" --bamOutput ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.HC.${CHROMOSOME}.bam"
		CMD=${CMD}" --emitDroppedReads"
	CMD=${CMD}" --out ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.${CHROMOSOME}.g.vcf.gz"

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

END_HAPLOTYPE_CALLER=`date '+%s'` # capture time process stops for wall clock tracking purposes.

# write out timing metrics to file

	echo ${SM_TAG},G01,HAPLOTYPE_CALLER_${CHROMOSOME},${HOSTNAME},${START_HAPLOTYPE_CALLER},${END_HAPLOTYPE_CALLER} \
	>> ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.csv

# exit with the signal from the program

	exit ${SCRIPT_STATUS}
