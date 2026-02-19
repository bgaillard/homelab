# Vault

Key shares: 6
Key threshold: 3

## TLS certificate

For now the TLS certificate used to expose the Vault UI and API is a self-signed certificate which has been manually generated.

The generation has been done using the following OpenSSL command:

```bash
# Create the self-signed TLS certificate
#
# For SAN and Google Chrome see the below link.
#
# @see https://stackoverflow.com/questions/10175812/how-can-i-generate-a-self-signed-ssl-certificate-using-openssl/41366949#41366949
openssl req \
    -x509 \
    -nodes \
    -days 365 \
    -newkey rsa:4096 \
    -keyout vault-pi-4.key \
    -out vault-pi-4.crt \
    -extensions san -config \
  <(echo "[req]"; 
    echo distinguished_name=req; 
    echo "[san]"; 
    echo subjectAltName=DNS:vault
    ) \
    -subj "/CN=vault"
```

The certificate and it's private key are then stored in Bitwarden for future reference and usage in Ansible.
