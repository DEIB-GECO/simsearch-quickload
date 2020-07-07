#! /usr/bin/python

# TRY WITH A FIND FROM THE SHELL TO IDENTIFY WHICH FOLDER BELONG TO WHICH SAMPLE
# AND RETRIEVE IN THIS WAY THE FASTQ FOLDER.

# this program will check the entries in the HTS-flow DB, comparing them with
# the LIMS system. If there are differences (e.g. new entries), it will
# generate the SQL file called HTSentriesUpdate.sql. Remember to  run
# mysql to fill the HTS-flow DB with the new ones.

import sys

cosmicSamples = sys.argv[1]
cosmicNC = sys.argv[2]
cosmicNCVcf = sys.argv[3]
diseaseSearch = sys.argv[4]


sampleNames = {}
mutationIds = {}

with open(cosmicSamples) as f:
        content = f.readlines()
        for line in content:
            if diseaseSearch in line:
                sampleName = line.strip().split("\t")[1]   
                sampleNames[sampleName] = True
            
            
with open(cosmicNC) as f:
        content = f.readlines()
        for line in content:   
            sampleName = line.strip().split("\t")[0] 
            if sampleName in sampleNames:
                mutationId = line.strip().split("\t")[2] 
                mutationIds[mutationId] = True


with open(cosmicNCVcf) as f:
        content = f.readlines()
        for line in content:   
            if line.startswith("##"):
                print(line)
            elif line.strip().split("\t")[2] in mutationIds:
                print(line)
            
          

