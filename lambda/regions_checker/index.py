import os
import boto3


def lambda_handler(event, context):

    exclude_regions = os.environ.get('ExcludeRegions', '').split(',')
    response_data = {}
    try:
        client = boto3.client('ec2')
        response = client.describe_regions(AllRegions=False)
        enabled_regions = [region['RegionName'] for region in response['Regions'] if
                           (not region['RegionName'] in exclude_regions and not region['RegionName'].startswith(
                               "cn-") and not region['RegionName'].startswith("us-gov"))]
        print("enabled_regions", enabled_regions)
        response_data["EnabledRegions"] = enabled_regions
        response_data["body"] = "ok"
        response_data["status_code"] = 200
        return response_data
    except Exception as e:
        response_data["status_code"] = 500
        response_data["body"] = str(e)
        return response_data
