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
	FLOWCELL=$4
	LANE=$5
	INDEX=$6
		PLATFORM_UNIT=${FLOWCELL}_${LANE}_${INDEX}
		# String concatenation of INDEX1_2 used by picard demux.
			INDEX_CONCAT=$(echo ${PLATFORM_UNIT} \
				| awk '{split ($0,INDEX,"_"); print INDEX[3]}' \
				| sed 's/-//')

	PLATFORM=$7
	LIBRARY_NAME=$8
	RUN_DATE=$9
	SM_TAG=${10}
	CENTER=${11}
	SEQUENCER_MODEL=${12}
	REF_GENOME=${13}
	PIPELINE_VERSION=${14}
	BAIT_BED=${15}
		BAIT_NAME=$(basename ${BAIT_BED} .bed)
	TARGET_BED=${16}
		TARGET_NAME=$(basename ${TARGET_BED} .bed)
	TITV_BED=${17}
		TITV_NAME=$(basename ${TITV_BED} .bed)
	NOVASEQ_REPO=${18}
	SAMPLE_SHEET=${19}
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=${20}

# Need to convert data in sample manifest to Iso 8601 date since we are not using bwa mem to populate this.
# Picard AddOrReplaceReadGroups is much more stringent here.

	if
		[[ ${RUN_DATE} = *"-"* ]]
	then
		# for when the date is this 2018-09-05

			ISO_8601=$(echo ${RUN_DATE} \
				| awk '{print "'${RUN_DATE}'" "T00:00:00-0500"}')
	else
		# for when the data is like this 4/26/2018

			ISO_8601=$(echo ${RUN_DATE} \
				| awk '{split ($0,DATES,"/"); \
				if (length(DATES[1]) < 2 && length(DATES[2]) < 2) \
				print DATES[3]"-0"DATES[1]"-0"DATES[2]"T00:00:00-0500"; \
				else if (length(DATES[1]) < 2 && length(DATES[2]) > 1) \
				print DATES[3]"-0"DATES[1]"-"DATES[2]"T00:00:00-0500"; \
				else if(length(DATES[1]) > 1 && length(DATES[2]) < 2) \
				print DATES[3]"-"DATES[1]"-0"DATES[2]"T00:00:00-0500"; \
				else print DATES[3]"-"DATES[1]"-"DATES[2]"T00:00:00-0500"}')
	fi

# -----Alignment and BAM post-processing-----

	# convert ubam to interleaved fastq on /dev/stdout
	# align with bwa mem
	# merge umi tags into mapped bam file
	# add readgroup header

# bwa mem for paired end reads

	START_BWA_MEM=$(date '+%s') # capture time process starts for wall clock tracking purposes.

	# if any part of pipe fails set exit to non-zero

		set -o pipefail

	# construct cmd line

		CMD="singularity exec ${ALIGNMENT_CONTAINER} java -jar"
			CMD=${CMD}" /gatk/picard.jar"
		CMD=${CMD}" SamToFastq"
			CMD=${CMD}" INPUT=${CORE_PATH}/${PROJECT}/DEMUX_UMAP/BARCODES/${FLOWCELL}/RG_UMAP_BAMS/${PLATFORM_UNIT}.${INDEX_CONCAT}.${LANE}.bam"
			CMD=${CMD}" FASTQ=/dev/stdout"
			CMD=${CMD}" INTERLEAVE=true"
		CMD=${CMD}" | singularity exec ${ALIGNMENT_CONTAINER} bwa"
		CMD=${CMD}" mem"
			CMD=${CMD}" -p"
			CMD=${CMD}" -K 100000000"
			CMD=${CMD}" -Y"
			CMD=${CMD}" -t 4"
			CMD=${CMD}" ${REF_GENOME}"
			CMD=${CMD}" /dev/stdin"
		CMD=${CMD}" | singularity exec ${ALIGNMENT_CONTAINER} java -jar"
			CMD=${CMD}" /gatk/picard.jar"
		CMD=${CMD}" MergeBamAlignment"
			CMD=${CMD}" ALIGNED=/dev/stdin"
			CMD=${CMD}" UNMAPPED=${CORE_PATH}/${PROJECT}/DEMUX_UMAP/BARCODES/${FLOWCELL}/RG_UMAP_BAMS/${PLATFORM_UNIT}.${INDEX_CONCAT}.${LANE}.bam"
			CMD=${CMD}" SORT_ORDER=coordinate"
			CMD=${CMD}" REFERENCE_SEQUENCE=${REF_GENOME}"
			CMD=${CMD}" MAX_GAPS=-1"
			CMD=${CMD}" EXPECTED_ORIENTATIONS=FR"
			CMD=${CMD}" ALIGNER_PROPER_PAIR_FLAGS=false"
		CMD=${CMD}" OUTPUT=/dev/stdout"
		CMD=${CMD}" | singularity exec ${ALIGNMENT_CONTAINER} java -jar"
			CMD=${CMD}" /gatk/picard.jar"
		CMD=${CMD}" AddOrReplaceReadGroups"
			CMD=${CMD}" INPUT=/dev/stdin"
			CMD=${CMD}" CREATE_INDEX=true"
			CMD=${CMD}" RGID=${FLOWCELL}_${LANE}"
			CMD=${CMD}" RGLB=${LIBRARY_NAME}"
			CMD=${CMD}" RGPL=${PLATFORM}"
			CMD=${CMD}" RGPU=${PLATFORM_UNIT}"
			CMD=${CMD}" RGPM=${SEQUENCER_MODEL}"
			CMD=${CMD}" RGSM=${SM_TAG}"
			CMD=${CMD}" RGCN=${CENTER}"
			CMD=${CMD}" RGDT=${ISO_8601}"
			CMD=${CMD}" RGPG=CIDR_SOMATIC_WES-${PIPELINE_VERSION}"
			CMD=${CMD}" RGDS=${BAIT_NAME},${TARGET_NAME},${TITV_NAME}"
		CMD=${CMD}" OUTPUT=${CORE_PATH}/${PROJECT}/TEMP/${PLATFORM_UNIT}_aligned.bam"

	# write command line to file and execute the command line

		echo ${CMD} >> ${CORE_PATH}/${PROJECT}/COMMAND_LINES/${SM_TAG}_command_lines.txt
		echo >> ${CORE_PATH}/${PROJECT}/COMMAND_LINES/${SM_TAG}_command_lines.txt
		echo ${CMD} | bash

	# check the exit signal at this point.

		SCRIPT_STATUS=$(echo $?)

		# if exit does not equal 0 then exit with whatever the exit signal is at the end.
		# also write to file that this job failed
		# so if it crashes, I just straight out exit
			### ...at first I didn't remember why would I chose that, but I am cool with it
			### ...not good for debugging, but I don't want cmd lines and times when jobs crash tbh if the plan is to possibly distribute them

			if
				[ "${SCRIPT_STATUS}" -ne 0 ]
			then
				echo ${SM_TAG} ${HOSTNAME} ${JOB_NAME} ${USER} ${SCRIPT_STATUS} ${SGE_STDERR_PATH} \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.txt
				exit ${SCRIPT_STATUS}
			fi

	END_BWA_MEM=$(date '+%s') # capture time process stops for wall clock tracking purposes.

# write wall clock times to file

	echo ${SM_TAG},A01,BWA_MEM,${HOSTNAME},${START_BWA_MEM},${END_BWA_MEM} \
	>> ${CORE_PATH}/${PROJECT}/REPORTS/${PROJECT}.WALL.CLOCK.TIMES.csv

# exit with the signal from the program

	exit ${SCRIPT_STATUS}
