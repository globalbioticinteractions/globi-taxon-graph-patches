#!/bin/bash
#
# Patch Related to issue:
#  https://github.com/globalbioticinteractions/globalwebdb/issues/1
#

set -xe

function init {
  mkdir -p input output

  # get GloBI taxon graph 0.4.3
  preston cat\
   --remote https://zenodo.org\
   'hash://md5/154da7e73facf3a563f0c846a8c73963'\
  > input/taxonMap.tsv.gz
  
  # also available via
  # curl -L https://zenodo.org/record/10037600/files/taxonMap.tsv.gz > input/taxonMap.tsv.gz

  # Poelen, J. H. (2023). Global Biotic Interactions: Taxon Graph (0.4.3) [Data set]. Zenodo. https://doi.org/10.5281/zenodo.10037600
  
}

function remove_crested_wheatgrass_mappings {
  # attempt to remove suspect mappings like [crested wheatgrass	] -> [Anas platyrhynchos]
  # https://github.com/globalbioticinteractions/globalwebdb/issues/1
  cat input/taxonMap.tsv.gz\
  | gunzip\
  | sed '942719,942724d;942726d'\
  | gzip\
  > output/taxonMap.tsv.gz

}

function create_patch {
  diff <(cat input/taxonMap.tsv.gz | gunzip) <(cat output/taxonMap.tsv.gz | gunzip) | gzip > output/taxonMap.tsv.patch.gz

  cat input/taxonMap.tsv.gz | gunzip > output/taxonMapToBePatched.tsv
  cat output/taxonMap.tsv.patch.gz | gunzip | patch -b output/taxonMapToBePatched.tsv
  cat output/taxonMapToBePatched.tsv | gzip > output/taxonMapPatched.tsv.gz
}

init
remove_crested_wheatgrass_mappings
create_patch
