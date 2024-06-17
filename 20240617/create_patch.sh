#!/bin/bash
#
# Patch Related to issue:
#  https://github.com/globalbioticinteractions/globalbioticinteractions/issues/968
#

set -xe

function init {
  mkdir -p input output

  # get GloBI taxon graph 0.4.5
  preston cat\
   --remote https://zenodo.org\
   'hash://md5/feea1349e9c92140ee25df8a66c8773a'\
  > input/taxonMap.tsv.gz
  
  # also available via
  # curl -L https://zenodo.org/records/10045365/files/taxonMap.tsv.gz > input/taxonMap.tsv.gz


  # Poelen, J. H. (2023). Global Biotic Interactions: Taxon Graph (0.4.5) [Data set]. Zenodo. https://doi.org/10.5281/zenodo.10045365
  
}

function remove_candidatus_mappings {
  # attempt to remove suspect mappings like [crested wheatgrass	] -> [Anas platyrhynchos]
  # https://github.com/globalbioticinteractions/globalbioticinteractions/issues/968
  cat input/taxonMap.tsv.gz\
  | gunzip\
  | grep -v "Candidatus"\
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
remove_candidatus_mappings
create_patch
