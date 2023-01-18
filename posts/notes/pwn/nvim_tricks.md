Given a list of hosts like

```
1.1.1.1
2.2.2.2
3.3.3.3
```

The following line is telling you if there are http or https enabled

```vim
:%!xargs -I{} bash -c "printf '{}\t'; curl -Iks http://{} &>/dev/null && printf ' 80'; curl -Iks https://{} &>/dev/null && printf ' 443'; printf '\n'"
```
