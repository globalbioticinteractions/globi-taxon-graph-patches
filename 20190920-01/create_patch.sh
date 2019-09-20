#!/bin/bash
#
#

set -xe

mkdir -p input output

# get active EOL dynamic hierarchy as of 2019-09-20 
curl https://editors.eol.org/other_files/DWH/TRAM-809/DH_v1_1.tar.gz > input/eol-dh.tar.gz 
cat input/eol-dh.tar.gz | gunzip | tar -xO ./taxon.tab | cut -f13 | tail -n+2 | grep "^[0-9]" | sort -n | uniq > output/eol-page-ids.tsv

# get GloBI taxon graph 0.3.15
curl https://zenodo.org/record/3378125/files/taxonMap.tsv.gz > input/taxonMap.tsv.gz
curl https://zenodo.org/record/3378125/files/taxonCache.tsv.gz > input/taxonCache.tsv.gz


# select previously assumed inactive eol pages using EOL dynamic hierarchy and map to EOL: prefix
zcat input/taxonMap.tsv.gz | tr '\t' '\n' | grep "EOL_V2:" | sed s/EOL_V2://g | sort -n | uniq > output/taxon-map-eol-page-ids-v2.tsv

zcat input/taxonCache.tsv.gz | tr '\t' '\n' | tr '|' '\n' | tr -d ' ' | grep "EOL_V2:" | sed s/EOL_V2://g | sort -n | uniq > output/taxon-cache-eol-page-ids-v2.tsv

cat output/*page-ids-v2.tsv | sort -n | uniq > output/eol-page-ids-v2.tsv

grep -F -x -f output/eol-page-ids-v2.tsv output/eol-page-ids.tsv | sed 's+^+s/\\(EOL_V2:\\)\\(+g' | sed 's+$+\\)\\([^0-9]\\)/EOL:\\2\\3\/g+g' > output/eol-page-ids-v2-fix.sed

zcat input/taxonCache.tsv.gz | sed -f output/eol-page-ids-v2-fix.sed | gzip > output/taxonCache0.tsv.gz

zcat input/taxonMap.tsv.gz | sed -f output/eol-page-ids-v2-fix.sed | gzip > output/taxonMap0.tsv.gz



# select assumed inactive eol pages using EOL dynamic hierarchy and map to EOL_V2: prefix
zcat input/taxonMap.tsv.gz | cut -f3 | grep -P "^EOL:[0-9]" | sed s/EOL://g | sort -n | uniq > output/taxon-map-eol-page-ids.tsv
zcat input/taxonCache.tsv.gz | tr '\t' '\n' | tr '|' '\n' | tr -d ' ' | grep "EOL:" | sed s/EOL://g | sort -n | uniq > output/taxon-cache-eol-page-ids.tsv

cat output/taxon-map-eol-page-ids.tsv output/taxon-cache-eol-page-ids.tsv | sort -n | uniq > output/globi-eol-page-ids.tsv

diff --unchanged-group-format='' --changed-group-format='%<' output/globi-eol-page-ids.tsv output/eol-page-ids.tsv > output/globi-eol-page-ids-inactive.tsv || true

cat output/globi-eol-page-ids-inactive.tsv | sed 's+^+s/\\(EOL:\\)\\(+g' | sed 's+$+\\)\\([^0-9]\\)/EOL_V2:\\2\\3\/g+g' > output/eol-page-ids-inactive-cache.sed

cat output/globi-eol-page-ids-inactive.tsv | sed 's+^+s/\\(\\t\\)\\(EOL:\\)\\(+g' | sed 's+$+\\)\\([^0-9]\\)/\\1EOL_V2:\\3\\4\/+g' > output/eol-page-ids-inactive-map.sed

zcat output/taxonCache0.tsv.gz | sed -f output/eol-page-ids-inactive-cache.sed | gzip > output/taxonCache1.tsv.gz
zcat output/taxonMap0.tsv.gz | sed -f output/eol-page-ids-inactive-map.sed | gzip > output/taxonMap1.tsv.gz

diff <(cat input/taxonCache.tsv.gz | gunzip) <(cat output/taxonCache1.tsv.gz| gunzip) | gzip > output/taxonCache.tsv.patch.gz
diff <(cat input/taxonMap.tsv.gz | gunzip) <(cat output/taxonMap1.tsv.gz| gunzip) | gzip > output/taxonMap.tsv.patch.gz
