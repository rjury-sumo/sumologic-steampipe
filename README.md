# sumologic-steampipe
This is a project to demonstrate how to integrate steampipe inventory or compliance data into Sumologic since Sumo offers a powerful and flexible query engine, as well as dashboarding and alerting capabilities.

Use these integrations and apps to:
- send inventory data to sumologic as per: https://steampipe.io/docs/using-steampipe/steampipe-query 
- run compliance checks such as https://steampipe.io/docs/using-steampipe/running-controls and post these to SumoLogic for compliance reporting use cases.

Example use cases might be:
- generating daily inventory reports in SumoLogic for  cloud or other infrastructure
- Building automated compliance checks in SumoLogic using steampipe compliance mods.

# Bash demo container
In /Users/rjury/Documents/sumo2022/sumologic-steampipe/demo-bash-using-containers you can find a very quick to start example of how to use a docker container image and a linux/macos shell to run and post inventory or compliance data to sumo.

# Data Integration Design
Steampipe produces two useful outputs for integration: inventory and compliance checks.

In general the approach is:
- for inventory sql query export in json format and post a slight modified json paylod to sumologic https endpoint source
- for checks use --export in csv format to a file and post that to a checks sumologic https source.

You can find data format design docs if you wish to build your own integration here, that will ensure your events work with the provided app content.
- docs/eventformat-compliance.md
- docs/eventformat-inventory.md

# Inventory Events
These come from steampipe sql queries and post your selected table columns to Sumologic as a JSON event.

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

# Integrating Compliance Check Data In SumoLogic
Run compliance checks such as https://steampipe.io/docs/using-steampipe/running-controls
For checks use --export in csv format to a file and post that to a checks sumologic https source.
To use checks make sure to follow the steps above to install the mod and bind the mod directory to the container.

## Querying the csv formatted check events in SumoLogic
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
