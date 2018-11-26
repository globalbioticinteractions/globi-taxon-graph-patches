#!/bin/bash
#
# Remove suspicious name mappings to Humpback scorpionfish (Scorpaenopsis gibbosa)
# The name mappings existed as far back as GloBI Taxon Graph v0.1.0 (Jan 2018, http://doi.org/10.5281/zenodo.265895) and is suspected to be introduced by a name index bug that mapped "no name" taxa to the first resolve taxon. 
#
# Also see https://github.com/jhpoelen/eol-globi-data/issues/385 .

mkdir -p input output

set -xe

wget https://zenodo.org/record/1495302/files/taxonMap.tsv.gz -O input/taxonMap.tsv.gz

zcat input/taxonMap.tsv.gz | tail -n+2 | grep  -v -P "Scorpaenopsis gibbosa"  | gzip > output/taxonMapPatched.tsv.gz
zcat input/taxonMap.tsv.gz | head -n1 | gzip > output/header.tsv.gz
zcat input/taxonMap.tsv.gz | grep  -P "(Scorpaenopsis gibbosa).*Scorpaenopsis gibbosa$" | gzip > output/Scorpaenopsis_gibbosa_identity_mapping.tsv.gz
cat output/header.tsv.gz output/taxonMapPatched.tsv.gz output/Scorpaenopsis_gibbosa_identity_mapping.tsv.gz > output/taxonMap.tsv.gz 

md5sum output/taxonMap.tsv.gz | cut -d ' ' -f1 > output/taxonMap.tsv.gz.md5

# create patch file
diff <(cat input/taxonMap.tsv.gz | gunzip) <(cat output/taxonMap.tsv.gz| gunzip)  | gzip > taxonMap.tsv.patch.gz
zcat taxonMap.tsv.patch.gz | sha256sum | cut -d ' ' -f1 > taxonMap.tsv.patch.sha256
