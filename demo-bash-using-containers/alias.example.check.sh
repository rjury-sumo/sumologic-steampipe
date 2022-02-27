mkdir -p $HOME/sp/config
mkdir -p $HOME/sp/logs
pwd=`pwd`

alias spcaws-compliance="docker run -w /home/steampipe/steampipe-mod-aws-compliance\
  -it \
  --rm \
  --name steampipe \
  --mount type=bind,source=$HOME/sp/config,target=/home/steampipe/.steampipe/config  \
  --mount type=bind,source=$HOME/sp/logs,target=/home/steampipe/.steampipe/logs   \
  --mount type=bind,source=$HOME/.aws,target=/home/steampipe/.aws \
  --mount type=bind,source=$pwd/steampipe-mod-aws-compliance,target=/home/steampipe/steampipe-mod-aws-compliance \
  --mount type=volume,source=steampipe_data,target=/home/steampipe/.steampipe/db/12.1.0/data \
  --mount type=volume,source=steampipe_internal,target=/home/steampipe/.steampipe/internal \
  --mount type=volume,source=steampipe_plugins,target=/home/steampipe/.steampipe/plugins   \
  turbot/steampipe check all --tag cis_level=1 --tag cis=true --output=csv"


