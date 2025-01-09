import os
import boto3
import hashlib
import base64


def calculate_sha256(file_path):
    """
    Calculate the SHA256 hash of a file.

    :param file_path: Path to the file.
    :return: The SHA256 hash as a hexadecimal string.
    """
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        # Read the file in chunks to avoid memory issues with large files
        for chunk in iter(lambda: f.read(4096), b""):
            sha256_hash.update(chunk)
    return sha256_hash.digest()


def lambda_handler(event, context):
    nasg_lambda_package = os.environ.get("NASG_LAMBDA_BUCKET")
    nasg_lambda_package_key = os.environ.get("NASG_LAMBDA_BUCKET_KEY")
    nasg_lambda_arn = os.environ.get("NASG_LAMBDA_ARN")
    write_dir = "/tmp/tmp.zip"
    response_data = {}

    if nasg_lambda_package is None or nasg_lambda_package_key is None or nasg_lambda_arn is None:
        response_data["status_code"] = 500
        response_data["body"] = "Empty required env var."
        print("Empty required env var.")
        return response_data

    try:
        s3_client = boto3.client('s3')
        lambda_client = boto3.client('lambda')

        nasg_deployed_lambda = lambda_client.get_function(FunctionName=nasg_lambda_arn)

        with open(write_dir, 'wb') as nasg_external_lambda:
            s3_client.download_fileobj(nasg_lambda_package, nasg_lambda_package_key, nasg_external_lambda)

        sha256 = calculate_sha256(write_dir)
        sha256_b64 = base64.b64encode(sha256).decode('utf-8')

        if nasg_deployed_lambda["Configuration"]["CodeSha256"] != sha256_b64:
            print("Lambda function outdated, updating...")
            lambda_client.update_function_code(
                FunctionName=nasg_lambda_arn,
                S3Bucket=nasg_lambda_package,
                S3Key=nasg_lambda_package_key
            )
            response_data["status_code"] = 200
            response_data["body"] = "Ok, Updated Lambda"
            return response_data
        else:
            print("Lambda up to date")
            response_data["status_code"] = 200
            response_data["body"] = "Ok. Lambda up to date"
            return response_data

    except Exception as e:
        print(str(e))
        response_data["status_code"] = 500
        response_data["body"] = str(e)
        return response_data
