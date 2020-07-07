#! /usr/bin/python

import sys
from twisted.conch.test.test_recvline import end
from __builtin__ import int

segwayBed = sys.argv[1]

excludeTerms = {"Quiescent", "LowConfidence", "RegPermissive"}

sampleNames = {}
mutationIds = {}

with open(segwayBed) as f:
        content = f.readlines()
        
        curChr= ""
        curStart= ""
        curEnd= ""
        curType= ""
        
        for line in content:
            fields = line.strip().split("\t")   
            chr=fields[0]
            start=fields[1]
            end=fields[2]
            segType=fields[3].split("_")[1]
            
            
            if segType == curType and chr == curChr and start == curEnd :
                curEnd=end
            else:
                
                if curType != "":
                    print("%s\t%s\t%s\t%s" % (curChr, curStart, curEnd, curType))
                
                if type in excludeTerms:
                    # continue
                    curType = ""
                    curChr=""
                    curStart=""
                    curEnd = ""
                else :
                    curType=segType
                    curChr=chr
                    curStart=start
                    curEnd = end
            
            
                
            