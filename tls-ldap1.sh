#!/bin/bash
#Install tools
sudo apt install -y gnutls-bin ssl-cert
#Generate CA Private Key
sudo sh -c "certtool --generate-privkey > /etc/ssl/private/cakey.pem"
#Create template for CA
sudo sh -c "cat <<END > /etc/ssl/ca.info
cn = Example
ca
cert_signing_key
END
"
#Create CA Certificate
sudo certtool --generate-self-signed \
--load-privkey /etc/ssl/private/cakey.pem \
--template /etc/ssl/ca.info \
--outfile /etc/ssl/certs/cacert.pem
#Create Server Privae Key
sudo certtool --generate-privkey \
--bits 1024 \
--outfile /etc/ssl/private/ldap1_slapd_key.pem
#Create Template For Server
sudo sh -c "cat <<END > /etc/ssl/ldap1.info
organization = Example
cn = ldap1.example.com
tls_www_server
encryption_key
signing_key
expiration_days = 3650
END
"
#Create Signed Certificate for Server
sudo certtool --generate-certificate \
--load-privkey /etc/ssl/private/ldap1_slapd_key.pem \
--load-ca-certificate /etc/ssl/certs/cacert.pem \
--load-ca-privkey /etc/ssl/private/cakey.pem \
--template /etc/ssl/ldap1.info \
--outfile /etc/ssl/certs/ldap1_slapd_cert.pem
#Setup permissions for slapd to access certs
sudo chgrp openldap /etc/ssl/private/ldap1_slapd_key.pem
sudo chmod 0640 /etc/ssl/private/ldap1_slapd_key.pem
sudo gpasswd -a openldap ssl-cert
sudo systemctl restart slapd.service
#Configure slapd with certs
cat <<END | sudo ldapmodify -Y EXTERNAL -H ldapi:///
dn: cn=config
add: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/ssl/certs/cacert.pem
-
add: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ssl/certs/ldap1_slapd_cert.pem
-
add: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ssl/private/ldap1_slapd_key.pem
END