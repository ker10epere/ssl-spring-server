find ~+ -type f -not -iname "*.sh" -exec rm {} +

mkdir ca server client
# generate CA
openssl genrsa -out ca/ca.key 2048

openssl req -new -x509 -nodes -days 365 \
  -key ca/ca.key \
  -subj "/CN=root-ca" \
  -out ca/ca.crt

openssl x509 -text -noout -in ca/ca.crt | grep CN

# generate server cert
openssl req -newkey rsa:2048 -nodes -days 365 \
  -subj "/CN=localhost" \
  -keyout server/server.key \
  -out server/server.csr

openssl req -text -noout -in server/server.csr | grep CN


# execute in wsl context
# sign server csr
openssl x509 -req -days 365 -set_serial 01 \
   -in server/server.csr \
   -out server/server.crt \
   -CA ca/ca.crt  \
   -CAkey ca/ca.key \
   -extfile <(printf "extendedKeyUsage=serverAuth")

openssl x509  -text -noout -in server/server.crt > serverout


openssl verify -CAfile ca/ca.crt server/server.crt

# generate pfx server
openssl pkcs12 -export \
  -out server/server.pfx \
  -inkey server/server.key \
  -in server/server.crt \
  -passin pass:changeit \
  -passout pass:changeit \
  -CAfile ca/ca.crt

openssl pkcs12 -export \
  -out server/server.p12 \
  -inkey server/server.key \
  -in server/server.crt \
  -certfile ca/ca.crt \
  -passout pass:changeit \
  -name springboot \
  -noiter -nomaciter

openssl pkcs12 -in server/server.pfx  -passin pass:changeit -passout pass:changeit

# generate client cert
# openssl req -newkey rsa:2048 -nodes -days 365 \
#   -subj "/CN=kerizaki" \
#   -keyout client/kerizaki.key \
#   -out client/kerizaki.csr

# openssl x509 -req -days 365 -set_serial 01  \
#   -in client/kerizaki.csr    \
#   -out client/kerizaki.crt  \
#   -CA ca/ca.crt  \
#   -CAkey ca/ca.key \
#   -extfile <(printf "extendedKeyUsage=clientAuth")

# openssl x509  -text -noout -in client/kerizaki.crt > clientout

# openssl pkcs12 -export \
#   -out client/kerizaki.pfx \
#   -inkey client/kerizaki.key \
#   -in client/kerizaki.crt \
#   -CAfile ca/ca.crt \
#   -passin pass:changeit \
#   -passout pass:changeit \
#   -name kerizaki

# works for wsl
for name in kerizaki ryuzaki charlotte; do
  openssl req -newkey rsa:2048 -nodes \
    -subj "/CN=$name" \
    -keyout client/$name.key \
    -out client/$name.csr

  openssl req -text -noout -in client/$name.csr | grep CN

  openssl x509 -req -days 365 -set_serial 01  \
   -in client/$name.csr    \
   -out client/$name.crt  \
   -CA ca/ca.crt  \
   -CAkey ca/ca.key \
   -extensions SAN  \
   -extfile <(printf "[SAN]\nextendedKeyUsage=clientAuth")

  openssl verify -CAfile ca/ca.crt client/$name.crt
  openssl pkcs12 -export \
    -out client/$name.pfx \
    -inkey client/$name.key \
    -in client/$name.crt \
    -CAfile ca/ca.crt \
    -passin pass:changeit \
    -passout pass:changeit \
    -name $name
done

for name in kerizaki ryuzaki charlotte; do
  PASSWORD=changeit
  keytool -importkeystore \
    -srckeystore client/$name.pfx \
    -srcstoretype pkcs12 \
    -destkeystore client/clients.jks \
    -deststoretype JKS \
    -storepass $PASSWORD \
    -keypass $PASSWORD \
    -srcstorepass $PASSWORD \
    -alias $name
done

keytool -list  -storepass changeit -v -keystore client/clients.jks > jks-contents
openssl x509  -text -noout -in client/kerizaki.crt

keytool -import \
-trustcacerts \
-keystore ca/cacerts \
-storepass changeit \
-alias root-ca \
-noprompt \
-file ca/ca.crt

openssl x509 -in ca/ca.crt -text