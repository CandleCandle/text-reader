

.PHONY: clean build test

test:
	stable env ponyc -o bin test && ./bin/test

build:
	stable env ponyc -o bin text-reader

clean:
	rm bin/*
