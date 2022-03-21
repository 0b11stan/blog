---
title: "Virtualization"
---

<p style="text-align: right">_- last update 12/03/2022 -_</p>

## Containers - Oneliners

_in the following `s/podman/docker/` works_

List 5 lagest images (to make some space)

```bash
podman image list --sort size --format '{{.ID}} - {{.Repository}} - {{.Size}}' | tail -n 5
```

Remove 5 largest images

```bash
podman rmi $(podman image list --sort size -q | tail -n 5)
```

