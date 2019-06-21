
# encode codes
codes="E017 E116 E117 E122 E123 E127"


# Datasets: Encode, Roadmap, Segway, chrommhmm, loops

# Chrommhmm Roadmap: hg19
# from http://egg2.wustl.edu/roadmap/data/byFileType/chromhmmSegmentations/ChmmModels/coreMarks/jointModel/final/*.dense.bed.bgz.*

mkdir ChmmModels
cd ChmmModels
for code in $codes; do 
wget  http://egg2.wustl.edu/roadmap/data/byFileType/chromhmmSegmentations/ChmmModels/coreMarks/jointModel/final/`echo $code`_15_coreMarks_dense.bed.gz
done


cd ..


# TFs:
# from http://egg2.wustl.edu/roadmap/src/chromHMM/bin/COORDS/hg19/TFBS/
mkdir TFBS
cd TFBS
wget -r --no-host-directories --cut-dirs=7 -A '*.bed.gz' http://egg2.wustl.edu/roadmap/src/chromHMM/bin/COORDS/hg19/TFBS/

# make bb
wget http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/fetchChromSizes
wget http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/bedToBigBed

chmod +x bedToBigBed
sh fetchChromSizes hg19 > hg19.chrom.sizes

for dir in `echo */`; do 
 celltype=${dir%%/}
 cd $celltype
 for bedfile in *.bed.gz; do
   name=${bedfile%.gz}
   echo $name
   zcat $bedfile | sort -k1,1 -k2,2n | perl -p -e 's/^([0-9XYN]+[\t\ ])/chr$1/g' |cut -f 1,2,3,4,5,6  > sorted.bed
   outname=`echo $celltype`_`echo $name |perl -p -e 's/(TF\_)?([^\.]+)\..*$/$2/g'`.bb   
   ../bedToBigBed sorted.bed ../hg19.chrom.sizes $outname
  done
  cd ..
done

cd ..

# RoadMap, histone marks: 
# http://egg2.wustl.edu/roadmap/data/byFileType/peaks/consolidated/narrowPeak/
# http://egg2.wustl.edu/roadmap/data/byFileType/peaks/consolidated/gappedPeak/
# http://egg2.wustl.edu/roadmap/data/byFileType/peaks/consolidated/narrowPeak/
mkdir peaks
cd peaks

for code in $codes; do 
 echo "wget -r --no-host-directories --cut-dirs=7 -A '`echo $code`*.broadPeak.gz' http://egg2.wustl.edu/roadmap/data/byFileType/peaks/consolidated/broadPeak/"
 wget -qO - http://egg2.wustl.edu/roadmap/data/byFileType/peaks/consolidated/broadPeak/ | sed -n 's#^.*href="\([^"]\{1,\}\)".*$#\1#p'  | cut -d\# -f2 | grep $code |\
  while read url; do wget http://egg2.wustl.edu/roadmap/data/byFileType/peaks/consolidated/broadPeak/$url; done
done

for code in $codes; do 
 echo "wget -r --no-host-directories --cut-dirs=7 -A '`echo $code`*.narrowPeak.gz' http://egg2.wustl.edu/roadmap/data/byFileType/peaks/consolidated/narrowPeak/"
 wget -qO - http://egg2.wustl.edu/roadmap/data/byFileType/peaks/consolidated/narrowPeak/ | sed -n 's#^.*href="\([^"]\{1,\}\)".*$#\1#p'  | cut -d\# -f2 | grep $code |\
  while read url; do wget http://egg2.wustl.edu/roadmap/data/byFileType/peaks/consolidated/narrowPeak/$url; done
done



# transform broadpeak/narrowPeak to bigbed
wget http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/fetchChromSizes
wget http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/bedToBigBed

chmod +x bedToBigBed
sh fetchChromSizes hg19 > hg19.chrom.sizes
sh fetchChromSizes hg38 > hg38.chrom.sizes

for code in $codes; do 
 for bedfile in $code*Peak.gz; do
  name=${bedfile%.gz}
  echo $name
  zcat $bedfile | sort -k1,1 -k2,2n | perl -p -e 's/^([0-9XYN]+[\t\ ])/chr$1/g' |cut -f 1,2,3,4,5,6  | perl -p -e 's/(\t[0-9]{4}\t\.)$/\t1000\t\./g' | python /home/aceol/Work/workspace/simsearch/simsearch-bundle/src/scripts/cutPeaksOutOfChromosome.py hg19.chrom.sizes> sorted.bed
  ./bedToBigBed sorted.bed hg19.chrom.sizes $name.bb
 done
done > output.txt

cd .. 

