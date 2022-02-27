# Event format for posting to sumologic for inventory events

This doc describes the suggested event format to post to SumoLogic to integrate with app content built in this repository. It's a reference for building a solution to post Steampipe data to sumo.

## Event Format
The inventory apps in Sumo use JSON formatted events. Since each inventory table has it's own columns (determined by your select query output), JSON provides an easy to parse and flexible format.

## Example Event
This is an example event to ingest into sumologic fromm the AWS ec2 instance table.
```
{
    "account_id": "165111111784",
    "arn": "arn:aws:ec2:us-east-2:165111111784:instance/i-05a3ae111111f445",
    "disable_api_termination": false,
    "iam_instance_profile_arn": "arn:aws:iam::165111111784:instance-profile/AmazonSSMRoleForInstancesQuickSetup",
    "image_id": "ami-08c213ebdf7b857c2",
    "instance_id": "i-05a3ae111111f445",
    "instance_state": "stopped",
    "instance_status": {
        "AvailabilityZone": "us-east-2b",
        "Events": null,
        "InstanceId": "i-05a3ae111111f445",
        "InstanceState": {
            "Code": 80,
            "Name": "stopped"
        },
        "InstanceStatus": {
            "Details": null,
            "Status": "not-applicable"
        },
        "OutpostArn": null,
        "SystemStatus": {
            "Details": null,
            "Status": "not-applicable"
        }
    },
    "instance_type": "t2.medium",
    "key_name": "march3-2021",
    "launch_time": "2022-01-26T03:10:43Z",
    "monitoring_state": "disabled",
    "partition": "aws",
    "placement_availability_zone": "us-east-2b",
    "private_dns_name": "ip-172-31-31-182.us-east-2.compute.internal",
    "public_ip_address": null,
    "region": "us-east-2",
    "security_groups": [
        {
            "GroupId": "sg-082d76963decb51fd",
            "GroupName": "windows-ec2-demo"
        }
    ],
    "subnet_id": "subnet-0044a17d",
    "tags": {
        "owner": "rick",
        "project": "sumo-agent-test"
    },
    "title": "i-05a3ae111111f445",
    "vpc_id": "vpc-fb45c290"
}
```

## Metadata
Set a _sourcecategory that denotes this as steampipe inventory data.
include the table name in the sourcecategory. for example 

```
steampipe/aws_ec2_instance
```
Its recommended to set sourcename to the ingested file or to clearly identify the table name such as aws_ec2_instance.json.

## Timestamp format
Setup your sumo source to 'use receipt time' since the events do not have a timestamp in them.
- untick  Extract timestamp information from log file entries so logs are assigned receipttime as messagetime

If you are wanting to add your own timestamp add a timestamp key to the JSON payload compliant with sumologic timestamp parsing, and use auto timestamp parsing on the source.

## Multiline parsing
If your solution posts single JSON events to sumo they should be correctly auto parsed as events. You may need to:
- post to sumo using single line compressed JSON format.
- set a boundary regex ```^ \{``` to ensure each json row in your data is a separate event on the ingestion source.

## Event Format Should Be JSON
Setup your integration to post **each inventory item** to sumo as a JSON as it's own JSON event. 
**Do not post arrays/lists of JSON objects as single events**  as this will fail to parse correctly when you exceed the 65k max event size limit for SumoLogic single events.