#!/bin/bash
#
# Patch Related to issues:
#  https://github.com/globalbioticinteractions/globalbioticinteractions/issues/640
#

set -xe

function init {
  mkdir -p input output

  # get GloBI taxon graph 0.3.30
  curl -L https://zenodo.org/record/4593724/files/taxonMap.tsv.gz > input/taxonMap.tsv.gz
  curl -L https://zenodo.org/record/4593724/files/taxonCache.tsv.gz > input/taxonCache.tsv.gz
}

function patch_eol_virus_names {
 cat input/taxonCache.tsv.gz\
 | gunzip\
 | grep "EOL.*Viruses"\
 | cut -f5\
 | grep -o -E "[^|]+*$"\
 | sed 's/^ //g'\
 > output/eol-virus-names-from-path.tsv

  cat input/taxonCache.tsv.gz\
  | gunzip\
  | grep "EOL.*Viruses"\
  > output/eol-virus-names.tsv

  paste output/eol-virus-names-from-path.tsv output/eol-virus-names.tsv\
  | cut -f1,2,5-\
  > output/eol-virus-id-names-patched.tsv

  paste <(cut -f1,2 output/eol-virus-names.tsv) output/eol-virus-names-from-path.tsv\
  | awk -F '\t' '{ print "s+" $1 "\\t" $2 "$+" $1 "\\t" $3 "+g" }'\
  > output/replace-end.sed 
 
  paste <(cut -f1,2 output/eol-virus-names.tsv) output/eol-virus-names-from-path.tsv\
  | awk -F '\t' '{ print "s+^" $1 "\\t" $2 "\\t+" $1 "\\t" $3 "\\t+g" }'\
  > output/replace-start.sed
  
  cat input/taxonMap.tsv.gz\
  | gunzip\
  | sed -f output/replace-end.sed\
  | gzip\
  > output/taxonMap.tsv.gz

  cat input/taxonCache.tsv.gz\
  | gunzip\
  | sed -f output/replace-start.sed\
  | gzip\
  > output/taxonCache.tsv.gz
}

function create_patch {
  diff <(cat input/taxonCache.tsv.gz | gunzip) <(cat output/taxonCache.tsv.gz | gunzip) | gzip > output/taxonCache.tsv.patch.gz
  diff <(cat input/taxonMap.tsv.gz | gunzip) <(cat output/taxonMap.tsv.gz | gunzip) | gzip > output/taxonMap.tsv.patch.gz

  cat input/taxonCache.tsv.gz | gunzip > output/taxonCacheToBePatched.tsv
  cat output/taxonCache.tsv.patch.gz | gunzip | patch -b output/taxonCacheToBePatched.tsv
  cat output/taxonCacheToBePatched.tsv | gzip > output/taxonCachePatched.tsv.gz

  cat input/taxonMap.tsv.gz | gunzip > output/taxonMapToBePatched.tsv
  cat output/taxonMap.tsv.patch.gz | gunzip | patch -b output/taxonMapToBePatched.tsv
  cat output/taxonMapToBePatched.tsv | gzip > output/taxonMapPatched.tsv.gz
}

init
patch_eol_virus_names
create_patch
