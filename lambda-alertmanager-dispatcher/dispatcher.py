import base64
import json
import os
import urllib.request
import urllib.error

MCP_SERVER_URL = os.environ.get("MCP_SERVER_URL", "")
AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")
AWS_ACCOUNT_ID = os.environ.get("AWS_ACCOUNT_ID", "")


def _node_id_and_type(labels):
    if "pod" in labels:
        return labels["pod"], "KubernetesPod"
    if "deployment" in labels:
        return labels["deployment"], "KubernetesDeployment"
    if "namespace" in labels:
        return labels["namespace"], "KubernetesNamespace"
    return labels.get("alertname", "unknown"), "KubernetesResource"


def handler(event, context):
    body = event.get("body", "{}")
    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode()
    payload = json.loads(body)

    results = []
    for alert in payload.get("alerts", []):
        labels = alert.get("labels", {})
        status = alert.get("status", "firing")
        alarm_name = labels.get("alertname", "unknown")
        node_id, resource_type = _node_id_and_type(labels)

        print(f"alertmanager alert={alarm_name} node={node_id} status={status} namespace={labels.get('namespace','')}")

        if status != "firing":
            results.append({"alarm_name": alarm_name, "status": status, "forwarded": False})
            continue

        incident = {
            "alarm_name": alarm_name,
            "node_id": node_id,
            "resource_type": resource_type,
            "region": AWS_REGION,
            "account_id": AWS_ACCOUNT_ID,
            "source": "prometheus-alertmanager",
            "namespace": labels.get("namespace", ""),
        }

        if not MCP_SERVER_URL:
            print(f"MCP_SERVER_URL no configurado, solo logueando: {json.dumps(incident)}")
            results.append({"alarm_name": alarm_name, "forwarded": False, "reason": "MCP_SERVER_URL not set"})
            continue

        req = urllib.request.Request(
            f"{MCP_SERVER_URL}/incident",
            data=json.dumps(incident).encode(),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                print(f"alarm={alarm_name} mcp_status={resp.status}")
                results.append({"alarm_name": alarm_name, "forwarded": True, "mcp_status": resp.status})
        except urllib.error.URLError as e:
            print(f"alarm={alarm_name} mcp_error={e}")
            results.append({"alarm_name": alarm_name, "forwarded": False, "error": str(e)})

    return {
        "statusCode": 200,
        "body": json.dumps({"processed": len(results), "results": results}),
    }
