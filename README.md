# Introduction to Geocoding

**Geocoding** is the process of associating geographic coordinates (latitude and longitude) with the name of a place. 
The place could be a building, a town, a county, a state--any location with coordinates can be **geocoded**. 

For large places, like states, we have two options. First, we can build a codebase that allows us to associate more 
than one coordinate with a location. Then we can provide all the coordinates that, with straight lines between, form 
the border of the area (like a dot-to-dot). The second option is to simply choose the center-most point of the area 
as the coordinate set. This is the easier and more common choice, and the approach we will use in this tutorial. 

To obtain geographic coordinates for a place name, we normally need to use a **geocoding API**. This is a service that 
allows 
us to look up geographic coordinates. There are many Geocoding APIs available, but most of them cost money either 
upfront or after a certain number of searches. If you're a Stanford student, there is a Stanford geocoding API 
available to you for unlimited searches. 

In this tutorial, we will take a different approach. We will **geocode** a text using **Wikification**. Wikification 
is the process of associating a stable Wikipedia or Wikidata identifier with an entity. Fortunately for us, 
Wikipedia pages for every entity that can be considered a place or location has listed geographic coordinates. 

## Data Pipeline

The first thing we will do is perform **named entity recognition** on our dataset. This will provide us with a list 
of **named entities**, including locations, that are in our dataset. We will perform NER using [Stanford CoreNLP]
(https://stanfordnlp.github.io/CoreNLP/). Then, we will filter our results by entity type so that we are left only 
with a list of location names.

Next, we will find the geographic coordinates for those locations using **pywikibot**, a Python package available 
from WikiData that allows for Python-based API lookups. 

Finally, we will format and return a list of location names and their geographic coordinates. In summary, our 
process is:
1. Perform NER on the dataset.
2. Filter the NER results to get **location** entities.
3. Use PyWikiBot to find the coordinates for each location.
4. Format and return results.

This entire process is performed in **geocode.sh**. For a detailed explanation of **geocode.sh**, see the section below.

## Quickstart

Make sure all the data files (.txt files) you want geocoded are located in a directory on Sherlock.

Clone this repository into Sherlock. I recommend cloning the repository into the top level of your scratch.

`git clone https://github.com/AnnieKLamar/geocode`

Navigate to the directory where you cloned the above repository. Open `geocode.sbatch`:

`nano geocode.sbatch`

Replace `geotagging_corpus` in the final line of the file with the full path to your data directory. For example, if 
you put your text 
files in a folder named "corpus" inside scratch, the final line would read (where $USER is your username):

`bash geocode.sh -d /scratch/users/$USER/corpus_directory`

Save the changes you made to the file by pressing CTRL+O (capital letter o). Press enter to confirm the save. Exit 
nano with CTRL+C. If you want to verify your changes were saved, you can look at the file:

`cat geocode.sbatch`

Now open `geocode.sh` and make sure that the penultimate line includes the directory where you cloned the GitHub 
repository. If you cloned the repository into the top level of your scratch, you can skip this step. Otherwise, open 
the file and make the necessary change:

`cd /scratch/users/$USER #CHANGE THIS `

You can now run the geocoding script with the 
following line. 

`sbatch geocode.sbatch`

Your results will appear as a .csv file wherever you cloned the GitHub repository. The time required will depend on 
how large your dataset is.

## geocode.sbatch
The following is a line-by-line description of the contents of `geocode.sbatch`.

`#!/bin/bash`
This line appears at the top of every .sbatch file and shell script.

`#SBATCH --job-name=geocode` This is the name of our project. You can change it.

`#SBATCH --output=/home/users/%u/out/geocode.%j.out` This is where the non-error outputs will go. 

`#SBATCH --error=/home/users/%u/err/geocode.%j.err` This is where error outputs will go.

`#SBATCH -p hns` We are running the project on the HNS partition.

`#SBATCH --mem=16GB` We are asking for 16GB of memory space. 

`#SBATCH -c 4` We are asking for 4 CPUs.

`ml purge` Purge any loaded modules.

`ml java` Load the Java module.

`chmod +x geocode.sh` This makes geocode.sh an executable script.

`bash geocode.sh -d geotagging_corpus` Run geocode.sh.

# geocode.sh

    while getopts d: flag
    do
            case "${flag}" in
                    d) corpus_directory=${OPTARG};;
            esac
    done

