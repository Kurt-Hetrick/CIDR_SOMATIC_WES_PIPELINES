#!/usr/bin/env bash

###################
# INPUT VARIABLES #
###################

	QC_REPORT=$1
		QC_REPORT_NAME=$(basename ${QC_REPORT} .csv)
	ALLELE_FRACTION_CUTOFF=$2 # AS A FRACTION. THAT IS 0.10 IS 10%. DEFAULT IS 0.10. I think using 0.1 or 0.10 should be fine.

		# if there is no 2nd argument present then use the number for priority
			if
				[[ ! ${ALLELE_FRACTION_CUTOFF} ]]
			then
				ALLELE_FRACTION_CUTOFF="0.10"
			fi

	PRIORITY=$3 # optional. if no 2nd argument present then the default is -15

		# if there is no 2nd argument present then use the number for priority
			if
				[[ ! ${PRIORITY} ]]
			then
				PRIORITY="-15"
			fi

########################################################################
# CHANGE SCRIPT DIR TO WHERE YOU HAVE HAVE THE SCRIPTS BEING SUBMITTED #
########################################################################

	SUBMITTER_SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

	COMMON_SCRIPT_DIR="${SUBMITTER_SCRIPT_PATH}/paired_tumor_normal_scripts_common"

	GRCH38_SCRIPT_DIR="${SUBMITTER_SCRIPT_PATH}/paired_tumor_normal_scripts_grch38"

	# HG19_SCRIPT_DIR="${SUBMITTER_SCRIPT_PATH}/hg19_scripts"

##################
# CORE VARIABLES #
##################

	# Directory where sequencing projects are located

		CORE_PATH="/mnt/research/active"

	# Directory where NovaSeqa runs are located.

		NOVASEQ_REPO="/mnt/instrument_files/novaseq"

	# used for tracking in the read group header of the cram file

		PIPELINE_VERSION=$(git \
			--git-dir=${SUBMITTER_SCRIPT_PATH}/.git \
			--work-tree=${SUBMITTER_SCRIPT_PATH} log \
			--pretty=format:'%h' -n 1)

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

	# NUMBER OF PARALLELIZATION THREADS TO USE
	# ASSUMES JOB SLOT IS SET FOR 4 THREADS

		THREAD_COUNT="4"

	# Generate a list of active queue and remove the ones that I don't want to use

		STD_QUEUE_LIST=$(qstat -f -s r \
			| egrep -v "^[0-9]|^-|^queue|^ " \
			| cut -d @ -f 1 \
			| sort \
			| uniq \
			| egrep -v "all.q|cgc.q|programmers.q|rhel7.q|bigmem.q|bina.q|qtest.q|bigdata.q|uhoh.q|testcgc.q" \
			| datamash collapse 1 \
			| awk '{print $1}')

	# Generate a list of active queue and remove the ones that I don't want to use, leaving only AVX ones

		AVX_QUEUE_LIST=$(qstat -f -s r \
			| egrep -v "^[0-9]|^-|^queue|^ " \
			| cut -d @ -f 1 \
			| sort \
			| uniq \
			| egrep -v "all.q|cgc.q|programmers.q|rhel7.q|bigmem.q|bina.q|qtest.q|bigdata.q|uhoh.q|testcgc.q|prod.q|rnd.q" \
			| datamash collapse 1 \
			| awk '{print $1}')

	# QSUB ARGUMENTS LIST
		# set shell on compute node
		# start in current working directory
		# transfer submit node env to compute node
		# set SINGULARITY BINDPATH
		# set queues to submit to
		# set priority
		# combine stdout and stderr logging to same output file

			NON_QUEUE_QSUB_ARGS="-S /bin/bash" \
				NON_QUEUE_QSUB_ARGS=${NON_QUEUE_QSUB_ARGS}" -cwd" \
				NON_QUEUE_QSUB_ARGS=${NON_QUEUE_QSUB_ARGS}" -V" \
				NON_QUEUE_QSUB_ARGS=${NON_QUEUE_QSUB_ARGS}" -v SINGULARITY_BINDPATH=/mnt:/mnt" \
				NON_QUEUE_QSUB_ARGS=${NON_QUEUE_QSUB_ARGS}" -p ${PRIORITY}" \
				NON_QUEUE_QSUB_ARGS=${NON_QUEUE_QSUB_ARGS}" -j y"

			STD_QUEUE_QSUB_ARGS=${NON_QUEUE_QSUB_ARGS}" -q ${STD_QUEUE_LIST}"

			AVX_QUEUE_QSUB_ARGS=${NON_QUEUE_QSUB_ARGS}" -q ${AVX_QUEUE_LIST}"

