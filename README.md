# sumologic-steampipe
A container to demo using steampipe.io to:
- send inventory data to sumologic as per: https://steampipe.io/docs/using-steampipe/steampipe-query 
- run compliance checks such as https://steampipe.io/docs/using-steampipe/running-controls

In general the approach is:
- for inventory sql query export in json format and post a slight modified json paylod to sumologic https endpoint source
- for checks use --export in csv format to a file and post that to a checks sumologic https source.

Note you can do EITHER query or checks or both, you only need to follow instructions to configure either as pertinent to your use case.

# setup steampipe container
For this demo we use the standard container, for usage see:  https://steampipe.io/docs/develop/containers

## aliasing the container
Use an alias we can execute the container and persist key info across sessions. This is an example to alias the container for a steampipe query. 

Check alias is a little more complex.

This means we don't have to install steampipe locally. For a production deployment you might want to run a real instance say on linux.

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

## Install reguired pluains into the container environment
Install any required plugins into the environment. These will be mounted to the container using:
```
--mount type=volume,source=steampipe_plugins,target=/home/steampipe/.steampipe/plugins 
```

For example:
```
sp plugin install steampipe aws
sp plugin list
etc
```

## Installing compliance check or other mods
If you want to also use mods such as https://github.com/turbot/steampipe-mod-aws-compliance these need to be included in your container image. For this demo we will clone the repo then mount the directory for example:
```
git clone https://github.com/turbot/steampipe-mod-aws-compliance.git
```

Then for checks use a special alias and cwd for the container:
```
mkdir -p $HOME/sp/config
mkdir -p $HOME/sp/logs
pwd=`pwd`
mkdir -p $pwd/CHECKS

alias spcaws-compliance="docker run -w /home/steampipe/steampipe-mod-aws-compliance\
  -it \
  --rm \
  --name steampipe \
  --mount type=bind,source=$HOME/sp/config,target=/home/steampipe/.steampipe/config  \
  --mount type=bind,source=$HOME/sp/logs,target=/home/steampipe/.steampipe/logs   \
  --mount type=bind,source=$HOME/.aws,target=/home/steampipe/.aws \
  --mount type=bind,source=$pwd/steampipe-mod-aws-compliance,target=/home/steampipe/steampipe-mod-aws-compliance \
  --mount type=bind,source=$pwd/CHECKS,target=/home/CHECKS \
  --mount type=volume,source=steampipe_data,target=/home/steampipe/.steampipe/db/12.1.0/data \
  --mount type=volume,source=steampipe_internal,target=/home/steampipe/.steampipe/internal \
  --mount type=volume,source=steampipe_plugins,target=/home/steampipe/.steampipe/plugins   \
  turbot/steampipe check all --tag cis_level=1 --tag cis=true"

spcaws-compliance --export=/home/CHECKS/aws-compliance-cis.csv 
```

## Setup required connections
For a simple demo the container you just need valid creditials in your execution environment for example if the aws cli is configured with default creditials.

For multi account/region or other custom connections you might need a more complex setup using connection files such as $HOME/sp/config/aws.spc
For multiple aws accounts and regions polling this article will be very useful.
https://aws.amazon.com/blogs/opensource/querying-aws-at-scale-across-apis-regions-and-accounts/

# Setup A Sumologic collector and source(s)
Create a new hosted collector called 'steampipe'

## create a hosted source for steampipe query json output
We will post json data from steampipe queries to this https endpoint.

Add a HTTPS logs source also called 'steampipe' to your collector 
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

note the https endpoint address for use later as the SUMO_STEAMPIPE_URL.

## Create hosted sources for any checks you want to collect
Since checks will be posted as single line csv files we need a slightly different format.
A good practice would be to create a different source for each compliance mod you are using as they will create different csv column formats.

for example for our AWS cis check above we will create a hosted source like this:
- name steampipe check aws-cis
- set a default category such as steampipe/check/aws
- untick Extract timestamp information from log file entries so logs are assigned receipttime as messagetime
- untick Detect messages spanning multiple lines

here is an example json for this new source:
```
{
  "api.version":"v1",
  "source":{
    "name":"steampipe check aws-cis",
    "category":"steampipe/check/aws",
    "automaticDateParsing":false,
    "multilineProcessingEnabled":false,
    "useAutolineMatching":false,
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
# setup envrionment variables
Note the example scripts use env vars for the sumo source endpoints.

## SUMO_STEAMPIPE_URL env var for query collection
Create an environment variable SUMO_STEAMPIPE_URL
This should have the endpoint address from the previous step.

## SUMO_STEAMPIPE_CHECK_URL env var for check collection
Since we need a single line source for checks we need another endpoint url. 
Create an environment variable SUMO_STEAMPIPE_CHECK_URL
This should have the endpoint address from the previous step.

# Using steampipe queries in SumoLogic
Send inventory data to sumologic as per: https://steampipe.io/docs/using-steampipe/steampipe-query 
We will post JSON formatted output.

## create collection files
Using an example such as aws.accounts.sh create a similar collection script for each table you want to collect. You will need to execute these on a schedule say daily via cron or some such.

There is some fluff in the file to set metadata in sumo and this tricky line with sed that breaks the json but in a way to ensure sumo sees each output row as a distinct json event:
```
cat "$outputpath/$filename" |  sed '/^\[/d'| sed '/^\]/d' | sed 's/^ \},/ }/g' > "$outputpath/post.$filename"
```

Basically this line:
- removes [ lines
- removes ] lines
- replaces lines with ``` },``` with ``` }```

the post should be to the SUMO_STEAMPIPE_URL variable you have set in the environment previously.

## Querying the steampipe json query logs
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
| json field=_raw "private_dns_name"

| count by account_id,title,arn,region,image_id,instance_id,instance_type,key_name,monitoring_state,placement_availability_zone,private_dns_name,tags,vpc_id
| sort instance_id asc

```

## Dashboarding query logs
You can find a simple example dashboard in the file dashboard.query.demo.json
![query dash](steampipe-aws-query-dashboard.png?raw=true "query dash")


# Using Compliance Check Data In SumoLogic
Run compliance checks such as https://steampipe.io/docs/using-steampipe/running-controls
For checks use --export in csv format to a file and post that to a checks sumologic https source.
To use checks make sure to follow the steps above to install the mod and bind the mod directory to the container.

## Create check collection file
This is an example script to run aws CIS Benchmark level 1 checks from the aws compliance mod.
The output will be a csv file in the local ./CHECKS directory
This will be posted to the single line friendly SUMO_STEAMPIPE_CHECK_URL HTTPS source we created previously.

```
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
```

## Querying the csv formatted checks data in sumologic
Each collection csv might have a unique column format so we use parse csv operator in sumo noting the column names for each check type.

Example query showing CIS checks in alsrm status
```
_sourcecategory = "steampipe/check/aws-compliance-cis"
| csv _raw extract  group_id,title,description,control_id,control_title,control_description,reason,resource,status,account_id,region,cis,cis_item_id,cis_level,cis_section_id,cis_type,cis_version,plugin,service
// ditch line 1
| where status !="status"
| where status in ("alarm")
| count by title,status,control_id,control_title,control_description,account_id,region,resource,reason,group_id
```

# Dashboarding Check Data
We can build dashboards easily from the compliance check data. See this example: dashboard.aws-cis-check.demo.json
![cis dash](steampipe-aws-cis-dash.png?raw=true "cis dash")
