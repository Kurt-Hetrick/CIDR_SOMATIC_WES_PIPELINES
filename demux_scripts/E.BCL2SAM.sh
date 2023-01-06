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
	RUN_FOLDER=$3
	PROJECT=$4
	LANE=$5
	SAMPLE_SHEET=$6
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$7
	READ_STRUCTURE=$8
	FCID=$9
	RUN_FOLDER_NAME=${10} # 146T8B9M8B146T

		RUN_SPLIT=$(echo ${RUN_FOLDER_NAME} \
			| awk '{split($0,runbc,"_"); print runbc[2]":"runbc[3]":"}')
		RUN_BARCODE=${RUN_SPLIT}${FCID}
		# Try limiting JVM to FreeMem -50g to avoid pegging the host
		FREE_MEMG=$(awk '/MemAvailable/ { printf "%.0f", ($2/1024/1024)-50}' /proc/meminfo)

START_BCL2SAM=$(date '+%s')

	echo Project started at $(date) \
	>> ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/REPORTS/DEMUX_${LANE}_START_END_TIMESTAMP.txt

		# THEN convert BCL to umapped BAM using read structure to add the UMI into the RX/UX tags.
		#num_processors can be tuned to the runtime environment by exposing to command line args if needed.
		#https://software.broadinstitute.org/gatk/documentation/tooldocs/4.0.5.2/picard_illumina_IlluminaBasecallsToSam.php
		# NOTE: ADAPTERS_TO_CHECK has been deprecated which is why it is not in here, but in the IDT webinar.

			CMD="singularity exec ${UMI_CONTAINER} java -jar"
				CMD=${CMD}" -Xmx${FREE_MEMG}g"
				CMD=${CMD}" /picard/picard.jar"
			CMD=${CMD}" IlluminaBasecallsToSam"
				CMD=${CMD}" BASECALLS_DIR=${RUN_FOLDER}/Data/Intensities/BaseCalls"
				CMD=${CMD}" BARCODES_DIR=${CORE_PATH}/${PROJECT}/DEMUX_UMAP/BARCODES/${FCID}/BARCODES/"
				CMD=${CMD}" READ_STRUCTURE=${READ_STRUCTURE}"
				CMD=${CMD}" LANE=${LANE}"
				CMD=${CMD}" NUM_PROCESSORS= -15"
				CMD=${CMD}" LIBRARY_PARAMS=${CORE_PATH}/${PROJECT}/DEMUX_UMAP/FCID_FILES/${FCID}/library_params.${LANE}.txt"
				CMD=${CMD}" MOLECULAR_INDEX_TAG=RX"
				CMD=${CMD}" RUN_BARCODE=${RUN_BARCODE}"
				CMD=${CMD}" READ_GROUP_ID=${FCID}_${LANE}"

# write command line to file and execute the command line

	echo ${CMD} >> ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/COMMAND_LINES/${LANE}.COMMAND.LINES.txt
	echo >> ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/COMMAND_LINES/${LANE}.COMMAND.LINES.txt
	echo ${CMD} | bash

	# check the exit signal at this point.

		SCRIPT_STATUS=$(echo $?)

	# if exit does not equal 0 then exit with whatever the exit signal is at the end.
	# also write to file that this job failed
    #JOB_NAME, USER and SGE_STDERR_PATH are internal variables to the cluster environment

		if
			[["${SCRIPT_STATUS}" -ne 0 ]]
		then
			echo ${HOSTNAME} ${JOB_NAME} ${USER} ${SCRIPT_STATUS} ${SGE_STDERR_PATH} \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}_${SUBMIT_STAMP}_ERRORS.csv
			exit ${SCRIPT_STATUS}
		fi

END_BCL2SAM=$(date '+%s')

# write wall clock times to file

	echo ${LANE},${PROJECT},E.BCL2SAM,${HOSTNAME},${START_BCL2SAM},${END_BCL2SAM} \
	>> ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/REPORTS/${LANE}.${PROJECT}.WALL.CLOCK.TIMES.csv

# write timestamp process ended to file

	echo Project ended at $(date) \
	>> ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/REPORTS/DEMUX_${LANE}_START_END_TIMESTAMP.txt

# exit with the signal from the program

	exit ${SCRIPT_STATUS}