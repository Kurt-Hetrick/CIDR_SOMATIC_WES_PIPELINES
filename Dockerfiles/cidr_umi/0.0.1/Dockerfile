FROM ubuntu:16.04

# newer versions of gatk have picard wrapped in, but I don't want to dig up what version of picard this is using
ENV PICARD_URL https://github.com/broadinstitute/picard/releases/download/2.26.10/picard.jar
# datamash
ENV DATAMASH_URL http://ftp.gnu.org/gnu/datamash/datamash-1.6.tar.gz
ENV DATAMASH_MD5 = "c3c243278a2f35de5ce988c844f8e240"
# fgbio
ENV FGBIO_URL https://github.com/fulcrumgenomics/fgbio/releases/download/2.0.2/fgbio-2.0.2.jar

SHELL ["/bin/bash", "-c"]

RUN mkdir -p /downloads
RUN mkdir -p /picard
RUN mkdir -p /fgbio
WORKDIR /downloads

RUN apt-get update -qq && \
	apt-get install -qq \
	bzip2 \
	tzdata \
	gcc \
	g++ \
	make \
	zlib1g-dev \
	wget \
	perl \
	openjdk-8-jdk

RUN wget -nv $PICARD_URL && \
	mv picard.jar /picard/picard.jar && \
	rm -rf /downloads/picard.jar

RUN wget -nv $DATAMASH_URL && \
	tar -xzf datamash-1.6.tar.gz && \
	cd datamash-1.6 && \
	./configure && \
	make && \
	make check && \
	make install && \
	cd .. && \
	rm -rf datamash-1.6* datamash-1.6.tar.gz

RUN wget -nv $FGBIO_URL && \
	mv fgbio-2.0.2.jar /fgbio/fgbio.jar && \
	rm -rf /downloads/fgbio-2.0.2.jar
