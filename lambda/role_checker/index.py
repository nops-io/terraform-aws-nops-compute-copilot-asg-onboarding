import boto3
import os
import json


def extract_list_or_make_it_list(d: dict, key: str):
    if isinstance(d.get(key), list):
        return d.get(key)
    else:
        return [d.get(key)]


def lambda_handler(event, context):
    admin_role_info = {
        "role_exists": False,
        "assume_policy_correct": False,
        "policy_exists": False,
        "policy_correct": False,
    }
    stack_set_execution_role_info = {
        "role_exists": False,
        "assume_policy_correct": False,
        "policy_exists": False,
        "policy_correct": False,
    }
    account_number = os.environ["account_number"]
    iam_connection = boto3.client("iam")

    try:
        admin_role = iam_connection.get_role(
            RoleName="AWSCloudFormationStackSetAdministrationRole"
        ).get("Role")
        if admin_role:
            admin_role_info["role_exists"] = True
        assume_role_document = admin_role.get("AssumeRolePolicyDocument", {})
        for statement in assume_role_document.get("Statement", []):
            if (
                    "Allow" in extract_list_or_make_it_list(statement, "Effect")
                    and "sts:AssumeRole"
                    in extract_list_or_make_it_list(statement, "Action")
                    and "cloudformation.amazonaws.com" in extract_list_or_make_it_list(statement.get("Principal", {}),
                                                                                       "Service")
            ):
                admin_role_info["assume_policy_correct"] = True

        policy = iam_connection.get_role_policy(
            RoleName="AWSCloudFormationStackSetAdministrationRole",
            PolicyName="AssumeRole-AWSCloudFormationStackSetExecutionRole",
        ).get("PolicyDocument", {})
        if policy:
            admin_role_info["policy_exists"] = True

        for statement in policy.get("Statement", []):
            if (
                    "Allow" in extract_list_or_make_it_list(statement, "Effect")
                    and "sts:AssumeRole"
                    in extract_list_or_make_it_list(statement, "Action")
                    and "arn:*:iam::*:role/AWSCloudFormationStackSetExecutionRole"
                    in extract_list_or_make_it_list(statement, "Resource")
            ):
                admin_role_info["policy_correct"] = True
    except Exception as e:
        if "NoSuchEntity" in str(e):
            pass
        else:
            return {"status_code": 500, "body": str(e)}

    try:
        iam_connection = boto3.client("iam")
        execution_role = iam_connection.get_role(
            RoleName="AWSCloudFormationStackSetExecutionRole"
        ).get("Role")
        if execution_role:
            stack_set_execution_role_info["role_exists"] = True
        assume_role_document = execution_role.get("AssumeRolePolicyDocument", {})
        for statement in assume_role_document.get("Statement", []):
            principals = extract_list_or_make_it_list(statement.get("Principal", {}), "AWS")
            if (
                    "Allow" in extract_list_or_make_it_list(statement, "Effect")
                    and "sts:AssumeRole"
                    in extract_list_or_make_it_list(statement, "Action")
                    and any([k in principals for k in [f"arn:aws:iam::{account_number}:root",
                                                       f"arn:aws:iam::{account_number}:role/AWSCloudFormationStackSetAdministrationRole"]])
            ):
                stack_set_execution_role_info["assume_policy_correct"] = True

        policies = iam_connection.list_attached_role_policies(
            RoleName="AWSCloudFormationStackSetExecutionRole"
        ).get("AttachedPolicies", [])
        if {
            "PolicyName": "AdministratorAccess",
            "PolicyArn": "arn:aws:iam::aws:policy/AdministratorAccess",
        } in policies:
            stack_set_execution_role_info["policy_exists"] = True
            stack_set_execution_role_info["policy_correct"] = True
    except Exception as e:
        if "NoSuchEntity" in str(e):
            pass
        else:
            return {"status_code": 500, "body": str(e)}

    if (
            admin_role_info["role_exists"]
            and admin_role_info["assume_policy_correct"]
            and admin_role_info["policy_exists"]
            and admin_role_info["policy_correct"]
            and stack_set_execution_role_info["role_exists"]
            and stack_set_execution_role_info["assume_policy_correct"]
            and stack_set_execution_role_info["policy_exists"]
            and admin_role_info["policy_correct"]
    ):
        return {"status_code": 200, "body": "ok"}
    elif (
            admin_role_info["role_exists"] and not admin_role_info["assume_policy_correct"]
    ):
        return {"status_code": 200, "body": "ok"}
    elif (
            stack_set_execution_role_info["role_exists"]
            and not stack_set_execution_role_info["assume_policy_correct"]
    ):
        return {"status_code": 500, "body": str(e)}

    if not admin_role_info["role_exists"]:
        iam_connection.create_role(
            RoleName="AWSCloudFormationStackSetAdministrationRole",
            AssumeRolePolicyDocument=json.dumps(
                {
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "Principal": {"Service": "cloudformation.amazonaws.com"},
                            "Action": "sts:AssumeRole",
                        }
                    ],
                }
            ),
        )

    if not admin_role_info["policy_exists"]:
        iam_connection.put_role_policy(
            RoleName="AWSCloudFormationStackSetAdministrationRole",
            PolicyName="AssumeRole-AWSCloudFormationStackSetExecutionRole",
            PolicyDocument=json.dumps(
                {
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Action": ["sts:AssumeRole"],
                            "Resource": [
                                "arn:*:iam::*:role/AWSCloudFormationStackSetExecutionRole"
                            ],
                            "Effect": "Allow",
                        }
                    ],
                }
            ),
        )

    if not stack_set_execution_role_info["role_exists"]:
        iam_connection.create_role(
            RoleName="AWSCloudFormationStackSetExecutionRole",
            AssumeRolePolicyDocument=json.dumps(
                {
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "Principal": {"AWS": f"arn:aws:iam::{account_number}:root"},
                            "Action": "sts:AssumeRole",
                        }
                    ],
                }
            ),
        )

    if not stack_set_execution_role_info["policy_exists"]:
        iam_connection.attach_role_policy(
            RoleName="AWSCloudFormationStackSetExecutionRole",
            PolicyArn="arn:aws:iam::aws:policy/AdministratorAccess",
        )

    return {"status_code": 200, "body": "ok"}