#####################
# PIPELINE PROGRAMS #
#####################

	JAVA_1_8="/mnt/linuxtools/JAVA/jdk1.8.0_73/bin"
	LAB_QC_DIR="/mnt/linuxtools/CUSTOM_CIDR/EnhancedSequencingQCReport/0.1.1"
		# Copied from /mnt/research/tools/LINUX/CIDRSEQSUITE/pipeline_dependencies/QC_REPORT/EnhancedSequencingQCReport.jar
		# md5 f979bb4dc8d97113735ef17acd3a766e  EnhancedSequencingQCReport.jar

	UMI_CONTAINER="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/CONTAINERS/umi-0.0.2.simg"
		# uses gatk 4.3.0.0 as the base image
		### added the following to the base image
			# bwa-0.7.15
			# picard-2.27.5 (in /picard dir)
			# datamash-1.6
			# fgbio-2.0.2 (in /fgbio dir)

	ALIGNMENT_CONTAINER="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/CONTAINERS/ddl_ce_control_align-0.0.4.simg"
	# contains the following software and is on Ubuntu 16.04.5 LTS
		# gatk 4.0.11.0 (base image). also contains the following.
			# Python 3.6.2 :: Continuum Analytics, Inc.
				# samtools 0.1.19
				# bcftools 0.1.19
				# bedtools v2.25.0
				# bgzip 1.2.1
				# tabix 1.2.1
				# samtools, bcftools, bgzip and tabix will be replaced with newer versions.
				# R 3.2.5
					# dependencies = c("gplots","digest", "gtable", "MASS", "plyr", "reshape2", "scales", "tibble", "lazyeval")    # for ggplot2
					# getopt_1.20.0.tar.gz
					# optparse_1.3.2.tar.gz
					# data.table_1.10.4-2.tar.gz
					# gsalib_2.1.tar.gz
					# ggplot2_2.2.1.tar.gz
				# openjdk version "1.8.0_181"
				# /gatk/gatk.jar -> /gatk/gatk-package-4.0.11.0-local.jar
		# added
			# picard.jar 2.17.0 (as /gatk/picard.jar)
			# samblaster-v.0.1.24
			# sambamba-0.6.8
			# bwa-0.7.15
			# datamash-1.6
			# verifyBamID v1.1.3
			# samtools 1.10
			# bgzip 1.10
			# tabix 1.10
			# bcftools 1.10.2

	GATK_3_7_0_CONTAINER="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/CONTAINERS/gatk3-3.7-0.simg"
	# singularity pull docker://broadinstitute/gatk3:3.7-0
	# used for generating the depth of coverage reports.
		# comes with R 3.1.1 with appropriate packages needed to create gatk pdf output
		# also comes with some version of java 1.8
		# jar file is /usr/GenomeAnalysisTK.jar

	GATK_CONTAINER_4_2_2_0="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/CONTAINERS/gatk-4.2.2.0.simg"

	BQSR_CONTAINER="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/CONTAINERS/gatk-4.0.1.1.simg"

	CIDRSEQSUITE_7_5_0_DIR="/mnt/linuxtools/CIDRSEQSUITE/7.5.0"

	PICARD_LIFTOVER_CONTAINER="/mnt/research/tools/LINUX/00_GIT_REPO_KURT/CONTAINERS/picard-2.26.10.0.simg"

##################
# PIPELINE FILES #
##################

	CODING_BED="/mnt/research/tools/PIPELINE_FILES/GRCh38_aux_files/gencode24_primary_collapsed.bed"
		# md5 acda5ab9bebcb9520f5ec9670ea09432
	GENE_LIST="/mnt/research/tools/PIPELINE_FILES/GRCh38_aux_files/RefSeqAll_hg38_rCRS-MT.gatk.txt"
		# md5 f4f25673a83db2dda32791e6a00d9604
		# need to create a link detailing how this file was created
	CYTOBAND_BED="/mnt/research/tools/PIPELINE_FILES/GRCh38_aux_files/GRCh38.Cytobands.bed"
		# md5 cac717c6bc149001c013a3a6c594908d
		# note that I should put some code in here to ignore the header, ^#
		# this is from ucsc
	VERIFY_VCF="/mnt/research/tools/PIPELINE_FILES/GRCh38_aux_files/Omni25_genotypes_1525_samples_v2.b37.PASS.ALL.sites.hg38.liftover.vcf"
		# md5 d71b55cde492b722a95021a5fb5a4d83
	DBSNP="/mnt/research/tools/PIPELINE_FILES/GRCh38_aux_files/Homo_sapiens_assembly38.dbsnp138.vcf"
		# md5 f7e1ef5c1830bfb33675b9c7cbaa4868
	DBSNP_129="/mnt/research/tools/PIPELINE_FILES/GRCh38_aux_files/dbsnp_138.hg38.liftover.excluding_sites_after_129.vcf.gz"
		# md5 85f3e9f0d5f30de2a046594b4ab4de86
	VERACODE_CSV="/mnt/research/tools/LINUX/CIDRSEQSUITE/resources/Veracode_hg18_hg19.csv"
	MERGED_MENDEL_BED_FILE="/mnt/research/active/M_Valle_MD_SeqWholeExome_120417_1_GRCh38/BED_Files/BAITS_Merged_S03723314_S06588914_TwistCUEXmito.lift.hg38.merge.clean.bed"
		# md5 7a5a4d410172d7070118f351e8f0b729
	HG38_TO_HG19_CHAIN="/mnt/shared_resources/public_resources/liftOver_chain/hg38ToHg19.over.chain"
	HG19_REF="/mnt/research/tools/PIPELINE_FILES/GATK_resource_bundle/2.8/hg19/ucsc.hg19.fasta"
	HG19_DICT="/mnt/research/tools/PIPELINE_FILES/GATK_resource_bundle/2.8/hg19/ucsc.hg19.dict"
	MERGED_CUTTING_BED_FILE="/mnt/research/active/H_Cutting_CFTR_WGHum-SeqCustom_1_Reanalysis/BED_Files_hg38/H_Cutting_phase_1plus2_super_file.bed.lift.hg38.bed"
		# FOR REANALYSIS OF CUTTING'S PHASE AND PHASE 2 PROJECTS.
		# md5 37eb87348fc917fb5f916db20621155f
	GNOMAD_AF_FREQ="/mnt/research/tools/PIPELINE_FILES/gatk_somatic/hg38/somatic-hg38_af-only-gnomad.hg38.vcf.gz"
	REF_GENOME="/mnt/shared_resources/public_resources/GRCh38DH/GRCh38_full_analysis_set_plus_decoy_hla.fa"
		REF_DICT=$(echo "${REF_GENOME%.*}".dict)

