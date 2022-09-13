#!/usr/bin/env bash

###################
# INPUT VARIABLES #
###################

	SAMPLE_SHEET=$1
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	IEM_SAMPLE_SHEET=$2
	READ_STRUCTURE=$3
	PRIORITY=$4 # optional. if no 4th argument present then the default is -15

		# if there is no 2nd argument present then use the number for priority
			if [[ ! ${PRIORITY} ]]
				then
				PRIORITY="-15"
			fi

########################################################################
# CHANGE SCRIPT DIR TO WHERE YOU HAVE HAVE THE SCRIPTS BEING SUBMITTED #
########################################################################

	SUBMITTER_SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

	SCRIPT_DIR="${SUBMITTER_SCRIPT_PATH}/scripts"

##################
# CORE VARIABLES #
##################

	# Directory where sequencing projects are located

		CORE_PATH="/mnt/research/active"

	# Directory where NovaSeqa runs are located.

		NOVASEQ_REPO="/mnt/instrument_files/novaseq"

	# used for tracking in the read group header of the cram file

		PIPELINE_VERSION=$(git --git-dir=${SUBMITTER_SCRIPT_PATH}/.git --work-tree=${SUBMITTER_SCRIPT_PATH} log --pretty=format:'%h' -n 1)

	# load gcc for programs like verifyBamID
	## this will get pushed out to all of the compute nodes since I specify env var to pushed out with qsub

			module load gcc/7.2.0

	# explicitly setting this b/c not everybody has had the $HOME directory transferred and I'm not going to through
	# and figure out who does and does not have this set correctly

			umask 0007

	# SUBMIT TIMESTAMP

		SUBMIT_STAMP=$(date '+%s')

	# SUBMITTER_ID

		SUBMITTER_ID=$(whoami)

	# grab submitter's name

		PERSON_NAME=$(getent passwd \
			| awk 'BEGIN {FS=":"} \
				$1=="'${SUBMITTER_ID}'" \
				{print $5}')

	# grab email addy

		SEND_TO=$(cat ${SUBMITTER_SCRIPT_PATH}/email_lists.txt)

	# bind the host file system /mnt to the singularity container. in case I use it in the submitter.

		export SINGULARITY_BINDPATH="/mnt:/mnt"

	# QSUB ARGUMENTS LIST
		# set shell on compute node
		# start in current working directory
		# transfer submit node env to compute node
		# set SINGULARITY BINDPATH
		# set queues to submit to
		# set priority
		# combine stdout and stderr logging to same output file

			QSUB_ARGS="-S /bin/bash" \
				QSUB_ARGS=${QSUB_ARGS}" -cwd" \
				QSUB_ARGS=${QSUB_ARGS}" -V" \
				QSUB_ARGS=${QSUB_ARGS}" -v SINGULARITY_BINDPATH=/mnt:/mnt" \
				QSUB_ARGS=${QSUB_ARGS}" -q ${QUEUE_LIST}" \
				QSUB_ARGS=${QSUB_ARGS}" -p ${PRIORITY}" \
				QSUB_ARGS=${QSUB_ARGS}" -j y"

#####################
# PIPELINE PROGRAMS #
#####################

	UMI_CONTAINER="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/CONTAINERS/umi-0.0.1.simg"
		# picard 2.26.10
		# datamash 1.6 # with some version of perl
		# some version of openjdk-8
		# fgbio 2.0.2

	# JAVA_1_8="/mnt/linuxtools/JAVA/jdk1.8.0_73/bin"
	# PICARD_DIR="/mnt/linuxtools/PICARD/picard-2.17.6"
	# DATAMASH_DIR="/mnt/linuxtools/DATAMASH/datamash-1.0.6"
	# FGBIO_DIR="/mnt/linuxtools/FGBIO_UMI"

#################################
##### MAKE A DIRECTORY TREE #####
#################################

