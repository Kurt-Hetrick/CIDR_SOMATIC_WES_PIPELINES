#!/usr/bin/env bash

###################
# INPUT VARIABLES #
###################

	SAMPLE_SHEET=$1
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	PRIORITY=$2 # optional. if no 2nd argument present then the default is -15

		# if there is no 2nd argument present then use the number for priority
			if [[ ! ${PRIORITY} ]]
				then
				PRIORITY="-15"
			fi

########################################################################
# CHANGE SCRIPT DIR TO WHERE YOU HAVE HAVE THE SCRIPTS BEING SUBMITTED #
########################################################################

	SUBMITTER_SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

	COMMON_SCRIPT_DIR="${SUBMITTER_SCRIPT_PATH}/common_scripts"

	GRCH37_SCRIPT_DIR="${SUBMITTER_SCRIPT_PATH}/grch37_scripts"

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

	# Generate a list of active queue and remove the ones that I don't want to use

		QUEUE_LIST=$(qstat -f -s r \
			| egrep -v "^[0-9]|^-|^queue|^ " \
			| cut -d @ -f 1 \
			| sort \
			| uniq \
			| egrep -v "all.q|cgc.q|programmers.q|rhel7.q|bigmem.q|bina.q|qtest.q|bigdata.q|uhoh.q|testcgc.q" \
			| datamash collapse 1 \
			| awk '{print $1}')

		# just show how to exclude a node
			# QUEUE_LIST=`qstat -f -s r \
			# 	| egrep -v "^[0-9]|^-|^queue" \
			# 	| cut -d @ -f 1 \
			# 	| sort \
			# 	| uniq \
			# 	| egrep -v "all.q|cgc.q|programmers.q|rhel7.q|bigmem.q|bina.q|qtest.q" \
			# 	| datamash collapse 1 \
			# 	| awk '{print $1,"-l \x27hostname=!DellR730-03\x27"}'`

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

	JAVA_1_8="/mnt/linuxtools/JAVA/jdk1.8.0_73/bin"
	LAB_QC_DIR="/mnt/linuxtools/CUSTOM_CIDR/EnhancedSequencingQCReport/0.1.1"
		# Copied from /mnt/research/tools/LINUX/CIDRSEQSUITE/pipeline_dependencies/QC_REPORT/EnhancedSequencingQCReport.jar
		# md5 f979bb4dc8d97113735ef17acd3a766e  EnhancedSequencingQCReport.jar
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

