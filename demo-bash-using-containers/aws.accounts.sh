########################################## COLLECTION CONFIG ############################################
outputpath="./TEMP"
table="aws_account"
columns="account_id,arn,organization_arn,organization_id,organization_master_account_arn,organization_master_account_email,organization_master_account_id,partition,region,title"
query="select $columns from $table"
output='json'
filename="$table.$output"
########################################## COLLECTION CONFIG ############################################

mkdir -p $HOME/sp/config
mkdir -p $HOME/sp/logs

alias sp="docker run \
  -it \
  --rm \
  --name steampipe \
  --mount type=bind,source=$HOME/sp/config,target=/home/steampipe/.steampipe/config  \
  --mount type=bind,source=$HOME/sp/logs,target=/home/steampipe/.steampipe/logs   \
  --mount type=bind,source=$HOME/.aws,target=/home/steampipe/.aws \
  --mount type=volume,source=steampipe_data,target=/home/steampipe/.steampipe/db/12.1.0/data \
  --mount type=volume,source=steampipe_internal,target=/home/steampipe/.steampipe/internal \
  --mount type=volume,source=steampipe_plugins,target=/home/steampipe/.steampipe/plugins   \
  turbot/steampipe"

mkdir -p $outputpath

# ensure the alias exists in your shell scope
sp query "$query" --output $output > "$outputpath/$filename"

# remove the [ and ] so we get 1 valid json per output row
# this way each result row will parse correctly in sumo provided we have a mult line regex ^ \{
cat "$outputpath/$filename" |  sed '/^\[/d'| sed '/^\]/d' | sed 's/^ \},/ }/g' > "$outputpath/post.$filename"

curl -X POST -H "X-Sumo-Category:steampipe/$table" -H "X-Sumo-Host:`hostname`" -H "X-Sumo-Name:$filename" -T "$outputpath/post.$filename" $SUMO_STEAMPIPE_URL