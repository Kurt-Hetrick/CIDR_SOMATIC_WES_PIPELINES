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
	REF_GENOME=$5

	SAMPLE_SHEET=$6
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$7

## --write lossless cram file. this is the deliverable

START_CRAM=`date '+%s'` # capture time process starts for wall clock tracking purposes.

# construct command line

	CMD="singularity exec ${ALIGNMENT_CONTAINER} samtools"
	CMD=${CMD}" view"
		CMD=${CMD}" -C ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG}/${SM_TAG}.bam"
		CMD=${CMD}" -T ${REF_GENOME}"
		CMD=${CMD}" -@ 4"
		CMD=${CMD}" --write-index"
		CMD=${CMD}" -O CRAM"
	CMD=${CMD}" -o ${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram"
	# generate md5sum on the cram file and the samtools generated index
	CMD=${CMD}" &&"
		CMD=${CMD}" md5sum ${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram*"
		CMD=${CMD}" >| ${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram.md5"
	# make a copy/rename the cram index file since their appears to be two useable standards
	CMD=${CMD}" &&"
		CMD=${CMD}" cp -rvf ${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram.crai" \
		CMD=${CMD}" ${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.crai"

	# write command line to file and execute the command line

		echo ${CMD} >> ${CORE_PATH}/${PROJECT}/COMMAND_LINES/${SM_TAG}_command_lines.txt
		echo >> ${CORE_PATH}/${PROJECT}/COMMAND_LINES/${SM_TAG}_command_lines.txt
		echo ${CMD} | bash

	# check the exit signal at this point.

		SCRIPT_STATUS=`echo $?`

END_CRAM=`date '+%s'` # capture time process stops for wall clock tracking purposes.

# write out timing metrics to file

	echo ${SM_TAG},E01,CRAM,${HOSTNAME},${START_CRAM},${END_CRAM} \
	>> ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.csv

