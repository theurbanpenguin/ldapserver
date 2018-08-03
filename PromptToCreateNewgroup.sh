#!/bin/bash
read -p "Enter the name of the group: " gname
read -p "Enter the GID Number: " gid
cat <<END > $gname.ldif
dn: cn=$gname,ou=groups,dc=example,dc=com
objectClass: posixGroup
cn: $gname
gidNumber: $gid
END
ldapadd -x -W -D cn=admin,dc=example,dc=com -f $gname.ldif
