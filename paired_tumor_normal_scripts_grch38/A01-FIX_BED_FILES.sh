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

	# ALIGNMENT_CONTAINER=$1
	QC_REPORT=$1
		QC_REPORT_NAME=$(basename ${QC_REPORT} .csv)
	CORE_PATH=$2
	TUMOR_PROJECT=$3
	TUMOR_INDIVIDUAL=$4
	TUMOR_SM_TAG=$5
	REF_DICT=$6
	BAIT_BED=$7
		# BAIT_BED_NAME=$(basename ${BAIT_BED} .bed)
	TARGET_BED=$8
		# TARGET_BED_NAME=$(basename ${TARGET_BED} .bed)
	# REF_DICT=$8
	# HG38_TO_HG19_CHAIN=$9
	# HG19_DICT=${10}

# FIX BED FILES

	# FIX THE BAIT BED FILE

		# make sure that there is EOF
		# remove CARRIAGE RETURNS
		# CONVERT VARIABLE LENGTH WHITESPACE FIELD DELIMETERS TO SINGLE TAB.

			awk 1 ${CORE_PATH}/${TUMOR_PROJECT}/BED_Files/${BAIT_BED}.bed \
				| sed -r 's/\r//g ; s/[[:space:]]+/\t/g' \
				| sort -V -k 1,1 -k 2,2n -k 3,3n \
				| grep -v "chrM" \
			>| ${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}-${TUMOR_SM_TAG}-${BAIT_BED}.bed

	# FIX THE TARGET BED FILE

		# make sure that there is EOF
		# remove CARRIAGE RETURNS
		# CONVERT VARIABLE LENGTH WHITESPACE FIELD DELIMETERS TO SINGLE TAB.
					
			awk 1 ${CORE_PATH}/${TUMOR_PROJECT}/BED_Files/${TARGET_BED}.bed \
				| sed -r 's/\r//g ; s/[[:space:]]+/\t/g' \
				| sort -V -k 1,1 -k 2,2n -k 3,3n \
				| grep -v "chrM" \
			>| ${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}-${TUMOR_SM_TAG}-${TARGET_BED}.bed

# # MAKE PICARD INTERVAL FILES (1-based start) for bed files in the sample sheet
# 	# GRAB THE SEQUENCING DICTIONARY FORM THE ".dict" file in the directory where the reference genome is located
# 	# then concatenate with the fixed bed file.
# 	# add 1 to the start
# 	# picard interval needs strand information and a locus name
# 		# made everything plus stranded b/c i don't think this information is used
# 		# constructed locus name with chr name, start+1, stop

# 	# bait bed

# 		(grep "^@SQ" ${REF_DICT} \
# 			; awk 'BEGIN {OFS="\t"} \
# 				{print $1,($2+1),$3,"+",$1"_"($2+1)"_"$3}' \
# 			${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}-${TUMOR_SM_TAG}-${BAIT_BED_NAME}.bed) \
# 		>| ${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}-${TUMOR_SM_TAG}-${BAIT_BED_NAME}-picard.bed

	# target bed

		(grep "^@SQ" ${REF_DICT} \
			; awk 'BEGIN {OFS="\t"} \
				{print $1,($2+1),$3,"+",$1"_"($2+1)"_"$3}' \
			${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}-${TUMOR_SM_TAG}-${TARGET_BED}.bed) \
		>| ${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}-${TUMOR_SM_TAG}-${TARGET_BED}-picard.bed

# 	# titv bed

# 		(grep "^@SQ" ${REF_DICT} \
# 			; awk 'BEGIN {OFS="\t"} \
# 				{print $1,($2+1),$3,"+",$1"_"($2+1)"_"$3}' \
# 			${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}-${TUMOR_SM_TAG}-${TITV_BED_NAME}.bed) \
# 		>| ${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}-${TUMOR_SM_TAG}-${TITV_BED_NAME}-picard.bed	

# 	# LIFTOVER PICARD TARGET INTERVAL LIST BACK TO HG19

# 		# construct command line

# 			CMD="singularity exec ${ALIGNMENT_CONTAINER} java -jar"
# 				CMD=${CMD}" /gatk/picard.jar"
# 			CMD=${CMD}" LiftOverIntervalList"
# 				CMD=${CMD}" INPUT=${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}-${TUMOR_SM_TAG}-${TARGET_BED_NAME}-picard.bed"
# 				CMD=${CMD}" SEQUENCE_DICTIONARY=${HG19_DICT}"
# 				CMD=${CMD}" CHAIN=${HG38_TO_HG19_CHAIN}"
# 			CMD=${CMD}" OUTPUT=${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}.OnTarget.hg19.interval_list"

# 		# write command line to file and execute the command line

# 			echo ${CMD} >> ${CORE_PATH}/${TUMOR_PROJECT}/COMMAND_LINES/${TUMOR_INDIVIDUAL}_command_lines.txt
# 			echo >> ${CORE_PATH}/${TUMOR_PROJECT}/COMMAND_LINES/${TUMOR_INDIVIDUAL}_command_lines.txt
# 			echo ${CMD} | bash

# 			# CONVERT HG19 CONVERT INTERVAL LIST BACK TO A BED FILE
# 			# remove contigs that are not from primary assembly
			
# 				grep -v "^@" ${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}.OnTarget.hg19.interval_list \
# 					| awk 'BEGIN {OFS="\t"} \
# 						$1!~"_" \
# 						{print $1,($2-1),$3}' \
# 				>| ${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}-${TUMOR_SM_TAG}-${TARGET_BED_NAME}.lift.hg19.bed