#########################################################
# CREATE_PROJECT_ARRAY for each PROJECT in sample sheet #
#########################################################
	# add a end of file is not present
	# remove carriage returns if not present
	# remove blank lines if present
	# remove lines that only have whitespace
		
		CREATE_PROJECT_ARRAY ()
		{
			PROJECT_ARRAY=(`awk 1 ${SAMPLE_SHEET} \
				| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
				| awk 'BEGIN {FS=","} $1=="'${PROJECT}'" {print $1}' \
				| sort \
				| uniq`)

			#  1  PROJECT
			SEQ_PROJECT=${PROJECT_ARRAY[0]}
		}

##################################
# project directory tree creator #
##################################

	MAKE_PROJECT_DIR_TREE ()
	{
		mkdir -p \
		${CORE_PATH}/${SEQ_PROJECT}/DEMUX_UMAP/{AGG_UMAP_CRAM,LOGS,REPORTS,COMMAND_LINES,TEMP} \
		${CORE_PATH}/${SEQ_PROJECT}/DEMUX_UMAP/REPORTS/DEMUX
	}

##################################
# RUN STEPS TO DO PROJECT SET UP #
##################################

	for PROJECT in \
		$(awk 1 ${SAMPLE_SHEET} \
			| awk 'BEGIN {FS=","} \
				NR>1 \
				{print $1}' \
		${SAMPLE_SHEET} \
			| sort \
			| uniq );
	do
		CREATE_PROJECT_ARRAY
		MAKE_PROJECT_DIR_TREE
	done

######################################################################################
# Get the unique flowcell ID for each value in the sample sheet. #####################
# This will be used to create flowcell specific barcodes and parameters directories. #
# Assign a run folder name based on the novaseq raw data repository ##################
# Make the directories needed for ExtractIlluminaBarcodes and IlluminaBasecallsToSam #
######################################################################################

	CREATE_FLOWCELL_ARRAY ()
	{
		FCID_ARRAY=(`awk 1 ${SAMPLE_SHEET} \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
			| awk 'BEGIN {FS=","} \
				$3=="'${LANE}'" \
				{print $2}' \
			| sort \
			| uniq`)

		FCID=${FCID_ARRAY[0]}
		
		RUN_FOLDER=$(ls ${NOVASEQ_REPO} \
			| grep ${FCID})

		mkdir -p \
			${CORE_PATH}/${SEQ_PROJECT}/DEMUX_UMAP/REPORTS/DEMUX/${FCID} \
			${CORE_PATH}/${PROJECT}/DEMUX_UMAP/BARCODES/${FCID}/{BARCODES,RG_UMAP_BAMS} \
			${CORE_PATH}/${SEQ_PROJECT}/DEMUX_UMAP/FCID_FILES/${FCID} \
			${CORE_PATH}/${SEQ_PROJECT}/DEMUX_UMAP/TEMP/${FCID}
	}

##############################################################################################
# For each lane, construct QSUB commands to ##################################################
# Build the picard lane and barcode parameter files FGBIO: ExtractBasecallingParamsForPicard #
# Run ExtractIlluminaBarcodes followed immediately by IlluminaBasecallsToSam #################
# These are based on the sample sheet format output by Illumina Experiment Manager ###########
##############################################################################################

# Function to create QSUB command that will run wrapper for FGBIO: ExtractBasecallingParamsForPicard

	EXTRACT_PARAMS_4_PICARD ()
	{
		echo \
		qsub \
			${QSUB_ARGS} \
			-R y \
			-pe slots 1 \
		-N EXTRACT_PARAMS_4_PICARD_${SEQ_PROJECT}_${FCID}_${LANE} \
			-o ${CORE_PATH}/${SEQ_PROJECT}/DEMUX_UMAP/LOGS/${FCID}_${LANE}-EXTRACT_PARAMS_4_PICARD.log \
		${SCRIPT_DIR}/EXTRACT_PARAMS_4_PICARD.sh \
			${UMI_CONTAINER} \
			${CORE_PATH} \
			${NOVASEQ_REPO}/${RUN_FOLDER} \
			${SEQ_PROJECT} \
			${LANE} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP} \
			${READ_STRUCTURE} \
			${FCID} \
			${RUN_FOLDER} \
			${IEM_SAMPLE_SHEET}
	}

