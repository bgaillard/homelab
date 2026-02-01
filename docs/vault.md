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

# For each client, copy the public certificate
sudo cp vault-pi-4.crt /etc/ssl/certs/
sudo chmod 400 /etc/ssl/certs/vault-pi-4.crt

# Update the certificate trust store
sudo update-ca-certificates

# Add it to Bitwarden and import it in your browser as a trusted authority
```
