#!/bin/bash

set -eo pipefail

if [[ -z "$API_TOKEN" ]]; then
	if [[ -r "$API_TOKEN_FILE" ]]; then
		API_TOKEN="$(< "$API_TOKEN_FILE")"
	else
		echo 'Missing environment variable API_TOKEN'
		exit 1
	fi
fi
if [[ -z "$RECORDS" ]]; then
	echo 'Missing environment variable RECORDS'
	exit 1
fi

# wrap the cloudflare API
api(){
	path="$1"
	shift

	res="$(curl -sS -H "Content-Type: application/json" -H "Authorization: Bearer $API_TOKEN" "https://api.cloudflare.com/client/v4/$path" "$@")"
	if [ "$(jq -r '.success' <<< "$res")" = "false" ]; then
		jq -r '.errors[] | .message' <<< "$res" >&2
		exit 1
	fi

	echo "$res"
}

update(){
	# get the public IP
	for url in "http://ifconfig.me/ip" "http://ifconfig.co" "http://ipv4.icanhazip.com"; do
		IP="$(curl -s "$url")"
		[ -n "$IP" ] && break
	done

	if [ -z "$IP" ]; then
		echo "Could not get public IP"
		exit 1
	fi

	# make sure the token is working
	api 'user/tokens/verify' | jq -r '.messages[] | .message'

	# iterate through the zones
	while read -r zone_id zone; do
		# iterate through the records
		echo "Enumerating '$zone' ($zone_id)"
		while read -r record_id record value ttl proxied; do
			# check if we're supposted to monitor this record
			if grep -qE "(^|\s)$record(\s|$)" <<< "$RECORDS"; then
				# check if the record value differs from the public IP
				if [[ "$value" != "$IP" ]]; then
					echo "Updating $record: $value -> $IP"
					api "zones/$zone_id/dns_records/$record_id" -XPUT \
						-d "{\"content\":\"$IP\",\"type\":\"A\",\"name\":\"$record\",\"ttl\":$ttl,\"proxied\":$proxied}" >/dev/null
				else
					echo "Record '$record' is up to date ($value)"
				fi
			fi
		done < <(api "zones/$zone_id/dns_records" | jq -r '.result[] | select(.type == "A") | "\(.id) \(.name) \(.content) \(.ttl) \(.proxied)"')
	done < <(api 'zones' | jq -r '.result[] | "\(.id) \(.name)"')
}

if [[ -z "$INTERVAL" ]]; then
	update
else
	trap 'exit 0' SIGINT SIGTERM

	while true; do
		update
		echo "Sleeping for $INTERVAL seconds"
		sleep "$INTERVAL"
	done
fi
