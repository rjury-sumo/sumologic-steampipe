# sumologic-steampipe
A container to demo using steampipe.io to send config data to sumologic.


# setup steampipe container
see: https://steampipe.io/docs/develop/containers

## alias
use an alias example such as alias.example.2.sh so we can execute the container and persist key info across sessions.

```
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
```

You can now launch steampipe in interactive or other modes using the alias for example:
```
sp query "select * from aws_account" --output json
```

## Install reguired pluains as per the docker developer page above
For example:
```
sp plugin install steampipe aws
sp plugin list
etc
```

## connections
Setup any required connection files such as $HOME/sp/config/aws.spc
For multiple aws accounts and regions polling this article will be very useful.
https://aws.amazon.com/blogs/opensource/querying-aws-at-scale-across-apis-regions-and-accounts/

## Sumologic collector and source

Create a new hosted collector called 'steampipe'

## create a hosted source
Add a HTTPS logs source also called 'steampipe' (you could have multiple here up to you!)
- set a default category such as steampipe
- untick  Extract timestamp information from log file entries so logs are assigned receipttime as messagetime
- set a boundary regex ```^ \{``` to ensure each json row is a separate event
** warning - this config only works because of a tricky sed line in the sciprts we use combined with json output **

here is an example json for this source:
```
{
  "api.version":"v1",
  "source":{
    "name":"steampipe",
    "category":"steampipe",
    "automaticDateParsing":false,
    "multilineProcessingEnabled":true,
    "useAutolineMatching":false,
    "manualPrefixRegexp":"^ \\{",
    "forceTimeZone":false,
    "filters":[],
    "cutoffTimestamp":0,
    "encoding":"UTF-8",
    "fields":{
      
    },
    "messagePerRequest":false,
    "sourceType":"HTTP"
  }
}
```

note the https endpoint address.

## SUMO_STEAMPIPE_URL env var
Create an environment variable SUMO_STEAMPIPE_URL
This should have the endpoint address from the previous step.

## create collection files
using an example such as aws.accounts.sh  create a similar collection script for your collection.
There is some fluff in the file to set metadata in sumo and this tricky line with sed that breaks the json but in a way to ensure sumo sees each output row as a distinct json event:
```
cat "$outputpath/$filename" |  sed '/^\[/d'| sed '/^\]/d' | sed 's/^ \},/ }/g' > "$outputpath/post.$filename"
```

Basically this line:
- removes [ lines
- removes ] lines
- replaces lines with ``` },``` with ``` }```

# Executing a Collection
Create a .sh file using the example aws.accounts.sh
The key thing in here is to set correct metadata and the sed line removes some leading and trailing [] lines so it will parse as json in sumo with each row of output being a valid json event.

# Querying the logs
Since each query row is posted to sumo as a json formatted event parsing this data is easy and straightforward for example:
```
_sourcecategory=steampipe/aws_account
| json field=_raw "account_id"
| json field=_raw "organization_master_account_id"
| json field=_raw "organization_master_account_email"
| json field=_raw "region"
| json field=_raw "title"
| count by account_id,organization_master_account_id,organization_master_account_email,region,title | fields -_count
```

ec2 example:
```
_sourcecategory=steampipe/aws_ec2_instance
| json field=_raw "account_id"
| json field=_raw "region"
| json field=_raw "title"
| json field=_raw "arn"
| json field=_raw "image_id"
| json field=_raw "instance_id"
| json field=_raw "instance_type"
| json field=_raw "key_name"
| json field=_raw "monitoring_state"
| json field=_raw "placement_availability_zone"
| json field=_raw "tags"
| json field=_raw "vpc_id"
```