import requests
from middleware.config import DCT


def post_policy(xml_payload: str, policy_number: str) -> dict:
    """POST a single policy XML to the DuckCreek API."""
    headers = {
        "Content-Type": "application/xml",
        "Authorization": f"Bearer {DCT['api_key']}",
    }
    url = f"{DCT['base_url']}/policy/submit"
    response = requests.post(
        url,
        data=xml_payload.encode("utf-8"),
        headers=headers,
        timeout=DCT["timeout"],
    )
    response.raise_for_status()
    return {"policy_number": policy_number, "status_code": response.status_code, "response": response.text}
