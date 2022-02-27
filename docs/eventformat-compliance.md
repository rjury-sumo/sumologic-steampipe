# Event format for posting to sumologic for compliance events

This doc describes the suggested event format to post to SumoLogic to integrate with app content built in this repository. It's a reference for building a solution to post Steampipe data to sumo.

## Event Format
The compliance mods for Steampipe can export a number of formats, however csv export output is the easiest to integrate into Sumo.

This ensures we can easily capture each compliance/audit finding as a separate event.
Actual csv columns will vary between compliance checks so you might need to use different sumo sources/sourcecategories for each check run

## Example Event
This is an example event to ingest into sumologic fromm the AWS cis compliance check.

example command code:
```
steampipe check all --tag cis_level=1 --tag cis=true --export=aws_cis_level1.csv
```

header line
```
group_id,title,description,control_id,control_title,control_description,reason,resource,status,account_id,region,cis,cis_item_id,cis_level,cis_section_id,cis_type,cis_version,plugin,service
```

each check row will be ouptut similar to this:
```
aws_compliance.benchmark.cis_v140_5,5 Networking,,control.cis_v140_5_1,5.1 Ensure no Network ACLs allow ingress from 0.0.0.0/0 to remote server administration ports,"The Network Access Control List (NACL) function provide stateless filtering of ingress and egress network traffic to AWS resources. It is recommended that no NACL allows unrestricted ingress access to remote server administration ports, such as SSH to port 22 and RDP to port 3389.",acl-e128a787 contains 1 rule(s) allowing ingress to port 22 or 3389 from 0.0.0.0/0 or ::/0.,arn:aws:ec2:ap-southeast-2:165111111784:network-acl/acl-e128a787,alarm,165111111784,ap-southeast-2,true,5.1,1,5,automated,v1.4.0,aws,vpc
```

## Metadata
Set a _sourcecategory that denotes this as steampipe compliance data.
include the check name in the sourcecategory. for example

```
steampipe/check/aws-compliance-cis
```

It's also recommended to set the _sourcename to the ingested file name or to indicate the specific compliance check such as aws-compliance-cis.csv

## Timestamp format
Setup your sumo source to 'use receipt time' since the events do not have a timestamp in them.
- untick  Extract timestamp information from log file entries so logs are assigned receipttime as messagetime


## Multiline parsing
Use single line parsing mode on ingest sources.

## Event Format Should Be CSV
This ensures we can easily capture each compliance/audit finding as a separate event.
Actual csv columns will vary between compliance checks so you might need to use different sumo sources/sourcecategories for each check run