##################
# PIPELINE FILES #
##################

	CODING_BED="/mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/UCSC_hg19_CodingOnly_083013_MERGED_noContigs_plus_rCRS_MT.bed"
		# MT was added from ucsc table browser for grch38, GENCODE v29
		# md5 386340ecb59652ad2d182a89dce0c4df
	GENE_LIST="/mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/RefSeqGene.GRCh37.rCRS.MT.bed"
		# md5 dec069c279625cfb110c2e4c5480e036
	CYTOBAND_BED="/mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/GRCh37.Cytobands.bed"
	VERIFY_VCF="/mnt/research/tools/PIPELINE_FILES/GRCh37_aux_files/Omni25_genotypes_1525_samples_v2.b37.PASS.ALL.sites.vcf"
	DBSNP_129="/mnt/research/tools/PIPELINE_FILES/GATK_resource_bundle/2.8/b37/dbsnp_138.b37.excluding_sites_after_129.vcf"
	VERACODE_CSV="/mnt/research/tools/LINUX/CIDRSEQSUITE/resources/Veracode_hg18_hg19.csv"
	MERGED_MENDEL_BED_FILE="/mnt/research/active/M_Valle_MD_SeqWholeExome_120417_1/BED_Files/BAITS_Merged_S03723314_S06588914_TwistCUEXmito.bed"
		# FOR REANALYSIS OF CUTTING'S PHASE AND PHASE 2 PROJECTS.
		# md5: 5d99c5df1d8f970a8219ef0ab455d756
	MERGED_CUTTING_BED_FILE="/mnt/research/active/H_Cutting_CFTR_WGHum-SeqCustom_1_Reanalysis/BED_Files/H_Cutting_phase_1plus2_super_file.bed"

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
				| awk 'BEGIN {FS=","} \
					$1=="'${PROJECT_NAME}'" \
					{print $1}' \
				| sort \
				| uniq`)

			# 1: Project=the Seq Proj folder name

				SEQ_PROJECT=${PROJECT_ARRAY[0]}
		}

##################################
# project directory tree creator #
##################################

	MAKE_PROJ_DIR_TREE ()
	{
		mkdir -p \
		${CORE_PATH}/${SEQ_PROJECT}/{COMMAND_LINES,CRAM,FASTQ,GVCF,HC_CRAM,LOGS} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/{ALIGNMENT_SUMMARY,ANEUPLOIDY_CHECK,ANNOVAR,COUNT_COVARIATES,ERROR_SUMMARY,LAB_PREP_REPORTS,PICARD_DUPLICATES,QC_REPORTS,QC_REPORT_PREP,QUALITY_YIELD,RG_HEADER,VERIFYBAMID,VERIFYBAMID_CHR} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/BAIT_BIAS/{METRICS,SUMMARY} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/BASE_DISTRIBUTION_BY_CYCLE/{METRICS,PDF} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/BASECALL_Q_SCORE_DISTRIBUTION/{METRICS,PDF} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/{CONCORDANCE,CONCORDANCE_MS} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/COUNT_COVARIATES \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/DEPTH_OF_COVERAGE/{TARGET,UCSC,BED_SUPERSET} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/GC_BIAS/{METRICS,PDF,SUMMARY} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/HYB_SELECTION/PER_TARGET_COVERAGE \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/INSERT_SIZE/{METRICS,PDF} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/MEAN_QUALITY_BY_CYCLE/{METRICS,PDF} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/PRE_ADAPTER/{METRICS,SUMMARY} \
		${CORE_PATH}/${SEQ_PROJECT}/REPORTS/VCF_METRICS/SINGLE_SAMPLE/{BAIT,TARGET,TITV} \
		${CORE_PATH}/${SEQ_PROJECT}/TEMP/${SAMPLE_SHEET_NAME} \
		${CORE_PATH}/${SEQ_PROJECT}/VCF/SINGLE_SAMPLE
	}

############################################################################################################
# run ben's enhanced sequencing lab prep metrics report generator which queries phoenix among other things #
############################################################################################################

	RUN_LAB_PREP_METRICS ()
	{
		echo \
		qsub \
			${QSUB_ARGS} \
		-N A00-LAB_PREP_METRICS_${PROJECT_NAME} \
			-o ${CORE_PATH}/${PROJECT_NAME}/LOGS/${PROJECT_NAME}-LAB_PREP_METRICS.log \
		${COMMON_SCRIPT_DIR}/A00-LAB_PREP_METRICS.sh \
			${JAVA_1_8} \
			${LAB_QC_DIR} \
			${CORE_PATH} \
			${PROJECT_NAME} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

################################################################
# combine steps into on function which is probably superfluous #
################################################################

	SETUP_PROJECT ()
	{
		CREATE_PROJECT_ARRAY
		MAKE_PROJ_DIR_TREE
		RUN_LAB_PREP_METRICS
		echo Project started at `date` >> ${CORE_PATH}/${SEQ_PROJECT}/REPORTS/PROJECT_START_END_TIMESTAMP.txt
	}

################################################################
# CREATE_SAMPLE_ARRAY to populate aggregated sample variables. #
################################################################

	CREATE_SAMPLE_ARRAY ()
	{
		SAMPLE_ARRAY=(`awk 1 ${SAMPLE_SHEET} \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
			| awk 'BEGIN {FS=","} $8=="'${SM_TAG}'" {split($19,INDEL,";"); print $1,$5,$6,$7,$8,$9,$10,$12,$15,$16,$17,$18,INDEL[1],INDEL[2]}' \
			| sort \
			| uniq`)

		# 1: Project=the Seq Proj folder name

			PROJECT=${SAMPLE_ARRAY[0]}

			###########################################################################
			# 2: SKIP: FCID=flowcell that sample read group was performed on ##########
			###########################################################################
			# 3: SKIP: Lane=lane of flowcell that sample read group was performed on] #
			###########################################################################
			# 4: SKIP: Index=sample barcode ###########################################
			###########################################################################

		# 5: Platform=type of sequencing chemistry matching SAM specification

			PLATFORM=${SAMPLE_ARRAY[1]}

		# 6: Library_Name=library group of the sample read group
		# Used during Marking Duplicates to determine if molecules are to be considered as part of the same library or not

			LIBRARY=${SAMPLE_ARRAY[2]}

		# 7: Date=should be the run set up date to match the seq run folder name
		# but it has been arbitrarily populated

			RUN_DATE=${SAMPLE_ARRAY[3]}

		# 8: SM_Tag=sample ID

			SM_TAG=${SAMPLE_ARRAY[4]}

				# If there is an @ in the qsub or holdId name it breaks

					SGE_SM_TAG=$(echo ${SM_TAG} | sed 's/@/_/g')

		# 9: Center=the center/funding mechanism

			CENTER=${SAMPLE_ARRAY[5]}

		# 10: Description=Generally we use to denote the sequencer setting (e.g. rapid run)
		# “HiSeq-X”, “HiSeq-4000”, “HiSeq-2500”, “HiSeq-2000”, “NextSeq-500”, or “MiSeq”.

			SEQUENCER_MODEL=${SAMPLE_ARRAY[6]}

			########################
			# 11: SKIP: Seq_Exp_ID #
			########################

		# 12: Genome_Ref=the reference genome used in the analysis pipeline

			REF_GENOME=${SAMPLE_ARRAY[7]}

				# REFERENCE DICTIONARY IS A SUMMARY OF EACH CONTIG. PAIRED WITH REF GENOME

					REF_DICT=$(echo ${REF_GENOME} | sed 's/fasta$/dict/g; s/fa$/dict/g')

			#####################################
			# 13: SKIP: Operator ################
			#####################################
			# 14: SKIP: Extra_VCF_Filter_Params #
			#####################################

		# 15: TS_TV_BED_File=where ucsc coding exons overlap with bait and target bed files

			TITV_BED=${SAMPLE_ARRAY[8]}

		# 16: Baits_BED_File=a super bed file incorporating bait, target, padding and overlap with ucsc coding exons.
		# Used for limited where to run base quality score recalibration on where to create gvcf files.

			BAIT_BED=${SAMPLE_ARRAY[9]}

			# since the mendel changes capture products need a way to define a 4th bed file which is the union of the different captures used.
			# Also have a section for garry cutting's 2 captures

				if [[ ${PROJECT} = "M_Valle"* ]];
					then
						HC_BAIT_BED=${MERGED_MENDEL_BED_FILE}
				elif [[ ${PROJECT} = "H_Cutting"* ]];
					then
						HC_BAIT_BED=${MERGED_CUTTING_BED_FILE}
				else
					HC_BAIT_BED=${BAIT_BED}
				fi

		# 17: Targets_BED_File=bed file acquired from manufacturer of their targets.

			TARGET_BED=${SAMPLE_ARRAY[10]}

		# 18: KNOWN_SITES_VCF=used to annotate ID field in VCF file.
		# masking in base call quality score recalibration.

			DBSNP=${SAMPLE_ARRAY[11]}

		# 19: KNOWN_INDEL_FILES=used for BQSR masking

			KNOWN_INDEL_1=${SAMPLE_ARRAY[12]}
			KNOWN_INDEL_2=${SAMPLE_ARRAY[13]}
	}

######################################################
# CREATE SAMPLE FOLDERS IN TEMP AND LOGS DIRECTORIES #
######################################################

	MAKE_SAMPLE_DIRECTORIES ()
	{
		mkdir -p \
		${CORE_PATH}/${PROJECT}/TEMP/${SAMPLE_SHEET_NAME}/${SM_TAG} \
		${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}
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
			${QSUB_ARGS} \
		-N A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-FIX_BED_FILES.log \
		${GRCH37_SCRIPT_DIR}/A01-FIX_BED_FILES.sh \
			${CORE_PATH} \
			${PROJECT} \
			${SM_TAG} \
			${BAIT_BED} \
			${TARGET_BED} \
			${TITV_BED} \
			${REF_DICT} \
			${SAMPLE_SHEET}
	}

	##############################################################################
	# CREATE VCF FOR VERIFYBAMID METRICS #########################################
	# USE THE TARGET BED FILE ####################################################
	# NOTE THIS SCRIPT IS THE SAME B/W HG19 AND GRCH38 BUT DIFFERENT THAN GRCH37 #
	##############################################################################

		SELECT_VERIFYBAMID_VCF ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N A01-A01-SELECT_VERIFYBAMID_VCF_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-SELECT_VERIFYBAMID_VCF.log \
			-hold_jid A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT} \
			${GRCH37_SCRIPT_DIR}/A01-A01-SELECT_VERIFYBAMID_VCF.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${VERIFY_VCF} \
				${TARGET_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

#############################################################################
# RUN STEPS TO DO PROJECT SET UP, FIX BED FILES, MAKE VERIFYBAMID VCF FILES #
#############################################################################

	for PROJECT_NAME in $(awk 1 ${SAMPLE_SHEET} \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
			| awk 'BEGIN {FS=","} \
				NR>1 \
				{print $1}' \
			| sort \
			| uniq);
	do
		SETUP_PROJECT
	done

	for SM_TAG in $(awk 1 ${SAMPLE_SHEET} \
		| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
		| awk 'BEGIN {FS=","} \
			NR>1 \
			{print $8}' \
		| sort \
		| uniq);
	do
		CREATE_SAMPLE_ARRAY
		MAKE_SAMPLE_DIRECTORIES
		FIX_BED_FILES
		echo sleep 0.1s
		SELECT_VERIFYBAMID_VCF
		echo sleep 0.1s
	done

#######################################################################################
##### BAM FILE GENERATION AND RUN VERIFYBAMID ########################################
#######################################################################################
# NOTE: THE CRAM FILE IS THE END PRODUCT BUT THE BAM FILE IS USED FOR OTHER PROCESSES #
# SOME PROGRAMS CAN'T TAKE IN CRAM AS AN INPUT ########################################
# THE OUTPUT FROM VERIFYBAMID IS USED FOR HAPLOTYPE CALLER ############################
#######################################################################################

#############################################################################
# CREATE_PLATFORM_UNIT_ARRAY so that bwa mem can add metadata to the header #
#############################################################################

	CREATE_PLATFORM_UNIT_ARRAY ()
	{
		PLATFORM_UNIT_ARRAY=(`awk 1 ${SAMPLE_SHEET} \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
			| awk 'BEGIN {FS=","} \
				$8$2$3$4=="'${PLATFORM_UNIT}'" \
				{split($19,INDEL,";"); \
				print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$12,$15,$16,$17,$18,INDEL[1],INDEL[2]}' \
			| sort \
			| uniq`)

		# 1: Project=the Seq Proj folder name

			PROJECT=${PLATFORM_UNIT_ARRAY[0]}

		# 2: FCID=flowcell that sample read group was performed on

			FCID=${PLATFORM_UNIT_ARRAY[1]}

		# 3: Lane=lane of flowcell that sample read group was performed on]

			LANE=${PLATFORM_UNIT_ARRAY[2]}

		# 4: Index=sample barcode

			INDEX=${PLATFORM_UNIT_ARRAY[3]}

		# 5: Platform=type of sequencing chemistry matching SAM specification

			PLATFORM=${PLATFORM_UNIT_ARRAY[4]}

		# 6: Library_Name=library group of the sample read group
		# Used during Marking Duplicates to determine if molecules are to be considered as part of the same library or not

			LIBRARY=${PLATFORM_UNIT_ARRAY[5]}

		# 7: Date=should be the run set up date to match the seq run folder name
		# but it has been arbitrarily populated

			RUN_DATE=${PLATFORM_UNIT_ARRAY[6]}

		# 8: SM_Tag=sample ID

			SM_TAG=${PLATFORM_UNIT_ARRAY[7]}

				# If there is an @ in the qsub or holdId name it breaks

					SGE_SM_TAG=$(echo ${SM_TAG} | sed 's/@/_/g')

		# 9: Center=the center/funding mechanism

			CENTER=${PLATFORM_UNIT_ARRAY[8]}

		# 10: Description=Generally we use to denote the sequencer setting (e.g. rapid run)
		# “HiSeq-X”, “HiSeq-4000”, “HiSeq-2500”, “HiSeq-2000”, “NextSeq-500”, or “MiSeq”.

			SEQUENCER_MODEL=${PLATFORM_UNIT_ARRAY[9]}

				#########################
				# 11: SKIP:  Seq_Exp_ID #
				#########################

		# 12: Genome_Ref=the reference genome used in the analysis pipeline

			REF_GENOME=${PLATFORM_UNIT_ARRAY[10]}

			#####################################
			# 13: SKIP:  Operator ###############
			#####################################
			# 14: SKIP: Extra_VCF_Filter_Params #
			#####################################

		# 15: TS_TV_BED_File=where ucsc coding exons overlap with bait and target bed files

			TITV_BED=${PLATFORM_UNIT_ARRAY[11]}

		# 16: Baits_BED_File=a super bed file incorporating bait, target, padding and overlap with ucsc coding exons.
		# Used for limited where to run base quality score recalibration on where to create gvcf files.

			BAIT_BED=${PLATFORM_UNIT_ARRAY[12]}

		# 17: Targets_BED_File=bed file acquired from manufacturer of their targets.

			TARGET_BED=${PLATFORM_UNIT_ARRAY[13]}

		# 18: KNOWN_SITES_VCF=used to annotate ID field in VCF file
		# masking in base call quality score recalibration.

			DBSNP=${PLATFORM_UNIT_ARRAY[14]}

		# 19: KNOWN_INDEL_FILES=used for BQSR masking

			KNOWN_INDEL_1=${PLATFORM_UNIT_ARRAY[15]}
			KNOWN_INDEL_2=${PLATFORM_UNIT_ARRAY[16]}
	}

####################################################################
# Use bwa mem to do the alignments #################################
# pipe to samblaster to add mate tags ##############################
# pipe to picard's AddOrReplaceReadGroups to handle the bam header #
####################################################################

	RUN_BWA ()
	{
		echo \
		qsub \
			${QSUB_ARGS} \
		-N A02-BWA_${SGE_SM_TAG}_${FCID}_${LANE}_${INDEX} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}_${FCID}_${LANE}_${INDEX}-BWA.log \
		${COMMON_SCRIPT_DIR}/A02-BWA.sh \
			${ALIGNMENT_CONTAINER} \
			${CORE_PATH} \
			${PROJECT} \
			${FCID} \
			${LANE} \
			${INDEX} \
			${PLATFORM} \
			${LIBRARY} \
			${RUN_DATE} \
			${SM_TAG} \
			${CENTER} \
			${SEQUENCER_MODEL} \
			${REF_GENOME} \
			${PIPELINE_VERSION} \
			${BAIT_BED} \
			${TARGET_BED} \
			${TITV_BED} \
			${NOVASEQ_REPO} \
			${SAMPLE_SHEET} \
			${SUBMIT_STAMP}
	}

#############################
# RUN STEPS TO RUN BWA, ETC #
#############################

	for PLATFORM_UNIT in $(awk 1 ${SAMPLE_SHEET} \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
			| awk 'BEGIN {FS=","} \
				NR>1 \
				{print $8$2$3$4}' \
			| sort \
			| uniq );
	do
		CREATE_PLATFORM_UNIT_ARRAY
		RUN_BWA
		echo sleep 0.1s
	done

#########################################################################################
### MARK_DUPLICATES #####################################################################
# Merge files and mark duplicates using picard duplictes with queryname sorting #########
# do coordinate sorting with sambamba ###################################################
#########################################################################################
#########################################################################################
# I am setting the heap space and garbage collector threads now #########################
# doing this does drastically decrease the load average ( the gc thread specification ) #
#########################################################################################
#########################################################################################
# create a hold job id qsub command line based on the number of #########################
# submit merging the bam files created by bwa mem above #################################
# only launch when every lane for a sample is done being processed by bwa mem ###########
# I want to clean this up eventually, but not in the mood for it right now. #############
#########################################################################################

	# What is being pulled out of the merged sample sheet
		# 1. PROJECT
		# 2. SM_TAG
		# 3. FCID_LANE_INDEX
		# 4. FCID_LANE_INDEX.bam
		# 5. SM_TAG
		# 6. DESCRIPTION (INSTRUMENT MODEL)

		awk 1 ${SAMPLE_SHEET} \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
			| awk 'BEGIN {FS=","; OFS="\t"} \
				NR>1 \
				{print $1,$8,$2"_"$3"_"$4,$2"_"$3"_"$4".bam",$8,$10}' \
			| awk 'BEGIN {OFS="\t"} \
				{sub(/@/,"_",$5)} \
				{print $1,$2,$3,$4,$5,$6}' \
			| sort \
				-k 1,1 \
				-k 2,2 \
				-k 3,3 \
				-k 6,6 \
			| uniq \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				-s \
				-g 1,2 \
				collapse 3 \
				collapse 4 \
				unique 5 \
				unique 6 \
		| awk 'BEGIN {FS="\t"} \
			gsub(/,/,",A02-BWA_"$5"_",$3) \
			gsub(/,/,",INPUT=" "'${CORE_PATH}'" "/" $1 "/TEMP/" "'${SAMPLE_SHEET_NAME}'" "/" $2 "/",$4) \
			{print "qsub",\
			"-S /bin/bash",\
			"-cwd",\
			"-V",\
			"-v SINGULARITY_BINDPATH=/mnt:/mnt",\
			"-q","'${QUEUE_LIST}'",\
			"-p","'${PRIORITY}'",\
			"-N","B01-MARK_DUPLICATES_"$5"_"$1,\
			"-o","'${CORE_PATH}'/"$1"/LOGS/"$2"/"$2"-MARK_DUPLICATES.log",\
			"-j y",\
			"-hold_jid","A02-BWA_"$5"_"$3, \
			"'${COMMON_SCRIPT_DIR}'""/B01-MARK_DUPLICATES.sh",\
			"'${ALIGNMENT_CONTAINER}'",\
			"'${CORE_PATH}'",\
			$1,\
			$2,\
			$6,\
			"'${SAMPLE_SHEET}'",\
			"'${SUBMIT_STAMP}'",\
			"INPUT=" "'${CORE_PATH}'" "/" $1 "/TEMP/" "'${SAMPLE_SHEET_NAME}'" "/" $2 "/"$4,\
			"\n" \
			"sleep 0.1s"}'

###################################################
### PROCEEDING WITH AGGREGATED SAMPLE FILES NOW ###
###################################################

	################################
	# run bqsr using bait bed file #
	################################

		RUN_BQSR ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N C01-PERFORM_BQSR_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-PERFORM_BQSR.log \
			-hold_jid A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT},B01-MARK_DUPLICATES_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/C01-PERFORM_BQSR.sh \
				${BQSR_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${KNOWN_INDEL_1} \
				${KNOWN_INDEL_2} \
				${DBSNP} \
				${BAIT_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	##############################
	# use a 4 bin q score scheme #
	# remove indel Q scores ######
	# retain original Q score  ###
	##############################

		APPLY_BQSR ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N D01-APPLY_BQSR_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-APPLY_BQSR.log \
			-hold_jid C01-PERFORM_BQSR_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/D01-APPLY_BQSR.sh \
				${BQSR_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	###################
	# RUN VERIFYBAMID #
	###################

		RUN_VERIFYBAMID ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N E01-RUN_VERIFYBAMID_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-VERIFYBAMID.log \
			-hold_jid A01-A01-SELECT_VERIFYBAMID_VCF_${SGE_SM_TAG}_${PROJECT},D01-APPLY_BQSR_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/E01-VERIFYBAMID.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

###############################
# RUN STEPS BQSR, VERIFYBAMID #
###############################

	for SM_TAG in $(awk 1 ${SAMPLE_SHEET} \
		| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
		| awk 'BEGIN {FS=","} \
			NR>1 \
			{print $8}' \
		| sort \
		| uniq);
	do
		CREATE_SAMPLE_ARRAY
		RUN_BQSR
		echo sleep 0.1s
		APPLY_BQSR
		echo sleep 0.1s
		RUN_VERIFYBAMID
		echo sleep 0.1s
	done

################################################################################################
##### HAPLOTYPE CALLER AND GENOTYPE GVCF SCATTER/GATHER SECTION ################################
# RUN HAPLOTYPE CALLER AND THEN GENOTYPE GVCFS PER CHROMOSOME FOUND IN SAMPLE HC BAIT BED FILE #
# NOTE: HC BAIT BED FILE IS THE BAIT BED FILE IN SAMPLE SHEET UNLESS IT IS A SPECIAL PROJECT ###
# NOTE CONT'D: LIKE MENDEL OR GARRY CUTTTING ###################################################
# GATHER GVCFS, BAM (FROM HAPLOTYPE CALLER), AND VCF FILES INTO ONE FILE PER SAMPLE ############
# CONVERT HAPLOTYPE CALLER BAM FILE INTO CRAM ##################################################
################################################################################################

#######################################################################################################
### HAPLOTYPE CALLER AND GENOTYPE GVCF SCATTER FUNCTIONS ##############################################
# INPUT IS THE BAM FILE ###############################################################################
# the freemix value from verifybamID output is pulled as a variable to the haplotype caller script ####
#######################################################################################################

	###############################################################################################
	# run haplotype caller to create a gvcf for all intervals per chromosome in the bait bed file #
	###############################################################################################

		CALL_HAPLOTYPE_CALLER ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N F01-HAPLOTYPE_CALLER_${SGE_SM_TAG}_${PROJECT}_chr${CHROMOSOME} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-HAPLOTYPE_CALLER_chr${CHROMOSOME}.log \
			-hold_jid A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT},D01-APPLY_BQSR_${SGE_SM_TAG}_${PROJECT},E01-RUN_VERIFYBAMID_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/F01-HAPLOTYPE_CALLER_SCATTER.sh \
				${GATK_3_7_0_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${HC_BAIT_BED} \
				${CHROMOSOME} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

		CALL_HAPLOTYPE_CALLER ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N F01-HAPLOTYPE_CALLER_${SGE_SM_TAG}_${PROJECT}_chr${CHROMOSOME} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-HAPLOTYPE_CALLER_chr${CHROMOSOME}.log \
			-hold_jid A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT},D01-APPLY_BQSR_${SGE_SM_TAG}_${PROJECT},E01-RUN_VERIFYBAMID_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/F01-HAPLOTYPE_CALLER_SCATTER.sh \
				${GATK_3_7_0_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${HC_BAIT_BED} \
				${CHROMOSOME} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}


	################################################################################################
	# run genotype gvcfs for each per chromosome gvcf to ###########################################
	# but only make calls on the capture bait bed file and not the merged bed file if there is one #
	################################################################################################

		CALL_GENOTYPE_GVCF ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N G01-GENOTYPE_GVCF_${SGE_SM_TAG}_${PROJECT}_chr${CHROMOSOME} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-GENOTYPE_GVCF_chr${CHROMOSOME}.log \
			-hold_jid A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT},F01-HAPLOTYPE_CALLER_${SGE_SM_TAG}_${PROJECT}_chr${CHROMOSOME} \
			${COMMON_SCRIPT_DIR}/G01-GENOTYPE_GVCF_SCATTER.sh \
				${GATK_3_7_0_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${DBSNP} \
				${CHROMOSOME} \
				${BAIT_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

################################################################################
### HAPLOTYPE CALLER AND GENTOYPE GVCFS GATHER FUNCTIONS #######################
# GATHER UP THE PER SAMPLE PER CHROMOSOME GVCF FILES INTO A SINGLE SAMPLE GVCF #
# SAME FOR HC BAM AND INITIAL RAW VCF OUTPUTS ##################################
################################################################################

	#############################################################################################
	# create variables to create the hold id for gathering the chromosome level gvcfs/bams/vcfs #
	#############################################################################################

		BUILD_HOLD_ID_PATH_GVCF_AND_HC_BAM_AND_VCF_GATHER ()
		{
			HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER="-hold_jid "

			HOLD_ID_PATH_GENOTYPE_GVCF_GATHER="-hold_jid "

			for CHROMOSOME in $(sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' ${HC_BAIT_BED} \
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
				HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER="${HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER}F01-HAPLOTYPE_CALLER_${SM_TAG}_${PROJECT}_chr${CHROMOSOME},"

				HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER=`echo ${HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER} | sed 's/@/_/g'`

				HOLD_ID_PATH_GENOTYPE_GVCF_GATHER="${HOLD_ID_PATH_GENOTYPE_GVCF_GATHER}G01-GENOTYPE_GVCF_${SM_TAG}_${PROJECT}_chr${CHROMOSOME},"

				HOLD_ID_PATH_GENOTYPE_GVCF_GATHER=`echo ${HOLD_ID_PATH_GENOTYPE_GVCF_GATHER} | sed 's/@/_/g'`
			done
		}

	################################################################################################
	# gather the per chromosome gvcfs ##############################################################
	# NOTE THAT THE DIFF B/W PIPELINES HERE IS HOW HC_BAIT_BED file is defined b/w builds (cont'd) #
	# for special projects (e.g. mendel, cutting) ##################################################
	################################################################################################

		CALL_HAPLOTYPE_CALLER_GVCF_GATHER ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N G02-HAPLOTYPE_CALLER_GVCF_GATHER_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-HAPLOTYPE_CALLER_GVCF_GATHER.log \
			${HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER} \
			${GRCH37_SCRIPT_DIR}/G02-HAPLOTYPE_CALLER_GVCF_GATHER.sh \
				${GATK_3_7_0_CONTAINER} \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${HC_BAIT_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	################################################################################################
	# gather the per chromosome haplotype caller bam files #########################################
	# NOTE THAT THE DIFF B/W PIPELINES HERE IS HOW HC_BAIT_BED file is defined b/w builds (cont'd) #
	# for special projects (e.g. mendel, cutting) ##################################################
	################################################################################################

		CALL_HAPLOTYPE_CALLER_BAM_GATHER ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N G03-HAPLOTYPE_CALLER_BAM_GATHER_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-HAPLOTYPE_CALLER_BAM_GATHER.log \
			${HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER} \
			${GRCH37_SCRIPT_DIR}/G03-HAPLOTYPE_CALLER_BAM_GATHER.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${HC_BAIT_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

		########################################################
		# create a lossless HC cram, although the bam is lossy #
		########################################################

			HC_BAM_TO_CRAM ()
			{
				echo \
				qsub \
					${QSUB_ARGS} \
				-N G03-A01-HAPLOTYPE_CALLER_CRAM_${SGE_SM_TAG}_${PROJECT} \
					-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-HC_BAM_TO_CRAM.log \
				-hold_jid G03-HAPLOTYPE_CALLER_BAM_GATHER_${SGE_SM_TAG}_${PROJECT} \
				${COMMON_SCRIPT_DIR}/G03-A01-HAPLOTYPE_CALLER_CRAM.sh \
					${ALIGNMENT_CONTAINER} \
					${CORE_PATH} \
					${PROJECT} \
					${SM_TAG} \
					${REF_GENOME} \
					${SAMPLE_SHEET} \
					${SUBMIT_STAMP}
			}

	#########################################################################################
	# gather the per chromosome vcfs ########################################################
	# this step is the same between the hg19 and grch38 pipelines but different than grch37 #
	#########################################################################################

		CALL_GENOTYPE_GVCF_GATHER ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N H01-GENOTYPE_GVCF_GATHER_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-GENOTYPE_GVCF_GATHER.log \
			${HOLD_ID_PATH_GENOTYPE_GVCF_GATHER} \
			${GRCH37_SCRIPT_DIR}/H01-GENOTYPE_GVCF_GATHER.sh \
				${GATK_3_7_0_CONTAINER} \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${BAIT_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

#################################################################################################
# RUN STEPS FOR HAPLOTYPE CALLER GVCF/BAM AND GENOTYPE GVCF SCATTER/GATHER ######################
# Take the samples bait bed file and ############################################################
# create a list of unique chromosome to use as a scatter for haplotype caller and genotype gvcf #
# convert haplotype caller bamout to cram after gathering #######################################
#################################################################################################

	for SM_TAG in $(awk 1 ${SAMPLE_SHEET} \
		| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
		| awk 'BEGIN {FS=","} \
			NR>1 \
			{print $8}' \
		| sort \
		| uniq);
	do
		CREATE_SAMPLE_ARRAY
		# create variables for gathers starting with sge -hold_jid argument

			HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER="-hold_jid "
			HOLD_ID_PATH_GENOTYPE_GVCF_GATHER="-hold_jid "

		# run haplotype caller and genotype scatter in below for loop
		# populate with job names per sample in below for loop

		for CHROMOSOME in $(sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' ${HC_BAIT_BED} \
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
			# do haplotype caller and genotype gvcf scatter
				CALL_HAPLOTYPE_CALLER
				echo sleep 0.1s
				CALL_GENOTYPE_GVCF
				echo sleep 0.1s
			# populate -hold_jid argument with all haplotype caller scatter jobs to gather gvcf and bam per sample. 
				HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER="${HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER}F01-HAPLOTYPE_CALLER_${SM_TAG}_${PROJECT}_chr${CHROMOSOME},"
			# replace @ with _ in job names
				HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER=`echo ${HOLD_ID_PATH_GVCF_AND_HC_BAM_GATHER} | sed 's/@/_/g'`
			# populate -hold_jid argument with all genotype gvcf scatter jobs to gather vcf per sample.
				HOLD_ID_PATH_GENOTYPE_GVCF_GATHER="${HOLD_ID_PATH_GENOTYPE_GVCF_GATHER}G01-GENOTYPE_GVCF_${SM_TAG}_${PROJECT}_chr${CHROMOSOME},"
			# replace @ with _ in job names
				HOLD_ID_PATH_GENOTYPE_GVCF_GATHER=`echo ${HOLD_ID_PATH_GENOTYPE_GVCF_GATHER} | sed 's/@/_/g'`
		done

		# do gvcf/hc bam/and vcf gathers. convert hc bam to cram
			CALL_HAPLOTYPE_CALLER_GVCF_GATHER
			echo sleep 0.1s
			CALL_HAPLOTYPE_CALLER_BAM_GATHER
			echo sleep 0.1s
			HC_BAM_TO_CRAM
			echo sleep 0.1s
			CALL_GENOTYPE_GVCF_GATHER
			echo sleep 0.1s
	done

###########################################
##### BAM TO CRAM AND RELATED METRICS #####
###########################################

	#####################################################
	# create a lossless cram, although the bam is lossy #
	#####################################################

		BAM_TO_CRAM ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N E02-BAM_TO_CRAM_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-BAM_TO_CRAM.log \
			-hold_jid D01-APPLY_BQSR_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/E02-BAM_TO_CRAM.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	###############################################
	# CREATE DEPTH OF COVERAGE FOR ALL UCSC EXONS #
	###############################################

		DOC_CODING ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N E03-DOC_CODING_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-DOC_CODING.log \
			-hold_jid D01-APPLY_BQSR_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/E03-DOC_CODING.sh \
				${GATK_3_7_0_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${GENE_LIST} \
				${CODING_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	#############################################
	# CREATE DEPTH OF COVERAGE FOR BED SUPERSET #
	#############################################

		DOC_BAIT ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N E04-DOC_BAIT_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-DOC_BED_SUPERSET.log \
			-hold_jid D01-APPLY_BQSR_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/E04-DOC_BED_SUPERSET.sh \
				${GATK_3_7_0_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${GENE_LIST} \
				${BAIT_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	############################################
	# CREATE DEPTH OF COVERAGE FOR TARGET BED  #
	############################################

		DOC_TARGET ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N E05-DOC_TARGET_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-DOC_TARGET.log \
			-hold_jid D01-APPLY_BQSR_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/E05-DOC_TARGET.sh \
				${GATK_3_7_0_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${GENE_LIST} \
				${TARGET_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	#########################################################
	# DO AN ANEUPLOIDY CHECK ON TARGET BED FILE DOC OUTPUT  #
	#########################################################

		ANEUPLOIDY_CHECK ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N E05-A01-CHROM_DEPTH_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-ANEUPLOIDY_CHECK.log \
			-hold_jid E05-DOC_TARGET_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/E05-A01-CHROM_DEPTH.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${CYTOBAND_BED} \
				${SAMPLE_SHEET}
		}

	#############################
	# COLLECT MULTIPLE METRICS  #
	#############################

		COLLECT_MULTIPLE_METRICS ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N F02-COLLECT_MULTIPLE_METRICS_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-COLLECT_MULTIPLE_METRICS.log \
			-hold_jid A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT},E02-BAM_TO_CRAM_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/F02-COLLECT_MULTIPLE_METRICS.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${DBSNP} \
				${TARGET_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	#######################
	# COLLECT HS METRICS  #
	#######################

		COLLECT_HS_METRICS ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N F03-COLLECT_HS_METRICS_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-COLLECT_HS_METRICS.log \
			-hold_jid A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT},E02-BAM_TO_CRAM_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/F03-COLLECT_HS_METRICS.sh \
				${GATK_CONTAINER_4_2_2_0} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${BAIT_BED} \
				${TARGET_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	################################################################################
	# PERFORM VERIFYBAM ID PER CHROMOSOME ##########################################
	# DOING BOTH THE SELECT VCF AND VERIFYBAMID RUN WITHIN ONE JOB #################
	# NOTE THAT THE HG19 AND GRCH38 SCRIPTS ARE THE SAME BUT DIFFERENT FROM GRCH37 #
	################################################################################

		CALL_VERIFYBAMID_PER_AUTO ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N E06-VERIFYBAMID_PER_AUTO_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-VERIFYBAMID_PER_CHR.log \
			-hold_jid A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT},D01-APPLY_BQSR_${SGE_SM_TAG}_${PROJECT} \
			${GRCH37_SCRIPT_DIR}/E06-VERIFYBAMID_PER_AUTO.sh \
				${ALIGNMENT_CONTAINER} \
				${GATK_3_7_0_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${VERIFY_VCF} \
				${BAIT_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	######################################
	# GATHER PER CHR VERIFYBAMID REPORTS #
	######################################

		CALL_VERIFYBAMID_AUTO_GATHER ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N E06-A01-CAT_VERIFYBAMID_AUTO_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-CAT_VERIFYBAMID_AUTO.log \
			-hold_jid E06-VERIFYBAMID_PER_AUTO_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/E06-A01-CAT_VERIFYBAMID_AUTO.sh \
				${CORE_PATH} \
				${ALIGNMENT_CONTAINER} \
				${PROJECT} \
				${SM_TAG} \
				${BAIT_BED} \
				${SAMPLE_SHEET}
		}

############################################
# RUN STEPS TO DO BAM/CRAM RELATED METRICS #
############################################

	for SM_TAG in $(awk 1 ${SAMPLE_SHEET} \
		| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
		| awk 'BEGIN {FS=","} \
			NR>1 \
			{print $8}' \
		| sort \
		| uniq);
	do
		CREATE_SAMPLE_ARRAY
		BAM_TO_CRAM
		echo sleep 0.1s
		DOC_CODING
		echo sleep 0.1s
		DOC_BAIT
		echo sleep 0.1s
		DOC_TARGET
		echo sleep 0.1s
		ANEUPLOIDY_CHECK
		echo sleep 0.1s
		COLLECT_MULTIPLE_METRICS
		echo sleep 0.1s
		COLLECT_HS_METRICS
		echo sleep 0.1s
		CALL_VERIFYBAMID_PER_AUTO
		echo sleep 0.1s
		CALL_VERIFYBAMID_AUTO_GATHER
		echo sleep 0.1s
	done

#############################################
##### VCF BREAKOUTS, FILTERING, METRICS #####
#############################################

	################################################
	# EXTRACT SNV VARIANTS TO PERFORM FILTERING ON #
	################################################

		EXTRACT_SNV ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N I01-EXTRACT_SNV_QC_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-SELECT_SNV_QC.log \
			-hold_jid H01-GENOTYPE_GVCF_GATHER_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/I01-EXTRACT_SNV.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	############################################################
	# EXTRACT INDEL AND MIXED VARIANTS TO PERFORM FILTERING ON #
	############################################################

		EXTRACT_INDEL_AND_MIXED ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N I02-EXTRACT_INDEL_AND_MIXED_QC_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-SELECT_INDEL_QC.log \
			-hold_jid H01-GENOTYPE_GVCF_GATHER_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/I02-EXTRACT_INDEL_AND_MIXED.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	###############
	# FILTER SNVS #
	###############

		FILTER_SNV ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N I01-A01-FILTER_SNV_QC_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-FILTER_SNV_QC.log \
			-hold_jid I01-EXTRACT_SNV_QC_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/I01-A01-FILTER_SNV.sh \
				${GATK_3_7_0_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	##########################
	# FILTER INDEL AND MIXED #
	##########################

		FILTER_INDEL_AND_MIXED ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N I02-A01-FILTER_INDEL_AND_MIXED_QC_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-FILTER_INDEL_QC.log \
			-hold_jid I02-EXTRACT_INDEL_AND_MIXED_QC_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/I02-A01-FILTER_INDEL_AND_MIXED.sh \
				${GATK_3_7_0_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	##############################
	# COMBINE FILTERED VCF FILES #
	##############################

		COMBINE_FILTERED_VCF_FILES ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N J01-COMBINE_FILTERED_VCF_FILES_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-FILTER_INDEL_QC.log \
			-hold_jid I01-A01-FILTER_SNV_QC_${SGE_SM_TAG}_${PROJECT},I02-A01-FILTER_INDEL_AND_MIXED_QC_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/J01-COMBINE_FILTERED_VCF_FILES.sh \
				${GATK_3_7_0_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	#######################################################################################
	# EXTRACT OUT PASS ONLY SNVS FROM FINAL VCF ON TARGET BED FILE TO USE FOR CONCORDANCE #
	#######################################################################################

		EXTRACT_ON_TARGET_PASS_SNV ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N J01-A04-EXTRACT_SNV_TARGET_PASS_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-EXTRACT_SNV_TARGET_PASS.log \
			-hold_jid A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT},J01-COMBINE_FILTERED_VCF_FILES_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/J01-A04-EXTRACT_SNV_TARGET_PASS.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_GENOME} \
				${TARGET_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	############################################################################################
	# GENERATE CONCORDANCE USING GT ARRAY FINAL REPORT AS THE TRUTH SET ON THE TARGET BED FILE #
	# NOTE THAT SCRIPT IS THE SAME BETWEEN THE GRCH37 AND HG19 PIPELINES #######################
	# BUT DIFFERENT THAN THE ONE USED FOR THE GRCH38 PIPELINE ##################################
	############################################################################################

		TARGET_PASS_SNV_CONCORDANCE ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N J01-A04-A01-SNV_TARGET_PASS_CONCORDANCE_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-TARGET_PASS_SNV_QC_CONCORDANCE.log \
			-hold_jid J01-A04-EXTRACT_SNV_TARGET_PASS_${SGE_SM_TAG}_${PROJECT} \
			${GRCH37_SCRIPT_DIR}/J01-A04-A01-SNV_TARGET_PASS_CONCORDANCE.sh \
				${JAVA_1_8} \
				${CIDRSEQSUITE_7_5_0_DIR} \
				${VERACODE_CSV} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${TARGET_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	#############################################
	# GENERATE VCF METRICS FOR ON BAIT BED FILE #
	#############################################

		VCF_METRICS_BAIT ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N J01-A01-VCF_METRICS_BAIT_QC_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-VCF_METRICS_BAIT_QC.log \
			-hold_jid A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT},J01-COMBINE_FILTERED_VCF_FILES_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/J01-A01-VCF_METRICS_BAIT.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_DICT} \
				${DBSNP} \
				${BAIT_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	###############################################
	# GENERATE VCF METRICS FOR ON TARGET BED FILE #
	###############################################

		VCF_METRICS_TARGET ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N J01-A02-VCF_METRICS_TARGET_QC_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-VCF_METRICS_TARGET_QC.log \
			-hold_jid A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT},J01-COMBINE_FILTERED_VCF_FILES_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/J01-A02-VCF_METRICS_TARGET.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_DICT} \
				${DBSNP} \
				${TARGET_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

	#############################################
	# GENERATE VCF METRICS FOR ON TITV BED FILE #
	#############################################

		VCF_METRICS_TITV ()
		{
			echo \
			qsub \
				${QSUB_ARGS} \
			-N J01-A03-VCF_METRICS_TITV_QC_${SGE_SM_TAG}_${PROJECT} \
				-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-VCF_METRICS_TITV_QC.log \
			-hold_jid A01-FIX_BED_FILES_${SGE_SM_TAG}_${PROJECT},J01-COMBINE_FILTERED_VCF_FILES_${SGE_SM_TAG}_${PROJECT} \
			${COMMON_SCRIPT_DIR}/J01-A03-VCF_METRICS_TITV.sh \
				${ALIGNMENT_CONTAINER} \
				${CORE_PATH} \
				${PROJECT} \
				${SM_TAG} \
				${REF_DICT} \
				${DBSNP_129} \
				${TITV_BED} \
				${SAMPLE_SHEET} \
				${SUBMIT_STAMP}
		}

######################################
# GENERATE QC REPORT STUB FOR SAMPLE #
######################################

QC_REPORT_PREP ()
{
echo \
qsub \
${QSUB_ARGS} \
-N X1_${SGE_SM_TAG} \
-hold_jid \
E01-RUN_VERIFYBAMID_${SGE_SM_TAG}_${PROJECT},\
E03-DOC_CODING_${SGE_SM_TAG}_${PROJECT},\
E04-DOC_BAIT_${SGE_SM_TAG}_${PROJECT},\
E05-A01-CHROM_DEPTH_${SGE_SM_TAG}_${PROJECT},\
F02-COLLECT_MULTIPLE_METRICS_${SGE_SM_TAG}_${PROJECT},\
F03-COLLECT_HS_METRICS_${SGE_SM_TAG}_${PROJECT},\
E06-A01-CAT_VERIFYBAMID_AUTO_${SGE_SM_TAG}_${PROJECT},\
J01-A04-A01-SNV_TARGET_PASS_CONCORDANCE_${SGE_SM_TAG}_${PROJECT},\
J01-A01-VCF_METRICS_BAIT_QC_${SGE_SM_TAG}_${PROJECT},\
J01-A02-VCF_METRICS_TARGET_QC_${SGE_SM_TAG}_${PROJECT},\
J01-A03-VCF_METRICS_TITV_QC_${SGE_SM_TAG}_${PROJECT} \
-o ${CORE_PATH}/${PROJECT}/LOGS/${SM_TAG}/${SM_TAG}-QC_REPORT_PREP_QC.log \
${COMMON_SCRIPT_DIR}/X01-QC_REPORT_PREP.sh \
${ALIGNMENT_CONTAINER} \
${CORE_PATH} \
${PROJECT} \
${SM_TAG} \
${SAMPLE_SHEET} \
${SUBMIT_STAMP}
}

##########################################################
# RUN STEPS TO DO VCF RELATED METRICS AND QC REPORT PREP #
##########################################################

	for SM_TAG in $(awk 1 ${SAMPLE_SHEET} \
		| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
		| awk 'BEGIN {FS=","} \
			NR>1 \
			{print $8}' \
		| sort \
		| uniq);
	do
		CREATE_SAMPLE_ARRAY
		EXTRACT_SNV
		echo sleep 0.1s
		EXTRACT_INDEL_AND_MIXED
		echo sleep 0.1s
		FILTER_SNV
		echo sleep 0.1s
		FILTER_INDEL_AND_MIXED
		echo sleep 0.1s
		COMBINE_FILTERED_VCF_FILES
		echo sleep 0.1s
		EXTRACT_ON_TARGET_PASS_SNV
		echo sleep 0.1s
		TARGET_PASS_SNV_CONCORDANCE
		echo sleep 0.1s
		VCF_METRICS_BAIT
		echo sleep 0.1s
		VCF_METRICS_TARGET
		echo sleep 0.1s
		VCF_METRICS_TITV
		echo sleep 0.1s
		QC_REPORT_PREP
		echo sleep 0.1
	done

#############################
##### END PROJECT TASKS #####
#############################

# build hold id for qc report prep per sample, per project

	BUILD_HOLD_ID_PATH_PROJECT_WRAP_UP ()
	{
		HOLD_ID_PATH="-hold_jid "

		for SM_TAG in $(awk 1 ${SAMPLE_SHEET} \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
			| awk 'BEGIN {FS=","} \
				$1=="'${PROJECT}'" \
				{print $8}' \
			| sort \
			| uniq);
		do
			CREATE_SAMPLE_ARRAY
			HOLD_ID_PATH="${HOLD_ID_PATH}X1_${SGE_SM_TAG},"
			HOLD_ID_PATH=`echo ${HOLD_ID_PATH} | sed 's/@/_/g'`
		done
	}

# run end project functions (qc report, file clean-up) for each project

	PROJECT_WRAP_UP ()
	{
		echo \
		qsub \
			${QSUB_ARGS} \
			-m e \
			-M khetric1@jhmi.edu \
		-N X01-X01-END_PROJECT_TASKS_${PROJECT} \
			-o ${CORE_PATH}/${PROJECT}/LOGS/${PROJECT}-END_PROJECT_TASKS.log \
		${HOLD_ID_PATH}A00-LAB_PREP_METRICS_${PROJECT} \
		${GRCH37_SCRIPT_DIR}/X01-X01-END_PROJECT_TASKS.sh \
			${CORE_PATH} \
			${ALIGNMENT_CONTAINER} \
			${PROJECT} \
			${SAMPLE_SHEET} \
			${SUBMITTER_SCRIPT_PATH} \
			${SUBMITTER_ID} \
			${SUBMIT_STAMP}
	}

# final loop

	for PROJECT in $(awk 1 ${SAMPLE_SHEET} \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
			| awk 'BEGIN {FS=","} \
				NR>1 \
				{print $1}' \
			| sort \
			| uniq);
	do
		BUILD_HOLD_ID_PATH_PROJECT_WRAP_UP
		PROJECT_WRAP_UP
	done

# EMAIL WHEN DONE SUBMITTING

printf "${SAMPLE_SHEET}\nhas finished submitting at\n`date`\nby `whoami`" \
	| mail -s "${PERSON_NAME} has submitted CIDR.WES.QC.SUBMITTER.sh" \
		${SEND_TO}
