#!/bin/bash
#
# Patch Related to issues: 
#  https://github.com/globalbioticinteractions/globi-taxon-names/issues/6
#  https://github.com/globalbioticinteractions/globalbioticinteractions/issues/569
#  https://github.com/globalbioticinteractions/globalbioticinteractions/issues/243
#  https://github.com/GlobalNamesArchitecture/gni/issues/48
#

set -xe

mkdir -p input output

# get GloBI taxon graph 0.3.27
curl -L https://zenodo.org/record/4118439/files/taxonMap.tsv.gz > input/taxonMap.tsv.gz
curl -L https://zenodo.org/record/4118439/files/taxonCache.tsv.gz > input/taxonCache.tsv.gz

# get nomer v0.1.19 
curl -L "https://github.com/globalbioticinteractions/nomer/releases/download/0.1.19/nomer.jar" > input/nomer.jar

cat input/taxonMap.tsv.gz \
 | gunzip\
 | grep "NCBI:"\
 | tail -n+2\
 | sort\
 | uniq\
 | java -jar input/nomer.jar append ncbi-taxon-id\
 | gzip\
 > output/ncbi-matches.tsv.gz

cat input/taxonMap.tsv.gz \
 | gunzip\
 | grep "NCBI:"\
 | tail -n+2\
 | sort\
 | uniq\
 | java -jar input/nomer.jar append globi-globalnames\
 | gzip\
 >> output/ncbi-matches.tsv.gz


zcat output/ncbi-matches.tsv.gz\
| grep -v NONE\
| cut -f1,2,6,7\
| gzip\
> output/taxonMapNCBI.tsv.gz

zcat output/ncbi-matches.tsv.gz\
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

cat input/taxonMapNoNCBI.tsv.gz output/taxonMapNCBI.tsv.gz\
 | gunzip\
 | sort\
 | uniq\
 | gzip\
 >> output/taxonMap1.tsv.gz

diff <(cat input/taxonCache.tsv.gz | gunzip) <(cat output/taxonCache1.tsv.gz| gunzip) | gzip > output/taxonCache.tsv.patch.gz
diff <(cat input/taxonMap.tsv.gz | gunzip) <(cat output/taxonMap1.tsv.gz| gunzip) | gzip > output/taxonMap.tsv.patch.gz

zcat input/taxonCache.tsv.gz > output/taxonCacheToBePatched.tsv
zcat output/taxonCache.tsv.patch.gz | patch -b output/taxonCacheToBePatched.tsv
cat output/taxonCacheToBePatched.tsv | gzip > output/taxonCachePatched.tsv.gz

zcat input/taxonMap.tsv.gz > output/taxonMapToBePatched.tsv
zcat output/taxonMap.tsv.patch.gz | patch -b output/taxonMapToBePatched.tsv
cat output/taxonMapToBePatched.tsv | gzip > output/taxonMapPatched.tsv.gz
