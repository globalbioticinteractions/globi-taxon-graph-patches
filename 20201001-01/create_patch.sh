#!/bin/bash
#
#

set -xe

mkdir -p input output

# get a Plazi Treatments RDF Archive
curl "https://zenodo.org/record/4062537/files/plazi-treatments-rdf.zip" > input/plazi-treatments-rdf.zip

# get GloBI taxon graph 0.3.25
curl https://zenodo.org/record/3378125/files/taxonMap.tsv.gz > input/taxonMap.tsv.gz
curl https://zenodo.org/record/3378125/files/taxonCache.tsv.gz > input/taxonCache.tsv.gz

# get nomer v0.1.17 
curl "https://github.com/globalbioticinteractions/nomer/releases/download/0.1.17/nomer.jar" > input/nomer.jar

# link names to Plazi
echo 'nomer.schema.input=[{"column":2,"type":"externalId"},{"column": 3,"type":"name"}]' > input/nomer.properties
echo "nomer.plazi.treatments.archive=file://$PWD/input/plazi-treatments-rdf.zip" >> input/nomer.properties

cat taxonMap.tsv.gz \
 | gunzip\
 | awk -F '\t' '{ print $1 "\t" $2 "\t\t" $4 }'\
 | tail -n+2\
 | sort\
 | uniq\
 | java -jar input/nomer.jar append -p input/nomer.properties plazi\
 | gzip\
 > plazi-matches.tsv.gz

zcat plazi-matches.tsv.gz\
| grep -v NONE\
| cut -f1,2,6,7\
| gzip
> output/taxonMapPlazi.tsv.gz

zcat plazi-matches.tsv.gz\
| grep -v NONE\
| cut -f6-\
| gzip
> output/taxonCachePlazi.tsv.gz

cat input/taxonCache.tsv.gz\
 | head -n1
 | gzip
 > output/taxonCache1.tsv.gz

cat input/taxonCache.tsv.gz output/taxonCachePlazi.tsv.gz\
 | gunzip\
 | tail -n+2\
 | sort\
 | uniq\
 | gzip\
 >> output/taxonCache1.tsv.gz

cat input/taxonMap.tsv.gz\
 | head -n1
 | gzip
 > output/taxonMap1.tsv.gz

cat input/taxonMap.tsv.gz output/taxonMapPlazi.tsv.gz\
 | gunzip\
 | tail -n+2\
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
