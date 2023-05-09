---
title: "Miscellaneous"
---

<p style="text-align: right">_- 16/12/2022 -_</p>

## Digging into ctfd statistics

Download and unzip your ctf export from `/admin/export`.

Searching all user connections between the 30-11-2022 and 14-12-2022 and
exporting to csv, keeping only the relevant informations.

```bash
jq -r '.results | .[] | [select(.date | test("2022-(11-30|12-(0[1-9]|1[1-4])).*")) | {ip: .ip, user_id: .user_id, date: .date} | .[]] | @csv' tracking.json | sed '/^$/d' | tee access_stat.csv
```

For a json output, wrap the result in an array

```bash
jq -r '[ .results | .[] | select(.date | test("2022-(11-30|12-(0[1-9]|1[1-4])).*")) | {ip: .ip, user_id: .user_id, date: .date} ]' tracking.json | tee access_stat.json
```
