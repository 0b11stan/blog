www:
	mkdir $@
	./build.sh $@

clean:
	rm posts/index.md
	rm -r www