##########################################################
##### GRAB COLUMN POSITIONS FOR HEADERS IN QC REPORT #####
##########################################################

	PROJECT_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="PROJECT") print i}}' ${QC_REPORT})

	BAIT_BED_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="BAIT_BED_FILE") print i}}' ${QC_REPORT})

	TARGET_BED_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="TARGET_BED_FILE") print i}}' ${QC_REPORT})

	SUBJECT_ID_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="Subject_ID") print i}}' ${QC_REPORT})

	SM_TAG_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="SM_TAG") print i}}' ${QC_REPORT})

#################################
##### MAKE A DIRECTORY TREE #####
#################################

###############################################
# make an array for each PROJECT in qc report #
###############################################
	# add a end of file is not present
	# remove carriage returns if not present 
	# remove blank lines if present
	# remove lines that only have whitespace

		CREATE_PROJECT_ARRAY ()
		{
			PROJECT_ARRAY=(`awk 1 ${QC_REPORT} \
				| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
				| awk -v PROJECT_COLUMN_POSITION="$PROJECT_COLUMN_POSITION" \
					-v BAIT_BED_COLUMN_POSITION="$BAIT_BED_COLUMN_POSITION" \
					-v TARGET_BED_COLUMN_POSITION="$TARGET_BED_COLUMN_POSITION" \
					'BEGIN {FS=","} \
					$PROJECT_COLUMN_POSITION=="'${PROJECT_NAME}'" \
					{print $PROJECT_COLUMN_POSITION,$BAIT_BED_COLUMN_POSITION,$TARGET_BED_COLUMN_POSITION}' \
				| sort \
				| uniq`)

			# 1 Project=the Seq Proj folder name
			SEQ_PROJECT=${PROJECT_ARRAY[0]}

			# 2 Bait Bed file
			PROJECT_BAIT_BED=${PROJECT_ARRAY[1]}

			# 3 Target bed file
			PROJECT_TARGET_BED=${PROJECT_ARRAY[2]}
		}

##################################
# project directory tree creator #
##################################

	MAKE_PROJ_DIR_TREE ()
	{
		mkdir -p \
		${CORE_PATH}/${SEQ_PROJECT}/{COMMAND_LINES,LOGS} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/{GATK_CALC_TUMOR_CONTAM,LAB_PREP_REPORTS,QC_REPORTS,QC_REPORT_PREP,RG_HEADER} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/{CONCORDANCE,CONCORDANCE_PAIRED} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/VCF_METRICS/MUTECT2/{BAIT,TARGET} \
		${CORE_PATH}/${SEQ_PROJECT}/TEMP/${QC_REPORT_NAME} \
		${CORE_PATH}/${SEQ_PROJECT}/VCF/MUTECT2/{STATS,READ_ORIENT_MODEL}
	}

##################################
# RUN STEPS TO DO PROJECT SET UP #
##################################

	for PROJECT_NAME in $(awk 1 ${QC_REPORT} \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
			| awk -v PROJECT_COLUMN_POSITION="$PROJECT_COLUMN_POSITION" \
				'BEGIN {FS=","} \
				NR>1 \
				{print $PROJECT_COLUMN_POSITION}' \
			| sort \
			| uniq);
	do
		CREATE_PROJECT_ARRAY
		MAKE_PROJ_DIR_TREE
	done