This loop tells the script to expect a parameter after the variable `d`. We name that variable `corpus_directory`, 
and we can access it later with `$corpus_directory`.

    ml purge
    ml java/18.0.2 python/3.12.1 py-pandas/2.0.1_py39

These lines purge all loaded modules and re-load the specific version of Java we need.

    rm -r /scratch/user/$USER/stanford-corenlp*

This line removes a current installation of CoreNLP. This helps us avoid errors.

    wget https://nlp.stanford.edu/software/stanford-corenlp-4.5.5.zip -P /scratch/users/$USER
    unzip /scratch/users/$USER/stanford-corenlp-4.5.5.zip -d /scratch/users/$USER

Now we download and install CoreNLP.

    cd /scratch/users/$USER/stanford-corenlp-4.5.5
    echo -e "\nCollecting extra models for wikification... \n"
    wget https://huggingface.co/stanfordnlp/corenlp-english-kbp/resolve/main/stanford-corenlp-models-english-kbp.jar https://huggingface.co/stanfordnlp/corenlp-english-extra/resolve/main/stanford-corenlp-models-english-extra.jar -P /scratch/users/$USER/stanford-corenlp-4.5.5/

We navigate into the directory where CoreNLP was installed. We need to download some extra modules to perform 
Wikification. We can download (`wget`) both necessary modules on one line.

    unzip -o /scratch/users/$USER/stanford-corenlp-4.5.5/stanford-corenlp-models-english-extra.jar -d /scratch/users/$USER/stanford-corenlp.4.5.5/
    unzip -o /scratch/users/$USER/stanford-corenlp-4.5.5/stanford-corenlp-models-english-kbp.jar -d /scratch/users/$USER/stanford-corenlp.4.5.5/
    zip /scratch/users/$USER/stanford-corenlp.4.5.5/stanford-corenlp-4.5.5-models.jar /scratch/users/$USER/stanford-corenlp.4.5.5/stanford-corenlp-4.5.5-models.jar /scratch/users/$USER/stanford-corenlp.4.5.5/stanford-corenlp-models-english-extra.jar /scratch/users/$USER/stanford-corenlp.4.5.5/stanford-corenlp-models-english-kbp.jar

We want both the modules we downloaded in one file. To combine them, we need to unzip both files individually and then 
re-zip 
them together.

    for file in `find . -name "*.jar"`; do export
    CLASSPATH="$CLASSPATH:`realpath $file`"; done

A `.jar` file is like a `.zip` file for files that contain Java code. Java packages are bundled into executable `.
jar` files. To run these files in bash, we need to specify the `CLASSPATH`. The above loop goes through each file 
that ends in `.jar` and adds the absolute pathname (`realpath $file`) to the `CLASSPATH`.


    ls -d -1 /scratch/users/$USER/$corpus_directory/*.* > /scratch/users/$USER/filelist.lst

We add the names of every file in the user-specified `$corpus_directory` to a list inside a file named `filelist.lst`.

    mkdir -p /scratch/users/$USER/outputs/coreEntities
    java -cp "*" -Xmx16g edu.stanford.nlp.pipeline.StanfordCoreNLP -annotators tokenize,pos,lemma,ner,entitylink -filelist "/scratch/users/$USER/filelist.lst" -outputDirectory "/scratch/users/$USER/outputs/coreEntities/"

These lines perform NER using CoreNLP and store the output we need in a directory we made named `coreEntities`.

    grep "LOCATION Wikipedia" /scratch/users/$USER/outputs/coreEntities/*.out | sed 's/.*\=//' | sed 's/]//' >
    /scratch/users/$USER/outputs/coreEntities/entities.txt
    entities="/scratch/users/$USER/outputs/coreEntities/entities.txt"

We find any named-entities that are locations with a Wikipedia ID and store them in a .txt file named `entities.txt`.
Then, we assign the variable name `entities` to that file for easy reference.

    python3 -m pip install pywikibot

PyWikiBot is the Python package we will use to gather coordinate information. We need to install it because it is 
not a pre-loaded Sherlock module. 
    
    cd /scratch/users/$USER

This line might look different depending on where you cloned the GitHub repository. We want to navigate back to that 
directory. 

    python3 geocode.py $entities

Finally! We run the Python script that associates coordinates with location entities.

## geocode.py

This Python script associates coordinates with location entities. Since it is thoroughly commented, please look 
inside the file for more information. 