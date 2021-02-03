#!/bin/bash

# strict mode so script quits immediately upon failure
set -eo pipefail

dataDir=$1 ## Directory that contains GENERAL and PROTECTED folders
containerDataDir=$2 ## Directory that contains data generated by dpdash

[ -z $DPDASH_IMG ] && DPDASH_IMG=dpdash.sif
if [ ! -f $DPDASH_IMG ] && [ ! -d $DPDASH_IMG ]
then
	echo $DPDASH_IMG cannot be found. Make sure it exists or define DPDASH_IMG properly.
	exit 1
fi

singularity exec -B ${containerDataDir}:/data -B ${dataDir}:${dataDir} $DPDASH_IMG /data/scripts/push.sh
