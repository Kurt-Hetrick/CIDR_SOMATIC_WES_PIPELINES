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

	JAVA_1_8=$1
	PICARD_DIR=$2
	FGBIO_DIR=$3
	CORE_PATH=$4
	RUN_FOLDER=$5
	PROJECT=$6
	LANE=$7
	SAMPLE_SHEET=$8
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$9
	READ_STRUCTURE=${10}
	FCID=${11}
	RUN_FOLDER_NAME=${12}
	# example: 146T8B9M8B146T
	RUN_SPLIT=`echo ${RUN_FOLDER_NAME} | awk '{split($0,runbc,"_"); print runbc[2]":"runbc[3]":"}'`
	RUN_BARCODE=${RUN_SPLIT}${FCID}
	#Illumina style sample sheet...Maybe we can extract one from the CSS version
	IEM_SAMPLESHEET=${13}

START_EXTRACT_BARCODES=`date '+%s'`

echo Project started at `date` >> ${CORE_PATH}/${PROJECT}"/DEMUX_UMAP/REPORTS/DEMUX_"${LANE}"_START_END_TIMESTAMP.txt"

	# FIRST Extract barcode calling parameters from the Illumina Experiment Manager (IEM) style sample sheet.
	# The format of this sample sheet is a traditional illumina style header with run and analysis parameters.
	# The [DATA] header could be filled from a CIDR LIMS and currently is expecting a lane, sample id, sample name, index, index2 and project column set
	# The sample id and sample name are currently our Platform unit (PU) which is FCID_LANE_INDEX-INDEX2.
	# Sample ID is used for naming the downstream fastq files generated from Illumina's bcl2fastq2 application.
	# Sample Name is used by this pipeline in later steps by picards ExtractIlluminaBarcodes.
    # http://fulcrumgenomics.github.io/fgbio/tools/latest/ExtractBasecallingParamsForPicard.html
	${JAVA_1_8}/java -Xmx10g -jar ${FGBIO_DIR}/fgbio-0.8.0.jar ExtractBasecallingParamsForPicard \
		--input=${IEM_SAMPLESHEET} \
		--bam=${CORE_PATH}/${PROJECT}/DEMUX_UMAP/BARCODES/${FCID}/RG_UMAP_BAMS/ \
		--output=${CORE_PATH}/${PROJECT}/DEMUX_UMAP/FCID_FILES/${FCID}/ \
		--lanes ${LANE} \
		
	# check the exit signal at this point.

		SCRIPT_STATUS=`echo $?`

	# if exit does not equal 0 then exit with whatever the exit signal is at the end.
	# also write to file that this job failed

			if [ "$SCRIPT_STATUS" -ne 0 ]
			 then
				echo $HOSTNAME ${JOB_NAME} ${USER} ${SCRIPT_STATUS} ${SGE_STDERR_PATH} \
				>> ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/TEMP/${SAMPLE_SHEET_NAME}"_"${SUBMIT_STAMP}"_ERRORS.csv"
				exit ${SCRIPT_STATUS}
			fi

END_EXTRACT_BARCODES=`date '+%s'`

HOSTNAME=`hostname`

echo ${LANE}","${PROJECT}",D.XTRACT.BCL2SAM,"$HOSTNAME","${START_EXTRACT_BARCODES}","${END_EXTRACT_BARCODES} \
>> ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/REPORTS/${LANE}"."${PROJECT}".WALL.CLOCK.TIMES.csv"

	${JAVA_1_8}/java -Xmx10g -jar ${FGBIO_DIR}/fgbio-0.8.0.jar ExtractBasecallingParamsForPicard \
		--input=${IEM_SAMPLESHEET} \
		--bam${CORE_PATH}/${PROJECT}/DEMUX_UMAP/BARCODES/${FCID}/RG_UMAP_BAMS/ \
		--output=${CORE_PATH}/${PROJECT}/DEMUX_UMAP/FCID_FILES/${FCID}/ \
		--lanes ${LANE}  >> ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/COMMAND_LINES/${LANE}".COMMAND.LINES.txt"

echo >> ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/COMMAND_LINES/${LANE}".COMMAND.LINES.txt"

# if file is not present exit !=0

ls ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/FCID_FILES/${FCID}/"barcode_params."${LANE}".txt"

echo Project ended at `date` >> ${CORE_PATH}/${PROJECT}"/DEMUX_UMAP/REPORTS/DEMUX_"${LANE}"_START_END_TIMESTAMP.txt"