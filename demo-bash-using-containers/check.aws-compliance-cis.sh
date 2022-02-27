########################################## COLLECTION CONFIG ############################################
pwd=`pwd`
outputpath="$pwd/CHECKS"
check="aws-compliance-cis"
tags="--tag cis_level=1 --tag cis=true"
output='csv'
filename="$check.$output"
########################################## COLLECTION CONFIG ############################################

mkdir -p $HOME/sp/config
mkdir -p $HOME/sp/logs
mkdir -p $outputpath

alias spcaws-compliance="docker run -w /home/steampipe/steampipe-mod-aws-compliance\
  -it \
  --rm \
  --name steampipe \
  --mount type=bind,source=$HOME/sp/config,target=/home/steampipe/.steampipe/config  \
  --mount type=bind,source=$HOME/sp/logs,target=/home/steampipe/.steampipe/logs   \
  --mount type=bind,source=$HOME/.aws,target=/home/steampipe/.aws \
  --mount type=bind,source=$pwd/steampipe-mod-aws-compliance,target=/home/steampipe/steampipe-mod-aws-compliance \
  --mount type=bind,source=$outputpath,target=/home/CHECKS \
  --mount type=volume,source=steampipe_data,target=/home/steampipe/.steampipe/db/12.1.0/data \
  --mount type=volume,source=steampipe_internal,target=/home/steampipe/.steampipe/internal \
  --mount type=volume,source=steampipe_plugins,target=/home/steampipe/.steampipe/plugins   \
  turbot/steampipe check all "

# note the export path inside the container that we mapped with bind
spcaws-compliance $tags --export="home/CHECKS/$filename"

curl -X POST -H "X-Sumo-Category:steampipe/check/$check" -H "X-Sumo-Host:`hostname`" -H "X-Sumo-Name:$filename" -T "$outputpath/$filename" $SUMO_STEAMPIPE_CHECK_URL

