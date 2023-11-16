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

	UMI_CONTAINER=$1
	CORE_PATH=$2
	PROJECT=$3
	LANE=$4
	SAMPLE_SHEET=$5
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$6
	READ_STRUCTURE=$7 # example: 146T8B9M8B146T
	FCID=$8
	IEM_SAMPLESHEET=$9 #Illumina style sample sheet...Maybe we can extract one from the CSS version

START_EXTRACT_BARCODES=$(date '+%s') # capture time process starts for wall clock tracking purposes.

	echo Project started at $(date) \
	>> ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/REPORTS/DEMUX_${LANE}_START_END_TIMESTAMP.txt

# FIRST Extract barcode calling parameters from the Illumina Experiment Manager (IEM) style sample sheet.
# The format of this sample sheet is a traditional illumina style header with run and analysis parameters.
# The [DATA] header could be filled from a CIDR LIMS and currently is expecting a lane, sample id, sample name, index, index2 and project column set
# The sample id and sample name are currently our Platform unit (PU) which is FCID_LANE_INDEX-INDEX2.
# Sample ID is used for naming the downstream fastq files generated from Illumina's bcl2fastq2 application.
# Sample Name is used by this pipeline in later steps by picards ExtractIlluminaBarcodes.
# http://fulcrumgenomics.github.io/fgbio/tools/latest/ExtractBasecallingParamsForPicard.html

	CMD="singularity exec ${UMI_CONTAINER} java -jar"
		CMD=${CMD}" -Xmx10g"
		CMD=${CMD}" /fgbio/fgbio.jar"
	CMD=${CMD}" ExtractBasecallingParamsForPicard"
		CMD=${CMD}" --input=${IEM_SAMPLESHEET}"
		CMD=${CMD}" --bam=${CORE_PATH}/${PROJECT}/DEMUX_UMAP/BARCODES/${FCID}/RG_UMAP_BAMS/"
		CMD=${CMD}" --lanes ${LANE}"
	CMD=${CMD}" --output=${CORE_PATH}/${PROJECT}/DEMUX_UMAP/FCID_FILES/${FCID}/"

# write command line to file and execute the command line

	echo ${CMD} >> ${CORE_PATH}/${PROJECT}/COMMAND_LINES/${PROJECT}_DEMUX_command_lines.txt
	echo >> ${CORE_PATH}/${PROJECT}/COMMAND_LINES/${PROJECT}_DEMUX_command_lines.txt
	echo ${CMD} | bash

# check the exit signal at this point.

	SCRIPT_STATUS=$(echo $?)

# if exit does not equal 0 then exit with whatever the exit signal is at the end.
# also write to file that this job failed

	if
		[ "${SCRIPT_STATUS}" -ne 0 ]
	then
		echo ${HOSTNAME} ${JOB_NAME} ${USER} ${SCRIPT_STATUS} ${SGE_STDERR_PATH} \
		>> ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.csv
		exit ${SCRIPT_STATUS}
	fi

END_EXTRACT_BARCODES=$(date '+%s') # capture time process stops for wall clock tracking purposes.

# write wall clock times to file

	echo ${LANE},${PROJECT},D.XTRACT.BCL2SAM,${HOSTNAME},${START_EXTRACT_BARCODES},${END_EXTRACT_BARCODES} \
	>> ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/REPORTS/${LANE}.${PROJECT}.WALL.CLOCK.TIMES.csv

# write timestamp process ended to file

	echo Project ended at $(date) \
	>> ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/REPORTS/DEMUX_${LANE}_START_END_TIMESTAMP.txt

# exit with the signal from the program

	exit ${SCRIPT_STATUS}
