
mkdir work
cd work 

# make bb
wget --no-verbose http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/fetchChromSizes
wget --no-verbose http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/bedToBigBed

# liftover 
wget --no-verbose https://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/liftOver
wget --no-verbose https://hgdownload.cse.ucsc.edu/goldenpath/hg19/liftOver/hg19ToHg38.over.chain.gz

chmod +x bedToBigBed fetchChromSizes liftOver
sh ./fetchChromSizes hg19 > hg19.chrom.sizes
sh ./fetchChromSizes hg38 > hg38.chrom.sizes



# encode codes
codes="E017 E116 E117 E122 E123 E127"

# create subdir for hg38 and hg19
mkdir H_sapiens_Feb_2009 H_sapiens_Dec_2013
#rm H_sapiens_*/ChmmModels/*

# Datasets: Encode, Roadmap, Segway, chrommhmm, loops

# Chrommhmm Roadmap: hg19
# from http://egg2.wustl.edu/roadmap/data/byFileType/chromhmmSegmentations/ChmmModels/coreMarks/jointModel/final/*.dense.bed.bgz.*

mkdir H_sapiens_Feb_2009/ChmmModels
mkdir H_sapiens_Dec_2013/ChmmModels

for code in $codes; do 
    wget --no-verbose -O - http://egg2.wustl.edu/roadmap/data/byFileType/chromhmmSegmentations/ChmmModels/coreMarks/jointModel/final/`echo $code`_15_coreMarks_dense.bed.gz | zcat | grep -v "track name" | gzip >  H_sapiens_Feb_2009/ChmmModels/`echo $code`_15_coreMarks_dense.bed.gz
    ./liftOver H_sapiens_Feb_2009/ChmmModels/`echo $code`_15_coreMarks_dense.bed.gz hg19ToHg38.over.chain.gz H_sapiens_Dec_2013/ChmmModels/`echo $code`_15_coreMarks_dense.bed unlifted.bed 
    gzip H_sapiens_Dec_2013/ChmmModels/`echo $code`_15_coreMarks_dense.bed
done



# TFs:
# from http://egg2.wustl.edu/roadmap/src/chromHMM/bin/COORDS/hg19/TFBS/
mkdir TFBS
wget --no-verbose -r --no-host-directories --cut-dirs=7 -A '*.bed.gz' http://egg2.wustl.edu/roadmap/src/chromHMM/bin/COORDS/hg19/TFBS/ -P TFBS

mkdir H_sapiens_Feb_2009/TFBS
mkdir H_sapiens_Dec_2013/TFBS


for celltype in `ls -d TFBS/*/|cut -d '/' -f 2`; do 
    # celltype=${dir%%/}
    for bedfile in `ls TFBS/$celltype/ | grep 'bed.gz'`; do
        name=${bedfile%.gz}
        echo $name
        echo $bedfile
        # hg19
        zcat TFBS/$celltype/$bedfile | sort -k1,1 -k2,2n | perl -p -e 's/^([0-9XYN]+[\t\ ])/chr$1/g' |cut -f 1,2,3,4,5,6  > sorted.bed
        outname=`echo $celltype`_`echo $name |perl -p -e 's/(TF\_)?([^\.]+)\..*$/$2/g'`.bb   
        ./bedToBigBed sorted.bed hg19.chrom.sizes H_sapiens_Feb_2009/TFBS/$outname

        # hg38 
        ./liftOver TFBS/$celltype/$bedfile hg19ToHg38.over.chain.gz  hg38.$bedfile unlifted.bed 
        cat hg38.$bedfile | sort -k1,1 -k2,2n | perl -p -e 's/^([0-9XYN]+[\t\ ])/chr$1/g' |cut -f 1,2,3,4,5,6  > sorted.bed
        outname=`echo $celltype`_`echo $name |perl -p -e 's/(TF\_)?([^\.]+)\..*$/$2/g'`.bb   
        ./bedToBigBed sorted.bed hg38.chrom.sizes H_sapiens_Dec_2013/TFBS/$outname
    done
done


# RoadMap, histone marks: 
# http://egg2.wustl.edu/roadmap/data/byFileType/peaks/consolidated/narrowPeak/
# http://egg2.wustl.edu/roadmap/data/byFileType/peaks/consolidated/gappedPeak/
# http://egg2.wustl.edu/roadmap/data/byFileType/peaks/consolidated/narrowPeak/
mkdir H_sapiens_Feb_2009/peaks
mkdir H_sapiens_Dec_2013/peaks

for code in $codes; do 
 echo "wget --no-verbose -r --no-host-directories --cut-dirs=7 -A '`echo $code`*.broadPeak.gz' http://egg2.wustl.edu/roadmap/data/byFileType/peaks/consolidated/broadPeak/"
 wget --no-verbose -qO - http://egg2.wustl.edu/roadmap/data/byFileType/peaks/consolidated/broadPeak/ | sed -n 's#^.*href="\([^"]\{1,\}\)".*$#\1#p'  | cut -d\# -f2 | grep $code |\
  while read url; do wget --no-verbose http://egg2.wustl.edu/roadmap/data/byFileType/peaks/consolidated/broadPeak/$url; done
