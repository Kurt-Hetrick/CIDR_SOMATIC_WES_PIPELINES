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
		RUN_SPLIT=$(basename ${RUN_FOLDER} \
			| awk '{split($0,runbc,"_"); print runbc[2]":"runbc[3]":"}')
		RUN_BARCODE=${RUN_SPLIT}${FCID}
	PROJECT=$4
	LANE=$5
	SAMPLE_SHEET=$6
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$7
	FCID=$8
	MISMATCH=$9
	NO_CALL=${10}

START_EXTRACT_BARCODES=$(date '+%s') # capture time process starts for wall clock tracking purposes.

	# if any part of pipe fails set exit to non-zero

		set -o pipefail

# FIRST Extract barcodes
#https://software.broadinstitute.org/gatk/documentation/tooldocs/4.0.5.2/picard_illumina_ExtractIlluminaBarcodes.php
#num_processors can be tuned to the runtime environment by exposing to command line args if needed.

	sort -k 1,1 ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/BARCODES/${FCID}/BARCODES/s_${LANE}_????_barcode.txt \
		| singularity exec ${UMI_CONTAINER} datamash \
			-g 1 \
			count 1 \
		| sort -k 2,2nr \
		| awk 'BEGIN {OFS="\t"} {print substr($1,1,8),substr($1,9,8),$2}' \
		| awk '{print "'${FCID}'","'${LANE}'",$0,"'${MISMATCH}'","'${NO_CALL}'"}' \
		| awk 'BEGIN {print "FLOWCELL","LANE","INDEX1","INDEX2","COUNT","MISMATCHES_ALLOWED","NOCALLS_ALLOWED"} \
			$5>=1000 \
			{print $0}' \
		| sed 's/ /\t/g' \
	>| ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/REPORTS/BARCODE_SUMMARY/${FCID}_${LANE}_barcodes_found_summary.txt \
		&& \
	rm -rvf ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/BARCODES/${FCID}/BARCODES/s_${LANE}_????_barcode.txt

	# sort -k 1,1 ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/BARCODES/${FCID}/BARCODES/s_${LANE}_????_barcode.txt \
	# 	| singularity exec ${UMI_CONTAINER} datamash \
	# 		-g 1 \
	# 		count 1 \
	# 	| sort -k 2,2nr \
	# 	| awk 'BEGIN {OFS="\t"} {print substr($1,1,8),substr($1,9,8),$2}' \
	# 	| awk '{print "'${FCID}'","'${LANE}'",$0,"'${MISMATCH}'","'${NO_CALL}'"}' \
	# 	| sed 's/ /\t/g' \
	# 	| awk 'BEGIN {print "FLOWCELL","LANE","INDEX1","INDEX2","COUNT","MISMATCHES_ALLOWED","NOCALLS_ALLOWED"} \
	# 		{print $0}' \
	# >| ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/REPORTS/BARCODE_SUMMARY/${FCID}_${LANE}_barcodes_found_summary.txt

# write command line to file and execute the command line

	# echo ${CMD} >> ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/COMMAND_LINES/${PROJECT}_DEMUX_command_lines.txt
	# echo >> ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/COMMAND_LINES/${PROJECT}_DEMUX_command_lines.txt
	# echo ${CMD} | bash

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

END_EXTRACT_BARCODES=$(date '+%s')

# write wall clock times to file

	echo ${LANE},${PROJECT},D.XTRACT.BARCODES,${HOSTNAME},${START_EXTRACT_BARCODES},${END_EXTRACT_BARCODES} \
	>> ${CORE_PATH}/${PROJECT}/DEMUX_UMAP/REPORTS/${LANE}.${PROJECT}.WALL.CLOCK.TIMES.csv

# exit with the signal from the program

	exit ${SCRIPT_STATUS}
