---
title: "Artificial Intelligence"
---

<p style="text-align: right">_- last update 12/03/2022 -_</p>

Here, by **Artificial Intelligence** I mean algorithms that can replicate human
behaviours. Given this definition, all algorithms may be described as _AI_ and
they are, in a way. Anyway, here are my notes about STT, TTS, robotic,
deeplearning, ...

## STT and TTS

* STT = **S**peech **T**o **T**ext
* TTS = **T**ext **T**o **S**peech

Projet intéressant : [mozillia/DeepSpeech](https://github.com/mozilla/DeepSpeech)

L'[installation](https://deepspeech.readthedocs.io/en/r0.9/?badge=latest) est
simple, voici un Dockerfile qui installe deepspeech sur du debian:

```dockerfile
FROM docker.io/debian
RUN mkdir -p /srv/deepspeech
WORKDIR /srv/deepspeech
RUN apt-get -qq update && \
    apt-get -qq -y install python3 python3-pip curl
RUN pip install deepspeech
```

Build and run with

```bash
podman build -t deepspeech .
podman run -it --rm deepspeech bash
```

Problème: c'est difficile de trouver des models pour le français.

[Ce poste](https://discourse.mozilla.org/t/tutorial-how-i-trained-a-specific-french-model-to-control-my-robot/22830)
explique une expérience détaillé d'entrainement d'un corpus français.

A voir si c'est possible d'entrainer un modèle avec les bases de donnée libres:
https://commonvoice.mozilla.org/en/datasets
