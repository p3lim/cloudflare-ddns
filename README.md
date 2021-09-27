# cloudflare-ddns

This repository builds a container image that will update [CloudFlare](https://cloudflare.com) DNS records when run.

It is configured entirely by environment variables:

- `API_TOKEN`: a [custom API token](https://dash.cloudflare.com/profile/api-tokens) for one or multiple zones, with the following permissions:
	- Zone, Zone, Read
	- Zone, DNS, Edit
- `RECORDS`: a space-separated list of record names to update
	- these must be fully-qualified domain names, e.g. `RECORDS="my.example.org example.org"`

### Usage

One-off:

```bash
podman run -e API_TOKEN="..." -e RECORDS="my.example.org example.org" ghcr.io/p3lim/cloudflare-ddns:latest
```

Kubernetes CronJob with Secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-ddns
type: Opaque
data: # base64 encoded
  API_TOKEN: ...
  RECORDS: bXkuZXhhbXBsZS5vcmcgZXhhbXBsZS5vcmc=
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cloudflare-ddns
spec:
  schedule: '0 * * * *' # once an hour
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: cloudflare-ddns
              image: ghcr.io/p3lim/cloudflare-ddns:latest
              envFrom:
                - secretRef:
                    name: cloudflare-ddns
          restartPolicy: Never
```

### Longevity

Steps have been taken to ensure the longevity of this repository and its image:

- A [workflow](https://github.com/p3lim/cloudflare-ddns/blob/master/.github/workflows/build.yml) watches for changes to the Dockerfile, which builds and pushes the image.
- [Dependabot](https://github.com/dependabot) watches for updates to the base image and creates pull requests when there's a new version.
- [Permissive license](https://github.com/p3lim/cloudflare-ddns/blob/master/LICENSE.txt) so anyone can take over maintenance should this repository become stale.
