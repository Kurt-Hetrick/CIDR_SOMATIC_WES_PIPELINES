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

	CORE_PATH=$1

	PROJECT=$2
	SM_TAG=$3
	BAIT_BED=$4
		BAIT_BED_NAME=$(basename ${BAIT_BED} .bed)
	TARGET_BED=$5
		TARGET_BED_NAME=$(basename ${TARGET_BED} .bed)
	TITV_BED=$6
		TITV_BED_NAME=$(basename ${TITV_BED} .bed)
	REF_DICT=$7
	SAMPLE_SHEET=$8
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)

# FIX BED FILES (FOR GRCH37)

	# FIX THE BAIT BED FILE

		# make sure that there is EOF
		# remove CARRIAGE RETURNS
		# remove CHR PREFIXES (THIS IS FOR GRCH37)
		# CONVERT VARIABLE LENGTH WHITESPACE FIELD DELIMETERS TO SINGLE TAB.
					
			awk 1 ${BAIT_BED} \
				| sed -r 's/\r//g ; s/chr//g ; s/[[:space:]]+/\t/g' \
			>| ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${BAIT_BED_NAME}.bed

	# FIX THE TARGET BED FILE

		# make sure that there is EOF
		# remove CARRIAGE RETURNS
		# remove CHR PREFIXES (THIS IS FOR GRCH37)
		# CONVERT VARIABLE LENGTH WHITESPACE FIELD DELIMETERS TO SINGLE TAB.
					
			awk 1 ${TARGET_BED} \
				| sed -r 's/\r//g ; s/chr//g ; s/[[:space:]]+/\t/g' \
			>| ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${TARGET_BED_NAME}.bed

	# FIX THE TITV BED FILE

		# make sure that there is EOF
		# remove CARRIAGE RETURNS
		# remove CHR PREFIXES (THIS IS FOR GRCH37)
		# CONVERT VARIABLE LENGTH WHITESPACE FIELD DELIMETERS TO SINGLE TAB.
					
			awk 1 ${TITV_BED} \
				| sed -r 's/\r//g ; s/chr//g ; s/[[:space:]]+/\t/g' \
			>| ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${TITV_BED_NAME}.bed

# MAKE PICARD INTERVAL FILES (1-based start) for bed files in the sample sheet
	# GRAB THE SEQUENCING DICTIONARY FORM THE ".dict" file in the directory where the reference genome is located
	# then concatenate with the fixed bed file.
	# add 1 to the start
	# picard interval needs strand information and a locus name
		# made everything plus stranded b/c i don't think this information is used
		# constructed locus name with chr name, start+1, stop

	# bait bed

		(grep "^@SQ" ${REF_DICT} \
			; awk 'BEGIN {OFS="\t"} \
				{print $1,($2+1),$3,"+",$1"_"($2+1)"_"$3}' \
			${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${BAIT_BED_NAME}.bed) \
		>| ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${BAIT_BED_NAME}-picard.bed

	# target bed

		(grep "^@SQ" ${REF_DICT} \
			; awk 'BEGIN {OFS="\t"} \
				{print $1,($2+1),$3,"+",$1"_"($2+1)"_"$3}' \
			${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${TARGET_BED_NAME}.bed) \
		>| ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${TARGET_BED_NAME}-picard.bed

	# titv bed

		(grep "^@SQ" ${REF_DICT} \
			; awk 'BEGIN {OFS="\t"} \
				{print $1,($2+1),$3,"+",$1"_"($2+1)"_"$3}' \
			${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${TITV_BED_NAME}.bed) \
		>| ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}-${TITV_BED_NAME}-picard.bed
