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
	# 146T8B9M8B146T
	RUN_SPLIT=`echo ${RUN_FOLDER_NAME} | awk '{split($0,runbc,"_"); print runbc[2]":"runbc[3]":"}'`
	RUN_BARCODE=${RUN_SPLIT}${FCID}
	# Try limiting JVM to FreeMem -50g to avoid pegging the host
	FREE_MEMG=`awk '/MemAvailable/ { printf "%.0f", ($2/1024/1024)-50}' /proc/meminfo`

START_EXTRACT_BARCODES=`date '+%s'`

echo Project started at `date` >> ${CORE_PATH}/${PROJECT}"/DEMUX_UMAP/REPORTS/DEMUX_"${LANE}"_START_END_TIMESTAMP.txt"

	# FIRST Extract barcodes
    #https://software.broadinstitute.org/gatk/documentation/tooldocs/4.0.5.2/picard_illumina_ExtractIlluminaBarcodes.php
    #num_processors can be tuned to the runtime environment by exposing to command line args if needed.
	${JAVA_1_8}/java -Xmx${FREE_MEMG}g -jar ${PICARD_DIR}/picard.jar ExtractIlluminaBarcodes \
		BASECALLS_DIR=${RUN_FOLDER}/Data/Intensities/BaseCalls \
		BARCODE_FILE=${CORE_PATH}/${PROJECT}/DEMUX_UMAP/FCID_FILES/${FCID}/barcode_params.${LANE}.txt \
		READ_STRUCTURE=${READ_STRUCTURE} \
		LANE=${LANE} \
		NUM_PROCESSORS= -15 \
		OUTPUT_DIR=${CORE_PATH}/${PROJECT}/DEMUX_UMAP/BARCODES/${FCID}/BARCODES/ \
		METRICS_FILE=${CORE_PATH}/${PROJECT}/DEMUX_UMAP/REPORTS/DEMUX/${FCID}/"lane_"${LANE}"_barcode_metrics.txt"

	# check the exit signal at this point.

		SCRIPT_STATUS=`echo $?`

	# if exit does not equal 0 then exit with whatever the exit signal is at the end.
	# also write to file that this job failed
    #JOB_NAME, USER and SGE_STDERR_PATH are internal variables to the cluster environment
			if [["$SCRIPT_STATUS" -ne 0 ]]
			 then
				echo `hostname` ${JOB_NAME} ${USER} ${SCRIPT_STATUS} ${SGE_STDERR_PATH} \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}"_"${SUBMIT_STAMP}"_ERRORS.csv"
				exit ${SCRIPT_STATUS}
			fi

END_EXTRACT_BARCODES=`date '+%s'`

#After running these jobs, print to a command line file for tracking.
echo ${LANE}","${PROJECT}",D.XTRACT.BARCODES,"`hostname`","${START_EXTRACT_BARCODES}","${END_EXTRACT_BARCODES} \
>> ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/REPORTS/${LANE}"."${PROJECT}".WALL.CLOCK.TIMES.csv"

echo ${JAVA_1_8}/java -Xmx${FREE_MEMG}g -jar ${PICARD_DIR}/picard.jar ExtractIlluminaBarcodes \
		BASECALLS_DIR=${RUN_FOLDER}/Data/Intensities/BaseCalls \
		BARCODE_FILE=${CORE_PATH}/${PROJECT}/DEMUX_UMAP/FCID_FILES/${FCID}/barcode_params.${LANE}.txt \
		READ_STRUCTURE=${READ_STRUCTURE} \
		LANE=${LANE} \
		NUM_PROCESSORS= -15 \
		OUTPUT_DIR=${CORE_PATH}/${PROJECT}/DEMUX_UMAP/BARCODES/${FCID}/BARCODES/ \
		METRICS_FILE=${CORE_PATH}/${PROJECT}/DEMUX_UMAP/REPORTS/DEMUX/${FCID}/"lane_"${LANE}"_barcode_metrics.txt"  >> ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/COMMAND_LINES/${LANE}".COMMAND.LINES.txt"

echo >> ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/COMMAND_LINES/${LANE}".COMMAND.LINES.txt"

# if file is not present exit !=0

ls ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/REPORTS/DEMUX/${FCID}/"lane_"${LANE}"_barcode_metrics.txt"

echo Project ended at `date` >> ${CORE_PATH}/${PROJECT}"/DEMUX_UMAP/REPORTS/DEMUX_"${LANE}"_START_END_TIMESTAMP.txt"