done

for code in $codes; do 
 echo "wget --no-verbose -r --no-host-directories --cut-dirs=7 -A '`echo $code`*.narrowPeak.gz' http://egg2.wustl.edu/roadmap/data/byFileType/peaks/consolidated/narrowPeak/"
 wget --no-verbose -qO - http://egg2.wustl.edu/roadmap/data/byFileType/peaks/consolidated/narrowPeak/ | sed -n 's#^.*href="\([^"]\{1,\}\)".*$#\1#p'  | cut -d\# -f2 | grep $code |\
  while read url; do wget --no-verbose http://egg2.wustl.edu/roadmap/data/byFileType/peaks/consolidated/narrowPeak/$url; done
done


# transform broadpeak/narrowPeak to bigbed

for code in $codes; do 
    for bedfile in $code*Peak.gz; do
        name=${bedfile%.gz}
        echo $name
        # hg19
        zcat $bedfile | sort -k1,1 -k2,2n | perl -p -e 's/^([0-9XYN]+[\t\ ])/chr$1/g' |cut -f 1,2,3,4,5,6  | perl -p -e 's/(\t[0-9]{4}\t\.)$/\t1000\t\./g' | python ../scripts/cutPeaksOutOfChromosome.py hg19.chrom.sizes> sorted.bed
        ./bedToBigBed sorted.bed hg19.chrom.sizes H_sapiens_Feb_2009/peaks/$name.bb
       
        # hg38 
        ./liftOver sorted.bed hg19ToHg38.over.chain.gz hg38.$bedfile unlifted.bed 
        cat hg38.$bedfile | sort -k1,1 -k2,2n | perl -p -e 's/^([0-9XYN]+[\t\ ])/chr$1/g' |cut -f 1,2,3,4,5,6  > sorted.bed
        ./bedToBigBed sorted.bed hg38.chrom.sizes H_sapiens_Dec_2013/peaks/$name.bb
    done
done 


# Groups to cell type: https://docs.google.com/spreadsheets/d/1yikGx4MsO9Ei36b64yOy9Vb6oPC5IBGlFbYEt-N6gOM/edit#gid=15
# tsv: https://docs.google.com/spreadsheets/d/1yikGx4MsO9Ei36b64yOy9Vb6oPC5IBGlFbYEt-N6gOM/export?format=tsv&id=1yikGx4MsO9Ei36b64yOy9Vb6oPC5IBGlFbYEt-N6gOM&gid=15
wget --no-verbose -O metadata.txt "https://docs.google.com/spreadsheets/d/1yikGx4MsO9Ei36b64yOy9Vb6oPC5IBGlFbYEt-N6gOM/export?format=tsv&id=1yikGx4MsO9Ei36b64yOy9Vb6oPC5IBGlFbYEt-N6gOM&gid=15"



# Segway encyclopedia
# http://noble.gs.washington.edu/proj/encyclopedia/
# encyclopedia:

mkdir H_sapiens_Feb_2009/segway
mkdir H_sapiens_Dec_2013/segway

mkdir segway

wget --no-verbose http://noble.gs.washington.edu/proj/encyclopedia/interpreted/H1-HESC.bed.gz -P segway
wget --no-verbose http://noble.gs.washington.edu/proj/encyclopedia/interpreted/HEPG2.bed.gz -P segway
wget --no-verbose http://noble.gs.washington.edu/proj/encyclopedia/interpreted/HUVEC.bed.gz -P segway
wget --no-verbose http://noble.gs.washington.edu/proj/encyclopedia/interpreted/K562.bed.gz -P segway

for bedfile in `ls segway/`; do
    name=${bedfile%.gz}
    echo $name
    # hg19
    zcat segway/$bedfile | sort -k1,1 -k2,2n | perl -p -e 's/^([0-9XYN]+[\t\ ])/chr$1/g' |cut -f 1,2,3,4,5,6  | perl -p -e 's/(\t[0-9]{4}\t\.)$/\t1000\t\./g' | python ../scripts/cutPeaksOutOfChromosome.py hg19.chrom.sizes> sorted.bed
    ./bedToBigBed sorted.bed hg19.chrom.sizes H_sapiens_Feb_2009/segway/$name.bb
    
    # hg38 
    ./liftOver segway/$bedfile hg19ToHg38.over.chain.gz tmp.hg38.bed unlifted.bed 
    cat tmp.hg38.bed  | sort -k1,1 -k2,2n | perl -p -e 's/^([0-9XYN]+[\t\ ])/chr$1/g' |cut -f 1,2,3,4,5,6  > sorted.bed
    outname=`echo $celltype`_`echo $name |perl -p -e 's/(TF\_)?([^\.]+)\..*$/$2/g'`.bb   
    ./bedToBigBed sorted.bed hg38.chrom.sizes H_sapiens_Dec_2013/segway/$outname
