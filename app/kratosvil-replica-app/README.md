# kratosvil-replica-app

Minimal nginx:alpine image that renders a single HTML page showing its own
pod identity, so a load balancer distributing traffic across replicas is
visibly provable — refresh the page, see a different pod name.

## How it works

The Kubernetes Downward API injects the pod's real name as the `POD_NAME`
env var (see `base/deployment.yaml`). nginx's official image already ships
an entrypoint step that runs `envsubst` against files in a template
directory before startup — normally used to template nginx config. This
image redirects that same mechanism at the HTML root instead:

```
NGINX_ENVSUBST_TEMPLATE_DIR=/etc/nginx/html-templates
NGINX_ENVSUBST_TEMPLATE_SUFFIX=.template
NGINX_ENVSUBST_OUTPUT_DIR=/usr/share/nginx/html
```

No custom entrypoint script needed — `index.html.template` just has
`${POD_NAME}` in it, and it comes out rendered on the other side.

## Local build/test

```
docker build -t kratosvil-replica-app:local .
docker run --rm -e POD_NAME=test-pod-123 -p 8090:80 kratosvil-replica-app:local
curl http://localhost:8090
```

## CI

`.github/workflows/build-and-promote.yml` builds and pushes this image to
ECR on every push touching this directory, tags it with the short commit
SHA, and bumps `overlays/dev/kustomization.yaml` to point at the new tag.
