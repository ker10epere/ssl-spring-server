# DELETE ALL FILES

```shell
find ~+ -type f -not -iname "*.md" -exec rm {} +
```

---

# Prerequisite

```shell
mkdir ca server client
```

---

# CA

```shell
# GENERATE CA KEY
openssl genrsa -out ca/ca.key 2048
# GENERATE CA CERTIFICATE
openssl req -x509 -new -nodes -key ca/ca.key -sha512 -days 3650 -out ca/ca.crt -subj "/CN=root-ca"
# VERIFY CA CERTIFICATE
openssl x509 -in ca/ca.crt -noout -text
```

---

# SERVER

```shell
# GENERATE SERVER KEY
openssl genrsa -out server/server.key 2048

# GENERATE CERTIFICATE SIGNING REQUEST
# KEEP IN MIND: COMMON NAME MUST DIFFER FROM CA'S COMMON NAME
openssl req -new -nodes -key server/server.key -out server/server.csr -subj "/CN=localhost"

# SIGN CSR THEN GENERATE SERVER CERTIFICATE
openssl x509 -req -in server/server.csr -days 3650 -CA ca/ca.crt -CAkey ca/ca.key -out server/server.crt

# VERIFY SERVER CERTIFICATE
openssl verify -CAfile ca/ca.crt server/server.crt

# CREATE PKCS12
openssl pkcs12 -export -out server/server.pfx -inkey server/server.key -in server/server.crt -certfile ca/ca.crt -passout pass:changeit -noiter -nomaciter
# WITH ALIAS springboot
openssl pkcs12 -export -out server/server-with-alias.pfx -inkey server/server.key -in server/server.crt -certfile ca/ca.crt -passout pass:changeit -name springboot -noiter -nomaciter

# VERIFY PKCS12
openssl pkcs12 -in server/server.pfx -passin pass:changeit -passout pass:changeit
openssl pkcs12 -in server/server-with-alias.pfx -passin pass:changeit -passout pass:changeit

```

---

# CLIENT

```shell

# GENERATE CLIENT KEY
openssl genrsa -out client/client.key 2048

# GENERATE CERTIFICATE SIGNING REQUEST
# KEEP IN MIND: COMMON NAME MUST DIFFER FROM CA'S COMMON NAME
openssl req -new -nodes -key client/client.key -out client/client.csr -subj "/CN=client.com"

# SIGN CSR THEN GENERATE CLIENT CERTIFICATE
openssl x509 -req -in client/client.csr -days 3650 -CA ca/ca.crt -CAkey ca/ca.key -out client/client.crt  -extfile <(printf "extendedKeyUsage=clientAuth") -set_serial "01"

# CHECK CONTENTS
openssl x509 -noout -text -in client/client.crt

# VERIFY CLIENT CERTIFICATE
openssl verify -CAfile ca/ca.crt client/client.crt
openssl verify -CAfile ca/ca.crt client/client.crt server/server.crt

# CREATE PKCS12
openssl pkcs12 -export -out client/client-with-alias.pfx -inkey client/client.key -in client/client.crt -certfile ca/ca.crt -passout pass:changeit -name springboot -noiter -nomaciter
openssl pkcs12 -export -out client/client.pfx -inkey client/client.key -in client/client.crt -certfile ca/ca.crt -passout pass:changeit -noiter -nomaciter

# VERIFY PKCS12
openssl pkcs12 -in client/client.pfx -passin pass:changeit -passout pass:changeit
openssl pkcs12 -in client/client-with-alias.pfx -passin pass:changeit -passout pass:changeit

```

---

# TRUSTSTORE

```shell
# CREATE TRUSTSTORE USING keytool
keytool -importcert -storetype PKCS12 -keystore ca/cacerts -storepass changeit -alias ca -file ca/ca.crt -noprompt

# CHECK TRUSTSTORE CONTENTS
keytool -list -storetype PKCS12 -keystore ca/cacerts -storepass changeit
```
