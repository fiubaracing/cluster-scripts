#!/bin/bash

cat >> /usr/local/bin/slurm_mail.py <<EOF
#!/usr/bin/env python3
import sys
import json
import argparse
import urllib.request
import urllib.error

# --- CONFIGURATION ---
API_KEY = "${RESEND_API_KEY}"
SENDER_EMAIL = "slurm@${RESEND_VERIFIED_DOMAIN}"
# ---------------------

def send_notification():
    # 1. Read body from Slurm (Standard Input)
    body_text = sys.stdin.read()
    if not body_text.strip():
        body_text = "Job status update (No details provided)."

    # 2. Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("-s", "--subject", required=True)
    parser.add_argument("recipient")
    args = parser.parse_args()

    # 3. Prepare JSON Payload
    url = "https://api.resend.com/emails"
    payload = {
        "from": SENDER_EMAIL,
        "to": [args.recipient],
        "subject": args.subject,
        "text": body_text,
        "html": f"<pre>{body_text}</pre>"
    }

    data = json.dumps(payload).encode('utf-8')

    # 4. Construct Request (Vanilla Python)
    req = urllib.request.Request(url, data=data, method='POST')
    req.add_header('Content-Type', 'application/json')
    req.add_header('Authorization', f'Bearer {API_KEY}')
    req.add_header('User-Agent', 'Slurm-Cluster-Notifier')

    # 5. Send
    try:
        with urllib.request.urlopen(req) as response:
            # Success (200 OK)
            pass 
    except urllib.error.HTTPError as e:
        # Log specific API errors (like 401 Unauthorized, 422 Validation)
        error_body = e.read().decode()
        with open("/tmp/slurm_api_error.log", "a") as f:
            f.write(f"Failed to send to {args.recipient}: {e.code} - {error_body}\n")
    except Exception as e:
        with open("/tmp/slurm_api_error.log", "a") as f:
            f.write(f"General Error: {str(e)}\n")

if __name__ == "__main__":
    send_notification()
EOF

chmod 511 /usr/local/bin/slurm_mail.py
chown slurm:slurm /usr/local/bin/slurm_mail.py
sed -i -E 's|^[[:space:]]*#?[[:space:]]*MailProg=.*|MailProg=/usr/local/bin/slurm_mail.py|' /etc/slurm/slurm.conf
systemctl restart slurmctld
