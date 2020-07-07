#! /usr/bin/python

# In a bed file, some peaks may be out of chromosome. In this case, cut it

import sys

#bedFile = sys.argv[1]
chromosomeSizeFile = sys.argv[1]

chromosomeSize = {}

with open(chromosomeSizeFile) as f:
    content = f.readlines()
    for line in content:
        (chromosome, size) = line.strip().split("\t")   
        chromosomeSize[chromosome] = int(size)


for line in sys.stdin:    
    (chromosome, start, end, name, score, strand) = line.strip().split("\t")   
    if int(end) > chromosomeSize[chromosome] :
        end = chromosomeSize[chromosome]
    print("%s\t%s\t%s\t%s\t%s\t%s" % (chromosome, start, end, name, score, strand))
            
    