# Groups to cell type: https://docs.google.com/spreadsheets/d/1yikGx4MsO9Ei36b64yOy9Vb6oPC5IBGlFbYEt-N6gOM/edit#gid=15
# tsv: https://docs.google.com/spreadsheets/d/1yikGx4MsO9Ei36b64yOy9Vb6oPC5IBGlFbYEt-N6gOM/export?format=tsv&id=1yikGx4MsO9Ei36b64yOy9Vb6oPC5IBGlFbYEt-N6gOM&gid=15
wget -O metadata.txt "https://docs.google.com/spreadsheets/d/1yikGx4MsO9Ei36b64yOy9Vb6oPC5IBGlFbYEt-N6gOM/export?format=tsv&id=1yikGx4MsO9Ei36b64yOy9Vb6oPC5IBGlFbYEt-N6gOM&gid=15"



# Segway encyclopedia
# http://noble.gs.washington.edu/proj/encyclopedia/
# encyclopedia:
mkdir segway
cd segway

#wget http://noble.gs.washington.edu/proj/encyclopedia/interpreted/gm12878.bed.gz
wget http://noble.gs.washington.edu/proj/encyclopedia/interpreted/H1-HESC.bed.gz
##wget http://noble.gs.washington.edu/proj/encyclopedia/interpreted/helas3.bed.gz
wget http://noble.gs.washington.edu/proj/encyclopedia/interpreted/HEPG2.bed.gz
wget http://noble.gs.washington.edu/proj/encyclopedia/interpreted/HUVEC.bed.gz
wget http://noble.gs.washington.edu/proj/encyclopedia/interpreted/K562.bed.gz


cd ..

# Loops
# from ftp://ftp.ncbi.nlm.nih.gov/geo/series/GSE63nnn/GSE63525/suppl/
mkdir GSE63525
cd GSE63525
wget -r --no-host-directories --cut-dirs=5 -A '*HiCCUPS_looplist.txt.gz'  ftp://ftp.ncbi.nlm.nih.gov/geo/series/GSE63nnn/GSE63525/suppl/


for file in *.gz; do 
#loop
fileName=`echo $file |sed 's/_HiCCUPS_looplist.txt.gz//g'`
gunzip -c   $file | cut -f 1,2,3,5,6 |grep -v chr1 | while read a b c d e; do echo $a $b $e . 1000 . $b $e 255,0,0 2 `echo $c - $b |bc`,`echo $e - $d|bc` 0,`echo $d - $b|bc` ;done |gzip  > $fileName.contacts.bed.gz
#contacts only
done



### Lot of data, which one to keep?
# small dataset:
# cell lines: the ones from GSE63525 (loops): CH12 GM12878 HeLa HMEC HUVEC IMR90 K562 KBM7 NHEK
celllines="CH12 GM12878 HeLa HMEC HUVEC IMR90 K562 KBM7 NHEK"

# Roadmap code? :
rm celllines.txt
for cellline in $celllines; do 
echo $cellline `grep $cellline metadata.txt  | cut -f 2`  >> celllines.txt
done


sourcedir=/media/aceol/data/simsearch-quickload-src/
targetdir=`pwd`
cd $targetdir


while read name id; do
    mkdir $id-$name
    cd $id-$name
    
    # roadmap
    mkdir histonemark
    cp $sourcedir/peaks/$id*narrow*.bb histonemark/
    mkdir tfbs
    cp $sourcedir/TFBS/$name/*.bb tfbs/
  
	  # annotations: segway + chrommhmm
	  mkdir annotations
    cp $sourcedir/segway/`echo  $name `* annotations/segway_`echo  $name`.bed.gz
    cp $sourcedir/ChmmModels/`echo $id`_15_coreMarks_dense.bed.gz annotations/`echo $id`_chromhmm_15_coreMarks_dense.bed.gz
    
    # loops
    mkdir loops
    cp $sourcedir/GSE63525/*$name.contacts.bed.gz loops/
    
    cd ..
done < $sourcedir/celllines.txt

rm annots.xml

echo "<files>" > annots.xml

while read name id; do

for filename in `ls $id-$name/histonemark/ |grep narrow`; do
    echo "  <file title=\"$id-$name/histone-marks/$filename\" name=\"$id-$name/histonemark/$filename\"/>" >> annots.xml
done
for filename in `ls $id-$name/tfbs/`; do
    echo "  <file title=\"$id-$name/tfbs/$filename\" name=\"$id-$name/tfbs/$filename\"/>" >> annots.xml
done
for filename in `ls $id-$name/annotations/`; do
    echo "  <file title=\"$id-$name/annotations/$filename\" name=\"$id-$name/annotations/$filename\"/>" >> annots.xml
done
for filename in `ls $id-$name/loops/`; do
    echo "  <file title=\"$id-$name/loops/$filename\" name=\"$id-$name/loops/$filename\"/>" >> annots.xml
done
done <  $sourcedir/celllines.txt

echo "</files>" >> annots.xml


echo "H_sapiens_Feb_2009	Homo sapiens (Feb 2009) human being (GRCh37/hg19)" > contents.txt


