#!/bin/bash

# strict mode so script quits immediately upon failure
set -eo pipefail

# Getting environment variables from .env
source ./loadenv.sh
# Check if required variables are defined
source ./varcheck.sh

dataDir=$DPDASH_DATA_DIR
containerDataDir=$DPDASH_STATE_DIR

if [ "$(ls -A $containerDataDir)" ]; then
    echo "$containerDataDir needs to both exist and be empty"
    exit 1
fi

if [ ! -z ${DPDASH_SERVICE_HOST+x} ]
then 
    serviceHost=$DPDASH_SERVICE_HOST
else
    serviceHost=`hostname -f | xargs`
fi

## Transport script files
mkdir -p ${containerDataDir}/scripts
find ./ -type f -maxdepth 1 ! -name $DPDASH_IMG -exec cp -t ${containerDataDir}/scripts/ {} +

## Get current working directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

## Generate SSL certificates
echo '***************Generating SSL Certificates***************'
mkdir -p ${containerDataDir}/ssl/ca ${containerDataDir}/ssl/server ${containerDataDir}/ssl/client
mkdir -p ${containerDataDir}/ssl/ca/certs ${containerDataDir}/ssl/ca/private
chmod 700 ${containerDataDir}/ssl/ca/private
cp ./openssl.cnf ${containerDataDir}/ssl/ca/openssl.cnf
cd ${containerDataDir}/ssl/ca
echo 01 > serial
touch index.txt

echo 'Generating CAs'
cd ${containerDataDir}/ssl/ca
openssl req -x509 -config openssl.cnf -newkey rsa:4096 -days 365 \
    -out cacert.pem -outform PEM -subj /CN=DPdashCA/ -nodes
openssl x509 -in cacert.pem -out cacert.cer -outform DER

echo 'Generating server keys'
cd ../server
openssl genrsa -out key.pem 4096
openssl req -new -key key.pem -out req.pem -outform PEM \
    -subj "/CN=${serviceHost}/O=server/" -nodes

cd ../ca
openssl ca -config openssl.cnf -in ../server/req.pem -out \
    ../server/cert.pem -notext -batch -extensions server_ca_extensions

echo 'Generating client keys'
cd ../client
openssl genrsa -out key.pem 4096
openssl req -new -key key.pem -out req.pem -outform PEM \
    -subj "/CN=${serviceHost}/O=client/" -nodes

cd ../ca
openssl ca -config openssl.cnf -in ../client/req.pem -out \
    ../client/cert.pem -notext -batch -extensions client_ca_extensions

echo 'Generating Mongodb keys'
cat ${containerDataDir}/ssl/server/key.pem ${containerDataDir}/ssl/server/cert.pem > ${containerDataDir}/ssl/mongo_server.pem
cat ${containerDataDir}/ssl/client/key.pem ${containerDataDir}/ssl/client/cert.pem > ${containerDataDir}/ssl/mongo_client.pem

## Generate Configurations
echo '***************Generating Configs***************'
cd ${containerDataDir}/scripts
mkdir -p ${containerDataDir}/dpdash/configs
export mongopw=`openssl rand -base64 32 | tr -d "+=/"`
export rabbitpw=`openssl rand -base64 32| tr -d "+=/"`
export dpdashsecret=`openssl rand -base64 32`
export appsecret=`openssl rand -base64 32 | tr -d "+=/"`
python ./configure.py --data-dir ${dataDir} --config-dir ${containerDataDir}/dpdash/configs --mongo-pw $mongopw --rabbit-pw $rabbitpw --ssl-ca /data/ssl/ca/cacert.pem --ssl-server-cert /data/ssl/server/cert.pem --ssl-server-key /data/ssl/server/key.pem  --ssl-client-cert /data/ssl/client/cert.pem --ssl-client-key /data/ssl/client/key.pem --mongo-server-cert /data/ssl/mongo_server.pem --mongo-path /data/dpdash/mongodb --celery-path /data/dpdash/celery/ --dpdash-secret $dpdashsecret --mongo-host ${serviceHost} --rabbit-host ${serviceHost} --dpdash-path /data/dpdash/ --app-secret $appsecret

## Initializing supervisord Space
echo '***************Initializing supervisord logdir***************'
mkdir -p ${containerDataDir}/dpdash/supervisord/logs

## Initializing MongoDB Space
echo '***************Initializing MONGOB Space***************'
mkdir -p ${containerDataDir}/dpdash/mongodb/logs && mkdir ${containerDataDir}/dpdash/mongodb/dbs

## Initializing Rabbitmq Space
echo '***************Initializing RABBITMQ Space***************'
mkdir -p ${containerDataDir}/dpdash/rabbitmq && mkdir ${containerDataDir}/dpdash/celery

## Initializing DPdash Upload Space
echo '***************Initializing DPdash Space*****************'
mkdir -p ${containerDataDir}/dpdash/uploads && mkdir -p ${containerDataDir}/dpdash/configs/dashboard
cd ${DIR}
cp -R ./configs/* ${containerDataDir}/dpdash/configs/dashboard/
cp supervisord.conf ${containerDataDir}/dpdash/configs/

## Set-up the container
echo '***************Setting up DPdash*****************'
singularity exec -B ${containerDataDir}:/data $DPDASH_IMG /data/scripts/setup.sh $mongopw $rabbitpw $appsecret
