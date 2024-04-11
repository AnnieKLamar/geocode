#!/bin/sh

while getopts d: flag
do
        case "${flag}" in
                d) corpus_directory=${OPTARG};;
        esac
done
# load modules
ml purge
ml java/18.0.2 python/3.12.1 py-pandas/2.0.1_py39

# remove current installation of CoreNLP
echo -e "\nRemoving current installation of Stanford CoreNLP... \n"
rm -r /scratch/user/$USER/stanford-corenlp*
# install CoreNLP
echo -e "\Installing Stanford CoreNLP... \n"
wget https://nlp.stanford.edu/software/stanford-corenlp-4.5.5.zip -P /scratch/users/$USER
unzip /scratch/users/$USER/stanford-corenlp-4.5.5.zip -d /scratch/users/$USER
# navigate into CoreNP and download extra Wikification modules
cd /scratch/users/$USER/stanford-corenlp-4.5.5
echo -e "\nCollecting extra models for wikification... \n"
wget https://huggingface.co/stanfordnlp/corenlp-english-kbp/resolve/main/stanford-corenlp-models-english-kbp.jar https://huggingface.co/stanfordnlp/corenlp-english-extra/resolve/main/stanford-corenlp-models-english-extra.jar -P /scratch/users/$USER/stanford-corenlp-4.5.5/
# unzip all downloaded modules and re-zip them togetherd
unzip -o /scratch/users/$USER/stanford-corenlp-4.5.5/stanford-corenlp-models-english-extra.jar -d /scratch/users/$USER/stanford-corenlp.4.5.5/
unzip -o /scratch/users/$USER/stanford-corenlp-4.5.5/stanford-corenlp-models-english-kbp.jar -d /scratch/users/$USER/stanford-corenlp.4.5.5/
zip /scratch/users/$USER/stanford-corenlp.4.5.5/stanford-corenlp-4.5.5-models.jar /scratch/users/$USER/stanford-corenlp.4.5.5/stanford-corenlp-4.5.5-models.jar /scratch/users/$USER/stanford-corenlp.4.5.5/stanford-corenlp-models-english-extra.jar /scratch/users/$USER/stanford-corenlp.4.5.5/stanford-corenlp-models-english-kbp.jar
# export all .jar files
echo -e "\nEstablishing classpath... \n"
for file in `find . -name "*.jar"`; do export
CLASSPATH="$CLASSPATH:`realpath $file`"; done
echo -e "\nWikifying text... \n"
# get all files in specified corpus directory
ls -d -1 /scratch/users/$USER/$corpus_directory/*.* > /scratch/users/$USER/filelist.lst
# NER with Wikification links into outputs/coreEntities
mkdir -p /scratch/users/$USER/outputs/coreEntities
java -cp "*" -Xmx16g edu.stanford.nlp.pipeline.StanfordCoreNLP -annotators tokenize,pos,lemma,ner,entitylink -filelist "/scratch/users/$USER/filelist.lst" -outputDirectory "/scratch/users/$USER/outputs/coreEntities/"
# get only locations with Wikipedia IDs from coreEntities
grep "LOCATION Wikipedia" /scratch/users/$USER/outputs/coreEntities/*.out | sed 's/.*\=//' | sed 's/]//' >
/scratch/users/$USER/outputs/coreEntities/entities.txt
entities="/scratch/users/$USER/outputs/coreEntities/entities.txt"
# Install pywikibotcd
python3 -m pip install pywikibot
# Wikify
cd /scratch/users/$USER
python3 geocode.py $entities
