#!/bin/bash
#
# Patch Related to issue:
#  https://github.com/globalbioticinteractions/globalbioticinteractions/issues/672
#

set -xe

function init {
  mkdir -p input output

  # get GloBI taxon graph 0.3.32
  curl -L https://zenodo.org/record/4753955/files/taxonMap.tsv.gz > input/taxonMap.tsv.gz
}

function remove_likely_suspicious_virus_acronym_mappings {
  # attempt to remove suspect mappings like [Plutella xylostella NPV] -> [Plutella xylostella]
  # see https://github.com/globalbioticinteractions/globalbioticinteractions/issues/672
  cat input/taxonMap.tsv.gz\
  | gunzip\
  | grep -P ".*(NCBI).*\t.*V\t"\
  | gzip\
  > output/taxonMapNCBI_Vs.tsv.gz

  cat input/taxonMap.tsv.gz\
  | gunzip\
  | tail -n+2\
  | grep -v -P ".*\t.*V\t"\
  | gzip\
  > output/taxonMapExcluding_Vs.tsv.gz

  cat output/taxonMapNCBI_Vs.tsv.gz output/taxonMapExcluding_Vs.tsv.gz\
  | sort\
  | uniq\
  > output/taxonMapNoHeader.tsv.gz
 
  cat <(cat input/taxonMap.tsv.gz | gunzip | head -n1 | gzip) <(cat output/taxonMapNoHeader.tsv.gz)\
  > output/taxonMap.tsv.gz

}

function create_patch {
  diff <(cat input/taxonMap.tsv.gz | gunzip) <(cat output/taxonMap.tsv.gz | gunzip) | gzip > output/taxonMap.tsv.patch.gz

  cat input/taxonMap.tsv.gz | gunzip > output/taxonMapToBePatched.tsv
  cat output/taxonMap.tsv.patch.gz | gunzip | patch -b output/taxonMapToBePatched.tsv
  cat output/taxonMapToBePatched.tsv | gzip > output/taxonMapPatched.tsv.gz
}

init
remove_likely_suspicious_virus_acronym_mappings
create_patch
