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

	CORE_PATH=$1
	ALIGNMENT_CONTAINER=$2

	PROJECT=$3
	SM_TAG=$4
	BAIT_BED=$5
		BAIT_BED_NAME=$(basename ${BAIT_BED} .bed)
	SAMPLE_SHEET=$6
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)

# CREATE A FILE WITH THE HEADER

	echo "#SM_TAG" CHROM VERIFYBAM_FREEMIX VERIFYBAM_SNPS VERIFYBAM_FREELK1 VERRIFYBAM_FREELK0 VERIFYBAM_AVG_DP \
	>| ${CORE_PATH}/${PROJECT}/REPORTS/VERIFYBAMID_CHR/${SM_TAG}.VERIFYBAMID.PER_CHR.txt

# LOOP THROUGH EACH UNIQUE AUTOSOME IN THE BAIT BED FILE AND APPEND TO ABOVE FILE

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
		cat ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.${AUTOSOME}.selfSM \
			| grep -v ^# \
			| awk 'BEGIN {OFS="\t"} \
				{print($1,"'${AUTOSOME}'",$7,$4,$8,$9,$6)}' \
		>> ${CORE_PATH}/${PROJECT}/REPORTS/VERIFYBAMID_CHR/${SM_TAG}.VERIFYBAMID.PER_CHR.txt
	done
