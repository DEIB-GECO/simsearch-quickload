FROM ubuntu:20.04

RUN  apt-get update \
  && apt-get install -y wget

RUN apt-get install -y libpng-dev \
  && apt-get install -y libkrb5-dev

RUN  wget -q -O /usr/local/bin/liftOver  http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/liftOver 
RUN  chmod a+x /usr/local/bin/liftOver

RUN wget -q -O /usr/local/bin/fetchChromSizes http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/fetchChromSizes 
RUN wget -q -O /usr/local/bin/bedToBigBed http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/bedToBigBed

RUN mkdir /usr/local/share/ 
RUN wget -q -O /usr/local/share/hg19ToHg38.over.chain.gz https://hgdownload.cse.ucsc.edu/goldenpath/hg19/liftOver/hg19ToHg38.over.chain.gz 

RUN chmod +x /usr/local/bin/*
RUN fetchChromSizes hg19 > /usr/local/share/hg19.chrom.sizes
RUN fetchChromSizes hg38 > /usr/local/share/hg38.chrom.sizes


