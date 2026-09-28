FROM rust:trixie

ENV MAFSMITH_URL=https://github.com/nf-osi/mafsmith/archive/refs/tags/v0.1.0.tar.gz
ENV SAMTOOLS_URL=https://github.com/samtools/samtools/releases/download/1.10/samtools-1.10.tar.bz2

RUN apt-get update \
	&& apt-get install -y \
    python3.8

SHELL ["/bin/bash", "-c"]

WORKDIR /data

RUN wget -nv $SAMTOOLS_URL && \
	tar -xvf samtools-1.10.tar.bz2 && \
	cd samtools-1.10 && \
	./configure --prefix=/usr && \
	make all all-htslib && \
	make install install-htslib && \
	cd .. && \
	rm -rf samtools-1.10*

RUN wget -nv $MAFSMITH_URL \
	&& tar -xzvf v0.1.0.tar.gz \
	&& cd mafsmith-0.1.0 \
	&& cargo build --release \
	&& ./target/release/mafsmith fetch \
	&& cp ./target/release/mafsmith /usr/bin \
	&& cp /root/.mafsmith/bin/fastvep /usr/bin \
	&& (zgrep ^# /root/.mafsmith/GRCh38/genes.gff3.gz | zgrep -v ^### ; zgrep -v "^#" /root/.mafsmith/GRCh38/genes.gff3.gz | awk '{print "chr"$0}') > /root/.mafsmith/GRCh38/genes.gff3 \
	&& rm -rvf /root/.mafsmith/GRCh38/genes.gff3.gz \
	&& sed 's/>/>chr/g' /root/.mafsmith/GRCh38/reference.fa > /root/.mafsmith/GRCh38/reference.fixed.fa \
	&& rm -rvf /root/.mafsmith/GRCh38/reference.fa \
	&& mv /root/.mafsmith/GRCh38/reference.fixed.fa /root/.mafsmith/GRCh38/reference.fa \
	&& samtools faidx /root/.mafsmith/GRCh38/reference.fa \
	&& rm -rvf /root/.mafsmith/GRCh38/reference.fa.gz \
	&& mv /root/.mafsmith/GRCh38 /data

ENV MAFSMITH_HOME=/data/mafsmith
ENV HOME=/data

## note: below is an example if you wanted to update to a specific version of ensemble

## ENV ENSEMBL_GFF3=https://ftp.ensembl.org/pub/release-116/gff3/homo_sapiens/Homo_sapiens.GRCh38.116.gff3.gz
## ENV ENSEMBL_FASTA=https://ftp.ensembl.org/pub/release-116/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz

# RUN wget $ENSEMBL_GFF3 \
# 	&& wget $ENSEMBL_FASTA \
# 	&& gunzip /downloads/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz

# RUN wget -nv $MAFSMITH_URL \
# 	&& tar -xzvf v0.1.0.tar.gz \
# 	&& cd mafsmith-0.1.0 \
# 	&& cargo build --release \
# 	&& ./target/release/mafsmith fetch \
# 		--gff3 /downloads/Homo_sapiens.GRCh38.116.gff3.gz \
# 		--ref-fasta /downloads/Homo_sapiens.GRCh38.dna.primary_assembly.fa \
# 	&& cp ./target/release/mafsmith /usr/bin \
# 	&& cp /root/.mafsmith/bin/fastvep /usr/bin \
#	&& (zgrep ^# /root/.mafsmith/GRCh38/genes.gff3.gz | zgrep -v ^### ; zgrep -v "^#" /root/.mafsmith/GRCh38/genes.gff3.gz | awk '{print "chr"$0}') > /root/.mafsmith/GRCh38/genes.gff3 \
#	&& rm -rvf /root/.mafsmith/GRCh38/genes.gff3.gz \
#	&& gzip /root/.mafsmith/GRCh38/genes.gff3 \
#	&& sed 's/>/>chr/g' /root/.mafsmith/GRCh38/reference.fa > /root/.mafsmith/GRCh38/reference.fixed.fa \
#	&& rm -rvf /root/.mafsmith/GRCh38/reference.fa \
#	&& mv /root/.mafsmith/GRCh38/reference.fixed.fa /root/.mafsmith/GRCh38/reference.fa \
#	&& samtools faidx /root/.mafsmith/GRCh38/reference.fa

## download the primary reference file from 
## https://ftp.ensembl.org/pub/release-116/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
#### note that you can replace the release version with whatever version that's current or whatever fits your fancy
## grab the accompanying gff file e.g.
## https://ftp.ensembl.org/pub/release-116/gff3/homo_sapiens/Homo_sapiens.GRCh38.116.gff3.gz
## gunzip the reference and gff3 file and index the reference file with samtools faidx and pass those through to mafsmith
