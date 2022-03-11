---
title: "Injections NoSQL"
---

<p style="text-align: right">_- last update 11/03/2022 -_</p>

Curl à toutes les options qu'il faut pour encoder les entrées, même en query
string:

```bash
curl --include 'http://10-10-100-154.p.thmlabs.com/search' \
	--cookie-jar ./cookies --cookie ./cookies \
	--get \
	--data-urlencode 'username[$ne]=xyz' \
	--data-urlencode 'role=guest'
```