###########################################################
# CREATE AN ARRAY OF VARIABLES FOR EACH TUMOR SAMPLE TYPE #
###########################################################

	CREATE_TUMOR_SAMPLE_ARRAY ()
	{
		TUMOR_INDIVIDUAL_ARRAY=(`awk \
			-v PROJECT_COLUMN_POSITION="$PROJECT_COLUMN_POSITION" \
			-v BAIT_BED_COLUMN_POSITION="$BAIT_BED_COLUMN_POSITION" \
			-v TARGET_BED_COLUMN_POSITION="$TARGET_BED_COLUMN_POSITION" \
			-v SUBJECT_ID_COLUMN_POSITION="$SUBJECT_ID_COLUMN_POSITION" \
			-v SM_TAG_COLUMN_POSITION="$SM_TAG_COLUMN_POSITION" \
			'BEGIN {FS=",";OFS="\t"} \
			$SUBJECT_ID_COLUMN_POSITION=="'${PI_TUMOR_INDIVIDUAL_NAME}'" \
			{split($SUBJECT_ID_COLUMN_POSITION,SUBJECT,"_"); \
			print SUBJECT[1],SUBJECT[2],$SUBJECT_ID_COLUMN_POSITION,$SM_TAG_COLUMN_POSITION,$PROJECT_COLUMN_POSITION,\
			$BAIT_BED_COLUMN_POSITION,$TARGET_BED_COLUMN_POSITION}' \
		${QC_REPORT} \
			| sort \
			| uniq`)

		# 1: Project=the Seq Proj folder name

			TUMOR_INDIVIDUAL=${TUMOR_INDIVIDUAL_ARRAY[0]}

		# 2: Platform=type of sequencing chemistry matching SAM specification

			TISSUE_TYPE=${TUMOR_INDIVIDUAL_ARRAY[1]}

		# 2: Platform=type of sequencing chemistry matching SAM specification

			SUBMITTER_ID=${TUMOR_INDIVIDUAL_ARRAY[2]}

		# 2: Platform=type of sequencing chemistry matching SAM specification

			TUMOR_SM_TAG=${TUMOR_INDIVIDUAL_ARRAY[3]}

		# 2: Platform=type of sequencing chemistry matching SAM specification

			TUMOR_PROJECT=${TUMOR_INDIVIDUAL_ARRAY[4]}

		# 2: Platform=type of sequencing chemistry matching SAM specification

			BAIT_BED=${TUMOR_INDIVIDUAL_ARRAY[5]}

		# 2: Platform=type of sequencing chemistry matching SAM specification

			TARGET_BED=${TUMOR_INDIVIDUAL_ARRAY[6]}
	}

######################################################
# CREATE SAMPLE FOLDERS IN TEMP AND LOGS DIRECTORIES #
######################################################

	MAKE_SAMPLE_DIRECTORIES ()
	{
		mkdir -p \
		${CORE_PATH}/${TUMOR_PROJECT}/TEMP/${QC_REPORT_NAME}/${TUMOR_INDIVIDUAL} \
		${CORE_PATH}/${TUMOR_PROJECT}/LOGS/${TUMOR_INDIVIDUAL}
	}

##################################################################################
### fix common formatting problems in bed files ##################################
### create picard style interval files ###########################################
### DO PER SAMPLE ################################################################
##################################################################################

	FIX_BED_FILES ()
	{
		echo \
		qsub \
			${STD_QUEUE_QSUB_ARGS} \
		-N A01-FIX_BED_FILES_${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${TUMOR_PROJECT} \
			-o ${CORE_PATH}/${TUMOR_PROJECT}/LOGS/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}-${TUMOR_SM_TAG}-FIX_BED_FILES.log \
		${GRCH38_SCRIPT_DIR}/A01-FIX_BED_FILES.sh \
			${QC_REPORT} \
			${CORE_PATH} \
			${TUMOR_PROJECT} \
			${TUMOR_INDIVIDUAL} \
			${TUMOR_SM_TAG} \
			${REF_DICT} \
			${BAIT_BED} \
			${TARGET_BED}
	}