# Function to create QSUB commands to run Picard's ExtractIlluminaBarcodes
# The end result will be unmapped BAM files containing the UMI sequence and quality scores in the RX/UX tags respectively.

	DEMUX_BARCODES ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q "bigdata.q,c6420_21.q" \
			-p ${PRIORITY} \
			-j y \
			-l excl=true \
			-R y \
		-N D.XTRACT.BARCODES_${SEQ_PROJECT}_${FCID}_${LANE} \
			-o ${CORE_PATH}/${SEQ_PROJECT}/DEMUX_UMAP/LOGS/${FCID}_${LANE}-D.XTRACT.BARCODES.log \
		-hold_jid EXTRACT_PARAMS_4_PICARD_${SEQ_PROJECT}_${FCID}_${LANE} \
		${SCRIPT_DIR}/D.XTRACT.BARCODES.sh \
			${UMI_CONTAINER} \
			${CORE_PATH} \
			${NOVASEQ_REPO}/${RUN_FOLDER} \
			${SEQ_PROJECT} \
			${LANE} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP} \
			${READ_STRUCTURE} \
			${FCID} \
			${RUN_FOLDER}
	}

#Function to create QSUB commands to run Picard's IlluminaBasecallsToSam
#The end result will be unmapped BAM files containing the UMI sequence and quality scores in the RX/UX tags respectively.

	DEMUX_BCL2SAM ()
	{
		echo \
		qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q "bigdata.q,c6420_21.q" \
			-p ${PRIORITY} \
			-j y \
			-l excl=true \
			-R y \
			-m e \
			-M foo \
		-N E.BCL2SAM_${SEQ_PROJECT}_${FCID}_${LANE} \
			-o ${CORE_PATH}/${SEQ_PROJECT}/DEMUX_UMAP/LOGS/${FCID}_${LANE}-E.BCL2SAM.log \
		-hold_jid D.XTRACT.BARCODES_${SEQ_PROJECT}_${FCID}_${LANE} \
		${SCRIPT_DIR}/E.BCL2SAM.sh \
			${UMI_CONTAINER} \
			${CORE_PATH} \
			${NOVASEQ_REPO}/${RUN_FOLDER} \
			${SEQ_PROJECT} \
			${LANE} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP} \
			${READ_STRUCTURE} \
			${FCID} \
			${RUN_FOLDER}
	}

# create a function to do all of the above

	DEMUX_PROJECT_LANE ()
	{
		echo Project started at $(date) >> ${CORE_PATH}/${SEQ_PROJECT}/DEMUX_UMAP/REPORTS/DEMUX_${LANE}_START_END_TIMESTAMP.txt
		CREATE_FLOWCELL_ARRAY
		EXTRACT_PARAMS_4_PICARD
		DEMUX_BARCODES
		DEMUX_BCL2SAM
		echo >| ${CORE_PATH}/${SEQ_PROJECT}/DEMUX_UMAP/LOGS/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.csv
	}

# For each unique lane identified in the CSS style sample sheet, call the DEMUX_PROJECT_LANE function

	for LANE in \
		$(awk 'BEGIN {FS=","} \
			NR>1 \
			{print $3}' \
		${SAMPLE_SHEET} \
			| sort \
			| uniq )
	do
		DEMUX_PROJECT_LANE
	done

#Basic redirect to an email to inform some people that the QSUB jobs have finished submitting.
#Another email will be sent at the completion of each lane of the demux job.
#Maybe TODO write a function to monitor and send an email when all lanes have completed.

	printf "${SCRIPT_DIR}/PICARD.DEMUX.SUBMITTER.sh\nhas finished submitting at\n$(date)\nby $(whoami)\n${SAMPLE_SHEET}\nVersion: ${PIPELINE_VERSION}" \
		| mail -s "${PERSON_NAME} has submitted PICARD.DEMUX.SUBMITTER.sh" \
		${SEND_TO}
