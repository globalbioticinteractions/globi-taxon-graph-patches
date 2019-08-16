#!/bin/bash
#
#

set -xe

mkdir -p input output

# get active EOL dynamic hierarchy as of 2019-08-16 
curl https://editors.eol.org/other_files/DWH/TRAM-809/DH_v1_1.tar.gz > input/eol-dh.tar.gz 
cat input/eol-dh.tar.gz | gunzip | tar -xO ./taxon.tab | cut -f13 | tail -n+2 | sort | uniq | sort -n > output/eol-page-ids.tsv

# get GloBI taxon graph 0.3.13
curl https://zenodo.org/record/3244412/files/taxonMap.tsv.gz > input/taxonMap.tsv.gz
curl https://zenodo.org/record/3244412/files/taxonCache.tsv.gz > input/taxonCache.tsv.gz

zcat input/taxonMap.tsv.gz | tr '\t' '\n' | grep "EOL_V2:" | sed s/EOL_V2://g | sort -n | uniq > output/taxon-map-eol-page-ids-v2.tsv

zcat input/taxonCache.tsv.gz | tr '\t' '\n' | tr '|' '\n' | tr -d ' ' | grep "EOL_V2:" | sed s/EOL_V2://g | sort -n | uniq > output/taxon-cache-eol-page-ids-v2.tsv

cat output/*page-ids-v2.tsv | sort -n | uniq > output/eol-page-ids-v2.tsv

grep -F -x -f output/eol-page-ids-v2.tsv output/eol-page-ids.tsv | sed 's+^+s/\\(EOL_V2:\\)\\(+g' | sed 's+$+\\)\\([^0-9]\\)/EOL:\\2\\3\/+g' > output/eol-page-ids-v2-fix.sed

zcat input/taxonCache.tsv.gz | sed -f output/eol-page-ids-v2-fix.sed | gzip > output/taxonCache.tsv.gz

zcat input/taxonMap.tsv.gz | sed -f output/eol-page-ids-v2-fix.sed | gzip > output/taxonMap.tsv.gz

diff <(cat input/taxonCache.tsv.gz | gunzip) <(cat output/taxonCache.tsv.gz| gunzip) | gzip > taxonCache.tsv.patch.gz
diff <(cat input/taxonMap.tsv.gz | gunzip) <(cat output/taxonMap.tsv.gz| gunzip) | gzip > taxonMap.tsv.patch.gz