done




# Loops
# from ftp://ftp.ncbi.nlm.nih.gov/geo/series/GSE63nnn/GSE63525/suppl/
mkdir loops

wget --no-verbose -r --no-host-directories --cut-dirs=5 -A '*HiCCUPS_looplist.txt.gz'  ftp://ftp.ncbi.nlm.nih.gov/geo/series/GSE63nnn/GSE63525/suppl/ -P loops

mkdir H_sapiens_Feb_2009/loops/
mkdir H_sapiens_Dec_2013/loops/

for file in loops/*.gz; do 
    #loop
    fileName=`echo $file |cut -d '/' -f 2 |sed 's/_HiCCUPS_looplist.txt.gz//g'`

    # hg19
    gunzip -c   $file | cut -f 1,2,3,5,6 | while read a b c d e; do echo $a $b $e . 1000 . $b $e 255,0,0 2 `echo $c - $b |bc`,`echo $e - $d|bc` 0,`echo $d - $b|bc` |grep -v 'chr1 x1 y2' ;done |gzip  > H_sapiens_Feb_2009/loops/$fileName.contacts.bed.gz
    # hg38
    ./liftOver H_sapiens_Feb_2009/loops/$fileName.contacts.bed.gz hg19ToHg38.over.chain.gz H_sapiens_Dec_2013/loops/$fileName.contacts.bed unlifted.bed  
    gzip H_sapiens_Dec_2013/loops/$fileName.contacts.bed
done



### Lot of data, which one to keep?
# small dataset:
# cell lines: the ones from GSE63525 (loops): CH12 GM12878 HeLa HMEC HUVEC IMR90 K562 KBM7 NHEK
celllines="GM12878 HeLa HMEC HUVEC IMR90 K562 NHEK"

# Roadmap code? :
rm celllines.txt
for cellline in $celllines; do 
echo $cellline `grep $cellline metadata.txt  | cut -f 2`  >> celllines.txt
done


mkdir quickload

# move everything to quickload folder
for assembly in H_sapiens_Feb_2009 H_sapiens_Dec_2013; do  
    while read name id; do
        targetdir=quickload/$assembly/$id-$name
        mkdir -p $targetdir
      
        # roadmap
        mkdir $targetdir/histonemark
        cp $assembly/peaks/$id*narrow*.bb $targetdir/histonemark/
        mkdir $targetdir/tfbs
        cp $assembly/TFBS/$name*.bb $targetdir/tfbs/
    
        # annotations: segway + chrommhmm
        mkdir $targetdir/annotations
        cp $assembly/segway/`echo  $name `* $targetdir/annotations/segway_`echo  $name`.bed.gz
        cp $assembly/ChmmModels/`echo $id`_15_coreMarks_dense.bed.gz $targetdir/annotations/`echo $id`_chromhmm_15_coreMarks_dense.bed.gz
        
        # loops
        mkdir $targetdir/loops
        cp $assembly/loops/GSE63525*$name.contacts.bed.gz $targetdir/loops/

    done < celllines.txt
done


# Create quickload annotation file
for assembly in H_sapiens_Feb_2009 H_sapiens_Dec_2013; do 

    rm quickload/$assembly/annots.xml

    echo "<files>" > quickload/$assembly/annots.xml

    while read name id; do

    for filename in `ls $id-$name/histonemark/ |grep narrow`; do
        echo "  <file title=\"$id-$name/histone-marks/$filename\" name=\"$id-$name/histonemark/$filename\"/>" >> quickload/$assembly/annots.xml
    done
    for filename in `ls $id-$name/tfbs/`; do
        echo "  <file title=\"$id-$name/tfbs/$filename\" name=\"$id-$name/tfbs/$filename\"/>" >> quickload/$assembly/annots.xml
    done
    for filename in `ls $id-$name/annotations/`; do
        echo "  <file title=\"$id-$name/annotations/$filename\" name=\"$id-$name/annotations/$filename\"/>" >> quickload/$assembly/annots.xml
    done
    for filename in `ls $id-$name/loops/`; do
        echo "  <file title=\"$id-$name/loops/$filename\" name=\"$id-$name/loops/$filename\"/>" >> quickload/$assembly/annots.xml
    done
    done <  celllines.txt

    echo "</files>" >> quickload/$assembly/annots.xml
done


echo "H_sapiens_Feb_2009	Homo sapiens (Feb 2009) human being (GRCh37/hg19)" > quickload/contents.txt
echo "H_sapiens_Dec_2013	Homo sapiens (Dec 2013) human being (GRCh38/hg38)" >> quickload/contents.txt

