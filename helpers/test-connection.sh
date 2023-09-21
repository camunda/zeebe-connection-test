#!/bin/bash

modeler_postgresql_password=$(kubectl get secret cpt-postgresql-web-modeler -o json | jq -r .data.\"postgres-password\" | sed 's/\"//g' | sed 's/\n//g' | base64 -d)


if [[ "$ZEEBE_ADDRESS" == "" ]]; then
  echo "Pre-filling unset env vars"
  keycloak_base_url="$(kubectl get ingress cpt-keycloak -o json | jq -c -r .spec.rules | jq -c -r '.[0].host')"
  token_endpoint="$(curl -X GET $keycloak_base_url/auth/realms/camunda-platform/.well-known/openid-configuration | jq .token_endpoint)"
  zeebe_address="$(kubectl get ingress cpt-zeebe-gateway -o json | jq -c -r .spec.rules | jq -c -r '.[0].host')"":443"
  zeebe_client_id=zeebe
  zeebe_secret=$(kubectl get secret cpt-zeebe-identity-secret -o json | jq -r .data.\"zeebe-secret\" | sed 's/\"//g' | sed 's/\n//g' | base64 -d)
  token_audience=zeebe-api

  export ZEEBE_ADDRESS=$zeebe_address
  echo ZEEBE_ADDRESS=$zeebe_address
  export OAUTH_URL=$token_endpoint
  echo OAUTH_URL=$keycloak_base_url
  export CLIENT_ID=$zeebe_client_id
  echo CLIENT_ID=$zeebe_client_id
  export TOKEN_AUDIENCE=$token_audience
  echo TOKEN_AUDIENCE=$token_audience


fi
ZEEBE_ADDRESS="${ZEEBE_ADDRESS:-}"
OAUTH_URL="${OAUTH_URL:-}"

CLIENT_ID="${CLIENT_ID:-}"
CLIENT_SECRET="${CLIENT_SECRET:-}"
TOKEN_AUDIENCE="${TOKEN_AUDIENCE:-}"


if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
  echo "Validate connection to Camunda 8 (self-managed)"
  echo ""
  echo "  Recognized environment variables:"
  echo ""
  echo "    ZEEBE_ADDRESS"
  echo "    OAUTH_URL"
  echo "    CLIENT_ID"
  echo "    CLIENT_SECRET"
  echo "    TOKEN_AUDIENCE"
  echo ""
  echo "  Example: "
  echo ""
  echo "    ZEEBE_ADDRESS=71dcb42b-a3d3-41fb-955b-e637a81ae06b.bru-2.zeebe.camunda.io:443 \\"
  echo "        OAUTH_URL=https://login.cloud.camunda.io/oauth/token \\"
  echo "        CLIENT_ID=MY_CLIENT_ID CLIENT_SECRET=MY_CLIENT_SECRET \\"
  echo "        TOKEN_AUDIENCE=zeebe.camunda.io \\"
  echo "        $0"

  exit 0
fi

if [[ -z "$ZEEBE_ADDRESS" ]]; then
  echo "ZEEBE_ADDRESS required"
  exit 1
fi

# Function to check if an endpoint is reachable
check_endpoint_reachability() {
    local endpoint="$1"

    echo -n "Checking <$endpoint> is reachable"
    if curl -Is --connect-timeout 5 "$endpoint" >/dev/null; then
        echo " [OK]"
    else
        echo " [FAILED]"
        exit 1
    fi
}

# Function to validate SSL for an endpoint if VALIDATE_SSL is set
validate_ssl() {
    local endpoint="$1"
    local server_name="$(echo $endpoint | cut -d":" -f1)"

    local additional_opts="${@:2}"

    if [[ "x$VALIDATE_SSL" != "x" ]] || [[ "$endpoint" == *443 ]]; then
      echo -n "Checking <$endpoint> SSL configuration"

      if timeout 2 openssl s_client ${additional_opts} -connect "$endpoint" -servername="$server_name" < /dev/null 2>/dev/null | openssl x509 -noout -checkend 0 > /dev/null 2>/dev/null; then
          echo " [OK]"
      else
          echo " [FAILED]"
          exit 1
      fi
    else
        echo "Skipping <$endpoint> SSL validation"
    fi
}

# Function to check if the OAuth token URL is correct and obtain a token
check_oauth_token_url() {
    local oauth_token_url="$1"

    # Make a request to obtain an OAuth token using the client ID and client secret
    local response

    echo -n "Checking <$oauth_token_url> returns valid JWT token"
    response=$(curl -s -X POST "$oauth_token_url" -d "grant_type=client_credentials" -d "client_id=$CLIENT_ID" -d "audience=$TOKEN_AUDIENCE" -d "client_secret=$CLIENT_SECRET")

    if echo "$response" | jq -e '.access_token' >/dev/null; then
        echo " [OK]"
    else
        echo " [FAILED]"
        exit 1
    fi
}

check_zeebe() {
  local zeebe_address="$1"

  check_endpoint_reachability "$zeebe_address" || exit 1
  validate_ssl "$zeebe_address" -alpn h2
}

check_oauth() {
  local oauth_url="$1"

  local oauth_hostname="$(echo $oauth_url | sed -e 's/https:\/\/\([^/]*\).*/\1/')"

  local oauth_port="$([[ "$oauth_url" == https* ]] && echo ":443" || echo "")"
  local oauth_address="$oauth_hostname$oauth_port"

  check_endpoint_reachability "$oauth_hostname" || exit 1
  validate_ssl "$oauth_address" || exit 1
  check_oauth_token_url "$oauth_url" || exit 1
}

##
# main script
##

check_zeebe $ZEEBE_ADDRESS

if [[ "x$OAUTH_URL" != "x" ]]; then
  check_oauth "$OAUTH_URL"
fi