##############################################################################
### PERFORM CONCORDANCE BETWEEN THE TUMOR SEQ QC VCF AND NORMAL SEQ QC VCF ###
##############################################################################

	CONCORDANCE_HAPLOTYPE_CALLER_CALLS ()
	{
		echo \
		qsub \
			${STD_QUEUE_QSUB_ARGS} \
		-N B01-CONCORDANCE_HAPLOTYPE_CALLER_${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${TUMOR_PROJECT} \
			-o ${CORE_PATH}/${TUMOR_PROJECT}/LOGS/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_CONCORDANCE_TO_NORMAL_HAPLOTYPE_CALLER_TARGET.log \
		${COMMON_SCRIPT_DIR}/B01-CONCORDANCE_HAPLOTYPE_CALLER.sh \
			${UMI_CONTAINER} \
			${QC_REPORT} \
			${CORE_PATH} \
			${TUMOR_PROJECT} \
			${TUMOR_INDIVIDUAL} \
			${TUMOR_SM_TAG} \
			${TARGET_BED} \
			${SUBMIT_STAMP}
	}

#######################################################
# run mutect2 #########################################
# this runs MUCH slower on non-avx machines ###########
# this is intended to be scattered across chromosomes #
#######################################################

	CALL_MUTECT2 ()
	{
		echo \
		qsub \
			${AVX_QUEUE_QSUB_ARGS} \
		-N B02-MUTECT2_${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${TUMOR_PROJECT}_chr${CHROMOSOME} \
			-o ${CORE_PATH}/${TUMOR_PROJECT}/LOGS/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}-${TUMOR_SM_TAG}-MUTECT2_chr${CHROMOSOME}.log \
		-hold_jid A01-FIX_BED_FILES_${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${TUMOR_PROJECT} \
		${COMMON_SCRIPT_DIR}/B02-MUTECT2_SCATTER.sh \
			${UMI_CONTAINER} \
			${QC_REPORT} \
			${CORE_PATH} \
			${TUMOR_PROJECT} \
			${TUMOR_INDIVIDUAL} \
			${TUMOR_SM_TAG} \
			${REF_GENOME} \
			${GNOMAD_AF_FREQ} \
			${BAIT_BED} \
			chr${CHROMOSOME} \
			${SUBMIT_STAMP}
	}

###################################################
# MERGE THE MUTECT2 STATS FILE USED FOR FILTERING #
###################################################

	MERGE_MUTECT2_STATS ()
	{
		echo \
		qsub \
			${STD_QUEUE_QSUB_ARGS} \
		-N C01-MERGE_MUTECT2_STATS_${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${TUMOR_PROJECT} \
			-o ${CORE_PATH}/${TUMOR_PROJECT}/LOGS/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_MERGE_MUTECT2_STATS.log \
		${HOLD_ID_PATH_MERGE} \
		${COMMON_SCRIPT_DIR}/C01-MERGE_MUTECT2_STATS.sh \
			${UMI_CONTAINER} \
			${ALIGNMENT_CONTAINER} \
			${QC_REPORT} \
			${CORE_PATH} \
			${TUMOR_PROJECT} \
			${TUMOR_INDIVIDUAL} \
			${TUMOR_SM_TAG} \
			${BAIT_BED} \
			${SUBMIT_STAMP}
	}

###########################################################################
# LEARN THE READ ORIENTATION MODEL (FOR FFPE) BY GATHERING MUTECT2 OUTPUT #
###########################################################################

	LEARN_READ_ORIENTATION_MODEL ()
	{
		echo \
		qsub \
			${STD_QUEUE_QSUB_ARGS} \
		-N C02-LEARN_READ_ORIENTATION_MODEL_${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${TUMOR_PROJECT} \
			-o ${CORE_PATH}/${TUMOR_PROJECT}/LOGS/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_LEARN_READ_ORIENTATION_MODEL.log \
		${HOLD_ID_PATH_MERGE} \
		${COMMON_SCRIPT_DIR}/C02-LEARN_READ_ORIENTATION_MODEL.sh \
			${UMI_CONTAINER} \
			${ALIGNMENT_CONTAINER} \
			${QC_REPORT} \
			${CORE_PATH} \
			${TUMOR_PROJECT} \
			${TUMOR_INDIVIDUAL} \
			${TUMOR_SM_TAG} \
			${BAIT_BED} \
			${SUBMIT_STAMP}
	}

###########################
# CONCATENATE MUTECT2 VCF #
###########################

	CONCATENATE_RAW_MUTECT2_VCF ()
	{
		echo \
		qsub \
			${STD_QUEUE_QSUB_ARGS} \
		-N C03-CONCATENATE_RAW_MUTECT2_VCF_${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${TUMOR_PROJECT} \
			-o ${CORE_PATH}/${TUMOR_PROJECT}/LOGS/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_CONCATENATE_RAW_MUTECT2_VCF.log \
		${HOLD_ID_PATH_MERGE} \
		${COMMON_SCRIPT_DIR}/C03-CONCATENATE_RAW_MUTECT2_VCF.sh \
			${GATK_3_7_0_CONTAINER} \
			${ALIGNMENT_CONTAINER} \
			${QC_REPORT} \
			${CORE_PATH} \
			${TUMOR_PROJECT} \
			${TUMOR_INDIVIDUAL} \
			${TUMOR_SM_TAG} \
			${REF_GENOME} \
			${BAIT_BED} \
			${SUBMIT_STAMP}
	}

######################
# FILTER MUTECT2 VCF #
######################

	FILTER_MUTECT2_VCF ()
	{
		echo \
		qsub \
			${STD_QUEUE_QSUB_ARGS} \
		-N D01-FILTER_MUTECT2_${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${TUMOR_PROJECT} \
			-o ${CORE_PATH}/${TUMOR_PROJECT}/LOGS/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_FILTER_MUTECT2_VCF.log \
		-hold_jid C01-MERGE_MUTECT2_STATS_${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${TUMOR_PROJECT},C02-LEARN_READ_ORIENTATION_MODEL_${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${TUMOR_PROJECT},C03-CONCATENATE_RAW_MUTECT2_VCF_${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${TUMOR_PROJECT} \
		${COMMON_SCRIPT_DIR}/D01-FILTER_MUTECT2_VCF.sh \
			${UMI_CONTAINER} \
			${QC_REPORT} \
			${CORE_PATH} \
			${TUMOR_PROJECT} \
			${TUMOR_INDIVIDUAL} \
			${TUMOR_SM_TAG} \
			${REF_GENOME} \
			${ALLELE_FRACTION_CUTOFF} \
			${SUBMIT_STAMP}
	}

###############################
# ON BAIT MUTECT2 VCF METRICS #
###############################

	VCF_MUTECT2_METRICS_BAIT ()
	{
		echo \
		qsub \
			${STD_QUEUE_QSUB_ARGS} \
		-N E01-VCF_MUTECT2_METRICS_BAIT_${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${TUMOR_PROJECT} \
			-o ${CORE_PATH}/${TUMOR_PROJECT}/LOGS/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_VCF_MUTECT2_METRICS_BAIT.log \
		-hold_jid D01-FILTER_MUTECT2_${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${TUMOR_PROJECT} \
		${COMMON_SCRIPT_DIR}/E01-VCF_MUTECT2_METRICS_BAIT.sh \
			${UMI_CONTAINER} \
			${QC_REPORT} \
			${CORE_PATH} \
			${TUMOR_PROJECT} \
			${TUMOR_INDIVIDUAL} \
			${TUMOR_SM_TAG} \
			${REF_DICT} \
			${BAIT_BED} \
			${DBSNP} \
			${THREAD_COUNT} \
			${SUBMIT_STAMP}
	}

#################################
# ON TARGET MUTECT2 VCF METRICS #
#################################

	VCF_MUTECT2_METRICS_TARGET ()
	{
		echo \
		qsub \
			${STD_QUEUE_QSUB_ARGS} \
		-N E02-VCF_MUTECT2_METRICS_TARGET_${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${TUMOR_PROJECT} \
			-o ${CORE_PATH}/${TUMOR_PROJECT}/LOGS/${TUMOR_INDIVIDUAL}/${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_VCF_MUTECT2_METRICS_TARGET.log \
		-hold_jid D01-FILTER_MUTECT2_${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${TUMOR_PROJECT} \
		${COMMON_SCRIPT_DIR}/E02-VCF_MUTECT2_METRICS_TARGET.sh \
			${UMI_CONTAINER} \
			${QC_REPORT} \
			${CORE_PATH} \
			${TUMOR_PROJECT} \
			${TUMOR_INDIVIDUAL} \
			${TUMOR_SM_TAG} \
			${REF_DICT} \
			${TARGET_BED} \
			${DBSNP} \
			${THREAD_COUNT} \
			${SUBMIT_STAMP}
	}


#################################
### EXECUTE ALL OF THE THINGS ###
#################################

	for PI_TUMOR_INDIVIDUAL_NAME in \
		$(awk \
			-v SUBJECT_ID_COLUMN_POSITION="$SUBJECT_ID_COLUMN_POSITION" \
			'BEGIN {FS=",";OFS="\t"} \
			{split($SUBJECT_ID_COLUMN_POSITION,SUBJECT,"_"); \
			print $SUBJECT_ID_COLUMN_POSITION,SUBJECT[2]}' \
		${QC_REPORT} \
		| awk '$2=="T"||$2=="C"||$2=="S" \
			{print $1}' \
		| sort \
		| uniq)
	do
		CREATE_TUMOR_SAMPLE_ARRAY
		MAKE_SAMPLE_DIRECTORIES
		FIX_BED_FILES
		echo sleep 0.1s
		CONCORDANCE_HAPLOTYPE_CALLER_CALLS
		echo sleep 0.1s

		HOLD_ID_PATH_MERGE="-hold_jid "

		for CHROMOSOME in $(sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
			${CORE_PATH}/${TUMOR_PROJECT}/BED_Files/${BAIT_BED}.bed \
			| sed -r 's/[[:space:]]+/\t/g' \
			| sed 's/chr//g' \
			| egrep "^[0-9]|^X|^Y" \
			| cut -f 1 \
			| sort -V \
			| uniq \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				collapse 1 \
			| sed 's/,/ /g');
		do
			CALL_MUTECT2
			echo sleep 0.1s

			HOLD_ID_PATH_MERGE="${HOLD_ID_PATH_MERGE}B02-MUTECT2_${TUMOR_INDIVIDUAL}_${TUMOR_SM_TAG}_${TUMOR_PROJECT}_chr${CHROMOSOME},"

			HOLD_ID_PATH_MERGE=$(echo ${HOLD_ID_PATH_MERGE} | sed 's/@/_/g')

		done

			MERGE_MUTECT2_STATS
			echo sleep 0.1s
			LEARN_READ_ORIENTATION_MODEL
			echo sleep 0.1s
			CONCATENATE_RAW_MUTECT2_VCF
			echo sleep 0.1s
			FILTER_MUTECT2_VCF
			echo sleep 0.1s
			VCF_MUTECT2_METRICS_BAIT
			echo sleep 0.1s
			VCF_MUTECT2_METRICS_TARGET
			echo sleep 0.1s
	done

# keep this b/c I think I'm going to need it later

# $(awk \
# 			-v SUBJECT_ID_COLUMN_POSITION="$SUBJECT_ID_COLUMN_POSITION" \
# 			'BEGIN {FS=",";OFS="\t"} \
# 			NR>1 \
# 			$SUBJECT_ID_COLUMN_POSITION ~ /[_]T$/ || $SUBJECT_ID_COLUMN_POSITION ~ /[_]N$/ \
# 			{split($SUBJECT_ID_COLUMN_POSITION,SUBJECT,"_"); \
# 			print SUBJECT[1],SUBJECT[2]' \
# 		${QC_REPORT} \
# 		awk '$2=="T"||$2=="C"||$2=="S" \
# 			{print $1}' \
# 		| sort \
# 		| uniq)

# GENERATE A LIST OF TUMOR SAMPLES.
# I think this is the way that I will want to go after the pilot, but for the pilot. I don't think I can.

# 	for TUMOR_INDIVIDUAL in \
# 		$(awk \
# 			-v SUBJECT_ID_COLUMN_POSITION="$SUBJECT_ID_COLUMN_POSITION" \
# 			'BEGIN {FS=",";OFS="\t"} \
# 			NR>1 \
# 			$SUBJECT_ID_COLUMN_POSITION ~ /[_]T$/ || \
# 			$SUBJECT_ID_COLUMN_POSITION ~ /[_]C$/ || $SUBJECT_ID_COLUMN_POSITION ~ /[_]S$/ \
# 			{split($SUBJECT_ID_COLUMN_POSITION,SUBJECT,"_"); \
# 			print SUBJECT[1],SUBJECT[2]' \
# 		${QC_REPORT} \
# 		awk '$2=="T"||$2=="C"||$2=="S" \
# 			{print $1}' \
# 		| sort \
# 		| uniq)
# 	do
# 		PROJECT_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="PROJECT") print i}}' ${QC_REPORT})

# 		BAIT_BED_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="BAIT_BED_FILE") print i}}' ${QC_REPORT})

# 			BAIT_BED="${CORE_PATH}/${}/${TUMOR_INDIVIDUAL}-${TUMOR_SM_TAG}"

# 		TARGET_BED_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="TARGET_BED_FILE") print i}}' ${QC_REPORT})

# 		SUBJECT_ID_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="Subject_ID") print i}}' ${QC_REPORT})

# 		SM_TAG_COLUMN_POSITION=$(awk 'BEGIN {FS=","} NR==1 {for (i=1; i<=NF; ++i) {if ($i=="SM_TAG") print i}}' ${QC_REPORT})

# 		# create variables for gathers starting with sge -hold_jid argument

# 			HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER="-hold_jid "
# 			HOLD_ID_PATH_GENOTYPE_GVCF_GATHER="-hold_jid "

# 		for CHROMOSOME in \
# 			$(sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' ${BAIT_BED} \
# 				| sed -r 's/[[:space:]]+/\t/g' \
# 				| sed 's/chr//g' \
# 				| egrep "^[0-9]|^X|^Y" \
# 				| cut -f 1 \
# 				| sort -V \
# 				| uniq \
# 				| singularity exec ${ALIGNMENT_CONTAINER} datamash \
# 					collapse 1 \
# 			| sed 's/,/ /g');
# 		do
# 			# do haplotype caller and genotype gvcf scatter
# 				CALL_HAPLOTYPE_CALLER
# 				echo sleep 0.1s
# 				CALL_GENOTYPE_GVCF
# 				echo sleep 0.1s
# 		done
# done


# # GET THE SM_TAG FOR A SCROLLS TUMOR SAMPLE (This is specific for DeVivo)




# for NORMAL_INDIVIDUAL in \
# 	$(awk \
# 		-v SUBJECT_ID_COLUMN_POSITION="$SUBJECT_ID_COLUMN_POSITION" \
# 		'BEGIN {FS=",";OFS="\t"} \
# 		NR>1 \
# 		$SUBJECT_ID_COLUMN_POSITION ~ /[_]T$/ || $SUBJECT_ID_COLUMN_POSITION ~ /[_]N$/ \
# 		{split($SUBJECT_ID_COLUMN_POSITION,SUBJECT,"_"); \
# 		print SUBJECT[1],SUBJECT[2]' \
# 	${QC_REPORT} \
# 	awk '$2=="N" \
# 		{print $1}' \
# 	| sort \
# 	| uniq) \
# do
# 	CALL_MUTECT2_TUMOR_NORMAL_SINGLE_SCATTER
# done

# awk \
# 	-v PROJECT_COLUMN_POSITION="$PROJECT_COLUMN_POSITION" \
# 	-v SUBJECT_ID_COLUMN_POSITION="$SUBJECT_ID_COLUMN_POSITION" \
# 	-v SM_TAG_COLUMN_POSITION="$SM_TAG_COLUMN_POSITION" \
# 	-v BAIT_BED_COLUMN_POSITION="$BAIT_BED_COLUMN_POSITION" \
# 	-v TARGET_BED_COLUMN_POSITION="$TARGET_BED_COLUMN_POSITION" \
# 	'BEGIN {FS=",";OFS="\t"} \
# 	NR>1 \
# 	$SUBJECT_ID_COLUMN_POSITION ~ /[_]T$/ || $SUBJECT_ID_COLUMN_POSITION ~ /[_]N$/ \
# 	{split($SUBJECT_ID_COLUMN_POSITION,SUBJECT,"_"); \
# 	print SUBJECT[1],SUBJECT[2],$SM_TAG_COLUMN_POSITION,$PROJECT_COLUMN_POSITION,$BAIT_BED_COLUMN_POSITION,$TARGET_BED_COLUMN_POSITION}' \
# ${QC_REPORT} \
# | awk '$1==${"'TUMOR_INDIVIDUAL'"} && $2=="T" \
# {print }

# ######################################
# # GENERATE QC REPORT STUB FOR SAMPLE #
# ######################################

# QC_REPORT_PREP ()
# {
# echo \
# qsub \
# ${STD_QUEUE_QSUB_ARGS} \
# -N X1_${SGE_SM_TAG} \
# -hold_jid \
# E01-RUN_VERIFYBAMID_${SGE_SM_TAG}_${TUMOR_PROJECT},\
# E03-DOC_CODING_${SGE_SM_TAG}_${TUMOR_PROJECT},\
# E04-DOC_BAIT_${SGE_SM_TAG}_${TUMOR_PROJECT},\
# E05-A01-CHROM_DEPTH_${SGE_SM_TAG}_${TUMOR_PROJECT},\
# F02-COLLECT_MULTIPLE_METRICS_${SGE_SM_TAG}_${TUMOR_PROJECT},\
# F03-COLLECT_HS_METRICS_${SGE_SM_TAG}_${TUMOR_PROJECT},\
# F04-A01-GATK_CALC_TUMOR_CONTAM_${SGE_SM_TAG}_${TUMOR_PROJECT},\
# E06-A01-CAT_VERIFYBAMID_AUTO_${SGE_SM_TAG}_${TUMOR_PROJECT},\
# J01-A04-A01-A01-SNV_TARGET_PASS_CONCORDANCE_${SGE_SM_TAG}_${TUMOR_PROJECT},\
# J01-A01-VCF_METRICS_BAIT_QC_${SGE_SM_TAG}_${TUMOR_PROJECT},\
# J01-A02-VCF_METRICS_TARGET_QC_${SGE_SM_TAG}_${TUMOR_PROJECT},\
# J01-A03-VCF_METRICS_TITV_QC_${SGE_SM_TAG}_${TUMOR_PROJECT} \
# -o ${CORE_PATH}/${TUMOR_PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-QC_REPORT_PREP_QC.log \
# ${COMMON_SCRIPT_DIR}/X01-QC_REPORT_PREP.sh \
# ${ALIGNMENT_CONTAINER} \
# ${CORE_PATH} \
# ${TUMOR_PROJECT} \
# ${SM_TAG} \
# ${SAMPLE_SHEET} \
# ${SUBMIT_STAMP}
# }

# ##########################################################
# # RUN STEPS TO DO VCF RELATED METRICS AND QC REPORT PREP #
# ##########################################################

# 	for SM_TAG in $(awk 1 ${SAMPLE_SHEET} \
# 		| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
# 		| awk 'BEGIN {FS=","} \
# 			NR>1 \
# 			{print $8}' \
# 		| sort \
# 		| uniq);
# 	do
# 		CREATE_SAMPLE_ARRAY
# 		EXTRACT_SNV
# 		echo sleep 0.1s
# 		EXTRACT_INDEL_AND_MIXED
# 		echo sleep 0.1s
# 		FILTER_SNV
# 		echo sleep 0.1s
# 		FILTER_INDEL_AND_MIXED
# 		echo sleep 0.1s
# 		COMBINE_FILTERED_VCF_FILES
# 		echo sleep 0.1s
# 		EXTRACT_ON_TARGET_PASS_SNV
# 		echo sleep 0.1s
# 		LIFTOVER_TARGET_PASS_SNV
# 		echo sleep 0.1s
# 		TARGET_PASS_SNV_CONCORDANCE
# 		echo sleep 0.1s
# 		VCF_METRICS_BAIT
# 		echo sleep 0.1s
# 		VCF_METRICS_TARGET
# 		echo sleep 0.1s
# 		VCF_METRICS_TITV
# 		echo sleep 0.1s
# 		QC_REPORT_PREP
# 		echo sleep 0.1
# 	done

# #############################
# ##### END PROJECT TASKS #####
# #############################

# # build hold id for qc report prep per sample, per project

# 	BUILD_HOLD_ID_PATH_PROJECT_WRAP_UP ()
# 	{
# 		HOLD_ID_PATH="-hold_jid "

# 		for SM_TAG in $(awk 1 ${SAMPLE_SHEET} \
# 			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
# 			| awk 'BEGIN {FS=","} \
# 				$1=="'${TUMOR_PROJECT}'" \
# 				{print $8}' \
# 			| sort \
# 			| uniq);
# 		do
# 			CREATE_SAMPLE_ARRAY
# 			HOLD_ID_PATH="${HOLD_ID_PATH}X1_${SGE_SM_TAG},"
# 			HOLD_ID_PATH=`echo ${HOLD_ID_PATH} | sed 's/@/_/g'`
# 		done
# 	}

# # run end project functions (qc report, file clean-up) for each project

# 	PROJECT_WRAP_UP ()
# 	{
# 		echo \
# 		qsub \
# 			${STD_QUEUE_QSUB_ARGS} \
# 			-m e \
# 			-M khetric1@jhmi.edu \
# 		-N X01-X01-END_PROJECT_TASKS_${TUMOR_PROJECT} \
# 			-o ${CORE_PATH}/${TUMOR_PROJECT}/LOGS/${TUMOR_PROJECT}-END_PROJECT_TASKS.log \
# 		${HOLD_ID_PATH}A00-LAB_PREP_METRICS_${TUMOR_PROJECT} \
# 		${GRCH38_SCRIPT_DIR}/X01-X01-END_PROJECT_TASKS.sh \
# 			${CORE_PATH} \
# 			${ALIGNMENT_CONTAINER} \
# 			${TUMOR_PROJECT} \
# 			${SAMPLE_SHEET} \
# 			${SUBMITTER_SCRIPT_PATH} \
# 			${SUBMITTER_ID} \
# 			${SUBMIT_STAMP}
# 	}

# # final loop

# 	for PROJECT in $(awk 1 ${SAMPLE_SHEET} \
# 			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
# 			| awk 'BEGIN {FS=","} \
# 				NR>1 \
# 				{print $1}' \
# 			| sort \
# 			| uniq);
# 	do
# 		BUILD_HOLD_ID_PATH_PROJECT_WRAP_UP
# 		PROJECT_WRAP_UP
# 	done

# EMAIL WHEN DONE SUBMITTING

# printf "${SAMPLE_SHEET}\nhas finished submitting at\n`date`\nby `whoami`" \
# 	| mail -s "${PERSON_NAME} has submitted CIDR.WES.QC.SUBMITTER.GRCH38.sh" \
# 		${SEND_TO}
