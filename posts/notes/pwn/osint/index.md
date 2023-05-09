---
title: "OSINT & CTI"
---

<p style="text-align: right">_- last update 09/08/2022 -_</p>

## Github Secrets

[trufflehog](https://github.com/trufflesecurity/trufflehog) is scanning github
repository to find secrets.

## Google Hacking / Dorking

Here is a [nice tutorial](https://support.google.com/websearch/answer/2466433)

There are no official detailed documentation but there are a lot of [cheat sheets](https://gist.github.com/sundowndev/283efaddbcf896ab405488330d1bbc06)

Most useful ones:

* `site:...`
* `inurl:...`
* `filetype:...`
* `intitle:...`
* `cache:...` (get the latest cached version by the Google search engine)

The gold one when starting a pentest: `site:target.net admin`

## Whois

The whois database is a greate way to learn more about a domain:

* creation / update date
* some technical emails
* organisation owning the domain
* ...

## Data leak and breach websites

If you found an email, search if this email's password has been leaked.

* https://haveibeenpwned.com/

## Reputation and OSINT informations

* [VirusTotal](https://www.virustotal.com/gui/home/upload) - A service that provides a cloud-based detection toolset and sandbox environment.
* [IPinfo.io](https://ipinfo.io/) - A service that provides detailed information about an IP address by focusing on geolocation data and service provider.
* [Talos Reputation](https://talosintelligence.com/) - An IP reputation check service is provided by Cisco Talos.
* [Urlscan.io](https://urlscan.io/) - A service that analyses websites by simulating regular user behaviour.
* [Browserling](https://www.browserling.com/) - A browser sandbox is used to test suspicious/malicious links.
* [Wannabrowser](https://www.wannabrowser.net/) - A browser sandbox is used to test suspicious/malicious links.
* [InQuest](https://labs.inquest.net/) - A service provides network and file analysis by using threat analytics.

## Email analysis

[emlAnalyzer](https://github.com/wahlflo/eml_analyzer)

```bash
emlAnalyzer -i Desktop/sample.eml --header -u --text --extract-all
```
