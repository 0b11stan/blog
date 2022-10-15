serve:
  python -m http.server -d www &

push:
  git push
  -pushd .. \
    && git commit -am "update submodule" \
    && git push \
    && popd

deploy: push
	ssh 192.168.1.133 \
		"cd /home/tristan/sources/0b11stan/selfhost/ && ./deploy.sh"

# vim: set syntax=make
