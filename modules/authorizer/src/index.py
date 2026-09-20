"""REQUEST Lambda authorizer for the private REST API.

Expects: Authorization: Bearer <token>
Compares the token to EXPECTED_TOKEN.
"""

from __future__ import annotations

import os

EXPECTED_TOKEN = os.environ.get("EXPECTED_TOKEN", "")


def _policy(principal_id: str, effect: str, resource: str, context: dict | None = None) -> dict:
    return {
        "principalId": principal_id,
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "execute-api:Invoke",
                    "Effect": effect,
                    "Resource": resource,
                }
            ],
        },
        "context": context or {},
    }


def handler(event, _context):
    method_arn = event.get("methodArn", "*")
    headers = {k.lower(): v for k, v in (event.get("headers") or {}).items()}
    auth = headers.get("authorization", "")

    token = ""
    if auth.lower().startswith("bearer "):
        token = auth.split(" ", 1)[1].strip()

    if not EXPECTED_TOKEN or token != EXPECTED_TOKEN:
        return _policy("anonymous", "Deny", method_arn)

    arn_parts = method_arn.split(":")
    if len(arn_parts) >= 6:
        api_and_stage = arn_parts[5].split("/")
        api_id = api_and_stage[0]
        stage = api_and_stage[1] if len(api_and_stage) > 1 else "*"
        wildcard = f"{':'.join(arn_parts[:5])}:{api_id}/{stage}/*"
    else:
        wildcard = method_arn

    return _policy(
        principal_id="internal-client",
        effect="Allow",
        resource=wildcard,
        context={"caller": "internal-client", "authType": "bearer"},
    )
