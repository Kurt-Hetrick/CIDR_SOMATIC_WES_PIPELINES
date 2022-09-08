#!/bin/bash

SAMPLE_SHEET=$1
	SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
IEM_SAMPLE_SHEET=$2	
READ_STRUCTURE=$3
# CHANGE DIR TO WHERE YOU HAVE HAVE THE SCRIPTS BEING SUBMITTED

SCRIPT_DIR=`pwd`

if [[ -d "${SCRIPT_DIR}/scripts" ]]
then
	TEST="This is a test"
else
	echo "$SCRIPT_DIR/scripts not found. Change to the submitter working directory. Aborting the submission"
	exit 1
fi

##################
# CORE VARIABLES #
##################

	# Directory where sequencing projects are located

		CORE_PATH="/mnt/research/active"

	# Directory where NovaSeqa runs are located.

		NOVASEQ_REPO="/mnt/instrument_files/novaseq"

	# Generate a list of active queue and remove the ones that I don't want to use

		QUEUE_LIST=`qstat -f -s r \
			| egrep -v "^[0-9]|^-|^queue|^ " \
			| cut -d @ -f 1 \
			| sort \
			| uniq \
			| egrep -v "all.q|cgc.q|programmers.q|bigmem.q|bina.q|qtest.q|prod.q|lemon.q|rnd.q|qtest.q|uhoh.q" \
			| datamash collapse 1 \
			| awk '{print $1}'`

		PRIORITY="-1000"

		PIPELINE_VERSION=`git --git-dir=${SCRIPT_DIR}/../.git --work-tree=${SCRIPT_DIR}/.. log --pretty=format:'%h' -n 1`
		
		# load gcc 5.1.0 for programs like verifyBamID
		## this will get pushed out to all of the compute nodes since I specify env var to pushed out with qsub
			module load gcc/7.2.0

		# explicitly setting this b/c not everybody has had the $HOME directory transferred and I'm not going to through
		# and figure out who does and does not have this set correctly
			umask 0007

	# SUBMIT TIMESTAMP

		SUBMIT_STAMP=`date '+%s'`
    # grab email addy

		SEND_TO=`cat ${SCRIPT_DIR}/../email_lists.txt`

	# grab users full name

		SUBMITTER_ID=`whoami`
		PERSON_NAME=`getent passwd | awk 'BEGIN {FS=":"} $1=="'${SUBMITTER_ID}'" {print $5}'`


#####################
# PIPELINE PROGRAMS #
#####################

	JAVA_1_8="/mnt/linuxtools/JAVA/jdk1.8.0_73/bin"
	PICARD_DIR="/mnt/linuxtools/PICARD/picard-2.17.6"
	DATAMASH_DIR="/mnt/linuxtools/DATAMASH/datamash-1.0.6"
	FGBIO_DIR="/mnt/linuxtools/FGBIO_UMI"


