#!/bin/bash

#SBATCH --job-name=geocode
#SBATCH --output=/home/users/%u/out/geocode.%j.out
#SBATCH --error=/home/users/%u/err/geocode.%j.err
#SBATCH -p hns
#SBATCH --mem=16GB
#SBATCH -c 4

ml purge
ml java
chmod +x geocode.sh
bash geocode.sh -d geotagging_corpus
