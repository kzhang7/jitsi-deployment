#!/bin/bash

secretsfile="$1"

get-secret () {
    printf '%q' $(grep -e "$1" "$secretsfile" | cut -d "=" -f2)
}

encrypt-secret () {
    get-secret "$1" | base64 -w 0
}

sed -i 's/JICOFO_COMPONENT_SECRET: .*/JICOFO_COMPONENT_SECRET: '$(encrypt-secret "JICOFO_COMPONENT_SECRET")'/g' base/jitsi/jitsi-secret.yaml
sed -i 's/JICOFO_AUTH_PASSWORD: .*/JICOFO_AUTH_PASSWORD: '$(encrypt-secret "JICOFO_AUTH_PASSWORD")'/g' base/jitsi/jitsi-secret.yaml
sed -i 's/JVB_AUTH_PASSWORD: .*/JVB_AUTH_PASSWORD: '$(encrypt-secret "JVB_AUTH_PASSWORD")'/g' base/jitsi/jitsi-secret.yaml
sed -i 's/JVB_STUN_SERVERS: .*/JVB_STUN_SERVERS: '$(encrypt-secret "JVB_STUN_SERVERS")'/g' base/jitsi/jitsi-secret.yaml
sed -i 's/TURNCREDENTIALS_SECRET: .*/TURNCREDENTIALS_SECRET: '$(encrypt-secret "TURNCREDENTIALS_SECRET")'/g' base/jitsi/jitsi-secret.yaml
sed -i 's/JWT_APP_SECRET: .*/JWT_APP_SECRET: '$(encrypt-secret "JWT_APP_SECRET")'/g' base/jitsi/jitsi-secret.yaml
sed -i 's/TURN_HOST: .*/TURN_HOST: '$(encrypt-secret "TURN_HOST")'/g' base/jitsi/jitsi-secret.yaml
sed -i 's/STUN_PORT: .*/STUN_PORT: '$(encrypt-secret "STUN_PORT")'/g' base/jitsi/jitsi-secret.yaml
sed -i 's/TURN_PORT: .*/TURN_PORT: '$(encrypt-secret "TURN_PORT")'/g' base/jitsi/jitsi-secret.yaml
sed -i 's/TURNS_PORT: .*/TURNS_PORT: '$(encrypt-secret "TURNS_PORT")'/g' base/jitsi/jitsi-secret.yaml

sed -i 's/users: .*/users: '$(encrypt-secret "users")'/g' base/ops/logging/es-realm-secret.yaml
sed -i 's/users_roles: .*/users_roles: '$(encrypt-secret "users_roles")'/g' base/ops/logging/es-realm-secret.yaml