#######################################################################################
### grab the read group header from the cram file and make a stub for the meta data ###
### this is so if you need to regenerate a qc report ##################################
### and the cram file has been moved and not symlinked back ###########################
### this can be referenced to use in generating the qc report. ########################
#######################################################################################
##### THIS IS THE HEADER ################################################
##### "SM_TAG","PROJECT","RG_PU","LIBRARY" ##############################
##### "LIBRARY_PLATE","LIBRARY_WELL","LIBRARY_ROW","LIBRARY_COLUMN" #####
##### "HYB_PLATE","HYB_WELL","HYB_ROW","HYB_COLUMN" #####################
#########################################################################

	if [ -f ${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram ];
		then

			# grab field number for SM_TAG

				SM_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools \
					view -H \
				${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram \
					| grep -m 1 ^@RG \
					| sed 's/\t/\n/g' \
					| cat -n \
					| sed 's/^ *//g' \
					| awk '$2~/^SM:/ \
						{print $1}'`)

			# grab field number for PLATFORM_UNIT_TAG

				PU_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools \
					view -H \
				${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram \
					| grep -m 1 ^@RG \
					| sed 's/\t/\n/g' \
					| cat -n \
					| sed 's/^ *//g' \
					| awk '$2~/^PU:/ \
						{print $1}'`)

			# grab field number for LIBRARY_TAG

				LB_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools \
					view -H \
				${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram \
					| grep -m 1 ^@RG \
					| sed 's/\t/\n/g' \
					| cat -n \
					| sed 's/^ *//g' \
					| awk '$2~/^LB:/ \
						{print $1}'`)

			# grab field number for CRAM_PROCESSING_VERSION (PG field)

				PG_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools \
					view -H \
				${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram \
					| grep -m 1 ^@RG \
					| sed 's/\t/\n/g' \
					| cat -n \
					| sed 's/^ *//g' \
					| awk '$2~/^PG:/ \
						{print $1}'`)

			# grab field number for PLATFORM_MODEL field (PG field)

				PM_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools \
					view -H \
				${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram \
					| grep -m 1 ^@RG \
					| sed 's/\t/\n/g' \
					| cat -n \
					| sed 's/^ *//g' \
					| awk '$2~/^PM:/ \
						{print $1}'`)

			# grab field number for LIMS_DATE

				DT_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools \
					view -H \
				${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram \
					| grep -m 1 ^@RG \
					| sed 's/\t/\n/g' \
					| cat -n \
					| sed 's/^ *//g' \
					| awk '$2~/^DT:/ \
						{print $1}'`)

			# grab field number for PLATFORM

				PL_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools \
					view -H \
				${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram \
					| grep -m 1 ^@RG \
					| sed 's/\t/\n/g' \
					| cat -n \
					| sed 's/^ *//g' \
					| awk '$2~/^PL:/ \
						{print $1}'`)

			# grab field number for BED FILES (DS field)

				DS_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools \
					view -H \
				${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram \
					| grep -m 1 ^@RG \
					| sed 's/\t/\n/g' \
					| cat -n \
					| sed 's/^ *//g' \
					| awk '$2~/^DS:/ \
						{print $1}'`)

			# Now grab the header and format
				# breaking out the library name into its parts is assuming that the format is...
				# fill in empty fields with NA thing (for loop in awk) is a lifesaver
				# https://unix.stackexchange.com/questions/53448/replacing-missing-value-blank-space-with-zero

				singularity exec ${ALIGNMENT_CONTAINER} samtools \
					view -H \
				${CORE_PATH}/${PROJECT}/CRAM/${SM_TAG}.cram \
					| grep ^@RG \
					| awk \
						-v SM_FIELD="$SM_FIELD" \
						-v PU_FIELD="$PU_FIELD" \
						-v LB_FIELD="$LB_FIELD" \
						-v PG_FIELD="$PG_FIELD" \
						-v PM_FIELD="$PM_FIELD" \
						-v DT_FIELD="$DT_FIELD" \
						-v PL_FIELD="$PL_FIELD" \
						-v DS_FIELD="$DS_FIELD" \
						'BEGIN {OFS="\t"} \
						{split($SM_FIELD,SMtag,":"); \
						split($PU_FIELD,PU,":"); \
						split($LB_FIELD,Library,":"); \
						split(Library[2],Library_Unit,"_"); \
						split($PG_FIELD,PROGRAM,":"); \
						split($PL_FIELD,SEQ_PLATFORM,":"); \
						split($PM_FIELD,SEQ_MODEL,":"); \
						split($DT_FIELD,DT,":"); \
						split(DT[2],DATE,"T"); \
						split($DS_FIELD,DS,":"); \
						split(DS[2],BED_FILES,","); \
						print "'${PROJECT}'",\
							SMtag[2],\
							PU[2],\
							Library[2],\
							Library_Unit[1],\
							Library_Unit[2],\
							substr(Library_Unit[2],1,1),\
							substr(Library_Unit[2],2,2),\
							Library_Unit[3],\
							Library_Unit[4],\
							substr(Library_Unit[4],1,1),\
							substr(Library_Unit[4],2,2),\
							PROGRAM[2],\
							SEQ_PLATFORM[2],\
							SEQ_MODEL[2],\
							DATE[1],\
							BED_FILES[1],\
							BED_FILES[2],\
							BED_FILES[3]}' \
					| awk 'BEGIN { FS = OFS = "\t" } { for(i=1; i<=NF; i++) if($i ~ /^ *$/) $i = "NA" }; 1' \
				>| ${CORE_PATH}/${PROJECT}/REPORTS/RG_HEADER/${SM_TAG}.RG_HEADER.txt
		else
			echo -e "${PROJECT}\t${SM_TAG}\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA" \
			>| ${CORE_PATH}/${PROJECT}/REPORTS/RG_HEADER/${SM_TAG}.RG_HEADER.txt
	fi

# if exit does not equal 0 then exit with whatever the exit signal is at the end.
# also write to file that this job failed

	if [ "${SCRIPT_STATUS}" -ne 0 ]
		then
			echo ${SM_TAG} ${HOSTNAME} ${JOB_NAME} ${USER} ${SCRIPT_STATUS} ${SGE_STDERR_PATH} \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt
			exit ${SCRIPT_STATUS}
	fi

# exit with the signal from samtools bam to cram

	exit ${SCRIPT_STATUS}
