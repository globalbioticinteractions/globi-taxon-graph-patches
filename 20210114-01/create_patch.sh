#!/bin/bash
#
# Patch Related to issues:
#  https://github.com/globalbioticinteractions/globi-taxon-names/issues/6
#  https://github.com/globalbioticinteractions/globalbioticinteractions/issues/569
#  https://github.com/globalbioticinteractions/globalbioticinteractions/issues/243
#  https://github.com/GlobalNamesArchitecture/gni/issues/48
#

set -xe

function init {
  mkdir -p input output

  # get GloBI taxon graph 0.3.27
  curl -L https://zenodo.org/record/4118439/files/taxonMap.tsv.gz > input/taxonMap.tsv.gz
  curl -L https://zenodo.org/record/4118439/files/taxonCache.tsv.gz > input/taxonCache.tsv.gz

  # get nomer v0.1.20
  curl -L "https://github.com/globalbioticinteractions/nomer/releases/download/0.1.20/nomer.jar" > input/nomer.jar
}

function resolve {
  cat input/taxonMap.tsv.gz \
 | gunzip\
 | grep "NCBI:"\
 | tail -n+2\
 | cut -f1,2\
 | sort\
 | uniq\
 | java -jar input/nomer.jar append ncbi-taxon-id\
 | gzip\
 > output/ncbi-matches.tsv.gz

  cat output/ncbi-matches.tsv.gz \
 | gunzip\
 | grep "NONE"\
 | cut -f1,2\
 | sort\
 | uniq\
 | java -jar input/nomer.jar append globi-globalnames\
 | gzip\
 >> output/gn-matches.tsv.gz
}

function resolve_paths_for_gn_matches {
 # re-resolve gn matches to avoid including truncated ncbi paths
 cat output/gn-matches.tsv.gz \
 | gunzip\
 | grep -v "NONE"\
 | cut -f4,5\
 | sort\
 | uniq\
 | java -jar input/nomer.jar append ncbi-taxon-id\
 | gzip\
 > output/gn-matches-with-original-paths.tsv.gz
}

function merge {
  # merge newly resolved ncbi taxa into taxon graph
  cat output/ncbi-matches.tsv.gz output/gn-matches.tsv.gz\
| gunzip\
| grep -v NONE\
| cut -f1,2,4,5\
| gzip\
> output/taxonMapNCBI.tsv.gz

  # do not use gn paths because they contain incorrectly parsed names
  resolve_paths_for_gn_matches

  cat output/ncbi-matches.tsv.gz output/gn-matches-with-original-paths.tsv.gz\
| gunzip\
| grep -v NONE\
| cut -f6-\
| gzip\
> output/taxonCacheNCBI.tsv.gz

  cat input/taxonCache.tsv.gz\
 | gunzip\
 | head -n1\
 | gzip\
 > output/taxonCache1.tsv.gz

  cat input/taxonCache.tsv.gz output/taxonCacheNCBI.tsv.gz\
 | gunzip\
 | tail -n+2\
 | sort\
 | uniq\
 | gzip\
 >> output/taxonCache1.tsv.gz

  cat input/taxonMap.tsv.gz\
 | gunzip\
 | head -n1\
 | gzip\
 > output/taxonMap1.tsv.gz

  cat input/taxonMap.tsv.gz\
 | gunzip\
 | tail -n+2\
 | grep -v "NCBI:"\
 | gzip\
 > output/taxonMapNoNCBI.tsv.gz

  cat output/taxonMapNoNCBI.tsv.gz output/taxonMapNCBI.tsv.gz\
 | gunzip\
 | sort\
 | uniq\
 | gzip\
 >> output/taxonMap1.tsv.gz
}

function create_patch {
  diff <(cat input/taxonCache.tsv.gz | gunzip) <(cat output/taxonCache1.tsv.gz| gunzip) | gzip > output/taxonCache.tsv.patch.gz
  diff <(cat input/taxonMap.tsv.gz | gunzip) <(cat output/taxonMap1.tsv.gz| gunzip) | gzip > output/taxonMap.tsv.patch.gz

  cat input/taxonCache.tsv.gz | gunzip > output/taxonCacheToBePatched.tsv
  cat output/taxonCache.tsv.patch.gz | gunzip | patch -b output/taxonCacheToBePatched.tsv
  cat output/taxonCacheToBePatched.tsv | gzip > output/taxonCachePatched.tsv.gz

  cat input/taxonMap.tsv.gz | gunzip > output/taxonMapToBePatched.tsv
  cat output/taxonMap.tsv.patch.gz | gunzip | patch -b output/taxonMapToBePatched.tsv
  cat output/taxonMapToBePatched.tsv | gzip > output/taxonMapPatched.tsv.gz
}

init
resolve
merge
create_patch
