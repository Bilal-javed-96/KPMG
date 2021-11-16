#Created By Bilal Javed
#Displays Info About running instances 
#Limitations : Only Applicable If single Instance is in running state
#Future Implementations : Can be customize to get info about any single instance and its 
#specific parameter.
import boto3
import json
from pprint import pprint
def get_running_instances():
    ec2_client = boto3.client("ec2", region_name="us-east-1")
    reservations = ec2_client.describe_instances(Filters=[
        {
            "Name": "instance-state-name",
            "Values": ["running"],
        }
    ]).get("Reservations")

    select_index = ['SubnetId','VpcId','PrivateDnsName','PrivateIpAddress','InstanceType','InstanceId',
            'ImageId']
    pprint(reservations)
    ind = 0
    print("Select Number to get Specific Metadata of Instance")
    for i in select_index:
        print(str(ind) + " : " + i )
        ind+=1
    ind = int(input("Enter Number from above list : "))
    if ind <= 6 :
        for reservation in reservations:
            for instance in reservation["Instances"]:
                instance_info = instance[select_index[ind]]
                print("Following is the requested information : " + instance_info)
    else:
        print("Entered Selection is invalid !!!!")    

get_running_instances()