#################################
##### MAKE A DIRECTORY TREE #####
#################################

	# make an array for each sample with information needed for pipeline input obtained from the sample sheet
		# add a end of file is not present
		# remove carriage returns if not present, remove blank lines if present, remove lines that only have whitespace
		
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

	# for every project in the sample sheet create all of the folders in the project if they don't already exist

		MAKE_PROJECT_DIR_TREE ()
		{
			mkdir -p \
			${CORE_PATH}/${SEQ_PROJECT}/DEMUX_UMAP/{AGG_UMAP_CRAM,LOGS,REPORTS,COMMAND_LINES,TEMP} \
			${CORE_PATH}/${SEQ_PROJECT}/DEMUX_UMAP/REPORTS/DEMUX \

		}

	for PROJECT in $(awk 'BEGIN {FS=","} NR>1 {print $1}' ${SAMPLE_SHEET} | sort | uniq );
		do
			CREATE_PROJECT_ARRAY
			MAKE_PROJECT_DIR_TREE
		done


    #Get the unique flowcell ID for each value in the sample sheet.
    #This will be used to create flowcell specific barcodes and parameters directories.
    #Assign a run folder name based on the novaseq raw data repository
    #Make the directories needed for ExtractIlluminaBarcodes and IlluminaBasecallsToSam

	CREATE_FLOWCELL_ARRAY ()
		{
			FCID_ARRAY=(`awk 1 ${SAMPLE_SHEET} \
				| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
				| awk 'BEGIN {FS=","} $3=="'${LANE}'" {print $2}' \
				| sort \
				| uniq`)
		FCID=${FCID_ARRAY[0]}
		RUN_FOLDER=`ls ${NOVASEQ_REPO} | grep ${FCID}`
		
		mkdir -p \
			${CORE_PATH}/${SEQ_PROJECT}/DEMUX_UMAP/REPORTS/DEMUX/${FCID} \
			${CORE_PATH}/${PROJECT}/DEMUX_UMAP/BARCODES/${FCID}/BARCODES/ \
			${CORE_PATH}/${PROJECT}/DEMUX_UMAP/BARCODES/${FCID}/RG_UMAP_BAMS/ \
			${CORE_PATH}/${SEQ_PROJECT}/DEMUX_UMAP/FCID_FILES/${FCID} \
			${CORE_PATH}/${SEQ_PROJECT}/DEMUX_UMAP/TEMP/${FCID}

		
		}

	#For each lane, construct QSUB commands to
	#Build the picard lane and barcode parameter files FGBIO: ExtractBasecallingParamsForPicard
	#Run ExtractIlluminaBarcodes followed immediately by IlluminaBasecallsToSam
	#These are based on the sample sheet format output by Illumina Experiment Manager

	DEMUX_PROJECT_LANE ()
	{
		echo Project started at `date` >> ${CORE_PATH}/${SEQ_PROJECT}"/DEMUX_UMAP/REPORTS/DEMUX_"${LANE}"_START_END_TIMESTAMP.txt"
		CREATE_FLOWCELL_ARRAY
		EXTRACT_PARAMS_4_PICARD
		DEMUX_BARCODES
		DEMUX_BCL2SAM
		echo >| ${CORE_PATH}/${SEQ_PROJECT}/DEMUX_UMAP/LOGS/${SAMPLE_SHEET_NAME}"_"${SUBMIT_STAMP}"_ERRORS.csv"
	}
	
	#Function to create QSUB command that will run wrapper for FGBIO: ExtractBasecallingParamsForPicard
	EXTRACT_PARAMS_4_PICARD() {
	echo \
			qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q ${QUEUE_LIST} \
			-p ${PRIORITY} \
			-N EXTRACT_PARAMS_4_PICARD"_"${SEQ_PROJECT}"_"${FCID}"_"${LANE} \
			-o ${CORE_PATH}/${SEQ_PROJECT}/DEMUX_UMAP/LOGS/${FCID}"_"${LANE}"-EXTRACT_PARAMS_4_PICARD.log" \
			-j y \
			-R y \
			-pe slots 1 \
			${SCRIPT_DIR}/scripts/EXTRACT_PARAMS_4_PICARD.sh \
			${JAVA_1_8} \
			${PICARD_DIR} \
			${FGBIO_DIR} \
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

	#Function to create QSUB commands to run Picard's ExtractIlluminaBarcodes
	#The end result will be unmapped BAM files containing the UMI sequence and quality scores in the RX/UX tags respectively.
	DEMUX_BARCODES () {
		echo \
			qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q "bigdata.q,c6420_21.q" \
			-p ${PRIORITY} \
			-N D.XTRACT.BARCODES"_"${SEQ_PROJECT}"_"${FCID}"_"${LANE} \
			-o ${CORE_PATH}/${SEQ_PROJECT}/DEMUX_UMAP/LOGS/${FCID}"_"${LANE}"-D.XTRACT.BARCODES.log" \
			-j y \
			-l excl=true \
			-R y \
			-hold_jid EXTRACT_PARAMS_4_PICARD"_"${SEQ_PROJECT}"_"${FCID}"_"${LANE} \
			${SCRIPT_DIR}/scripts/D.XTRACT.BARCODES.sh \
			${JAVA_1_8} \
			${PICARD_DIR} \
			${FGBIO_DIR} \
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
	DEMUX_BCL2SAM () {
		echo \
			qsub \
			-S /bin/bash \
			-cwd \
			-V \
			-q "bigdata.q,c6420_21.q" \
			-p ${PRIORITY} \
			-N E.BCL2SAM"_"${SEQ_PROJECT}"_"${FCID}"_"${LANE} \
			-o ${CORE_PATH}/${SEQ_PROJECT}/DEMUX_UMAP/LOGS/${FCID}"_"${LANE}"-E.BCL2SAM.log" \
			-j y \
			-l excl=true \
			-R y \
			-m e \
			-M foo \
			-hold_jid D.XTRACT.BARCODES"_"${SEQ_PROJECT}"_"${FCID}"_"${LANE} \
			${SCRIPT_DIR}/scripts/E.BCL2SAM.sh \
			${JAVA_1_8} \
			${PICARD_DIR} \
			${FGBIO_DIR} \
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

# For each unique lane identified in the CSS style sample sheet, call the DEMUX_PROJECT_LANE function
for LANE in $(awk 'BEGIN {FS=","} NR>1 {print $3}' ${SAMPLE_SHEET} | sort | uniq );
	do
		DEMUX_PROJECT_LANE
  done

#Basic redirect to an email to inform some people that the QSUB jobs have finished submitting.
#Another email will be sent at the completion of each lane of the demux job.
#Maybe TODO write a function to monitor and send an email when all lanes have completed.
printf "$SCRIPT_DIR/scripts/PICARD.DEMUX.SUBMITTER.sh\nhas finished submitting at\n`date`\nby `whoami`\n$SAMPLE_SHEET\nVersion: $PIPELINE_VERSION" \
	| mail -s "$PERSON_NAME has submitted PICARD.DEMUX.SUBMITTER.sh" \
	${SEND_TO} \
