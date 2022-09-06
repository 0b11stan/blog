www:
	mkdir $@
	./build.sh $@

clean:
	-rm -r www

serv:
	python -m http.server --directory www &
