#!/bin/bash
# GloBI Taxon Graph patch procedure that renames Encyclopedia of Life (EOL) 
# that are no longer supported in EOL v3.
#
# No longer supported EOL ids will change their prefix from:
# EOL:[some id]
# to 
# EOL_V2:[some id]
# EOL v3 was released in Nov 2018.
#
# This precedure was written by Jorrit Poelen on 2018-11-21 
#
set -xe 

mkdir -p output
mkdir -p input

curl "https://zenodo.org/record/1489121/files/taxonCache.tsv.gz" > input/taxonCache.tsv.gz 
curl "https://zenodo.org/record/1489121/files/taxonMap.tsv.gz" > input/taxonMap.tsv.gz 

# create a list of EOL ids in GloBI
zcat input/taxonCache.tsv.gz | cut -f1 | grep -P "^EOL:" | sort | uniq > output/eol_globi_ids.tsv

# create a list of EOL ids available in v3 via
curl https://opendata.eol.org/dataset/b6bb0c9e-681f-4656-b6de-39aa3a82f2de/resource/bac4e11c-28ab-4038-9947-02d9f1b0329f/download/eoldynamichierarchywithlandmarks.zip > input/taxa.zip

unzip -p input/taxa.zip taxa.txt | gzip > input/taxa.tsv.gz

cd output
zcat ../input/taxa.tsv.gz | tail -n+2 | cut -f15 | sort | uniq | grep -v -P "^$" | sed 's/^/EOL:/g' > eol_ids_v3.tsv

diff --unchanged-group-format='' --changed-group-format='%<' eol_globi_ids.tsv eol_ids_v3.tsv  > eol_globi_ids_not_in_v3.tsv || true
paste eol_globi_ids_not_in_v3.tsv eol_globi_ids_not_in_v3.tsv | sed  's/\tEOL/\tEOL_V2/g' > eol_globi_ids_not_in_v3_map.tsv

cat eol_globi_ids_not_in_v3_map.tsv | awk -F '\t' '{ print "s/\\t" $1 "/\\t" $2 "/g" }'  > taxonMap-patch.sed
cat eol_globi_ids_not_in_v3_map.tsv | awk -F '\t' '{ print "s/" $1 "/" $2 "/g" }'  > taxonCache-patch.sed

cat ../input/taxonCache.tsv.gz | gunzip | sed -f taxonCache-patch.sed | gzip > taxonCache.tsv.gz
cat ../input/taxonMap.tsv.gz | gunzip | sed -f taxonMap-patch.sed | gzip > taxonMap.tsv.gz

gzip *.tsv

cd ..

# create patch files
diff <(cat input/taxonCache.tsv.gz | gunzip) <(cat output/taxonCache.tsv.gz| gunzip) | gzip > taxonCache.tsv.patch.gz
diff <(cat input/taxonMap.tsv.gz | gunzip) <(cat output/taxonMap.tsv.gz| gunzip)  | gzip > taxonMap.tsv.patch.gz

