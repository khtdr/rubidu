all: test dist docs

grammar:
	@grep -e "^\s*##" lib/bnf_parser.rb | sed 's/ *## /    /'

test:
	@echo "\033[92m"BNF Test Suite"\033[33m"
	@ruby test.rb

build:
	mkdir -p dist
	echo "#!/usr/bin/env ruby" > dist/rubidu
	grep 'defined?' cli.rb >> dist/rubidu
	cat $(shell grep require_relative cli.rb | cut -d"'" -f2) >> dist/rubidu
	sed '/require_relative/d' cli.rb >> dist/rubidu
	chmod +x dist/rubidu

dist: build
	dist/rubidu --test && dist/rubidu -h

docs:
	@echo "# " Installation > README.md
	@echo '```bash' >> README.md
	@echo "curl -O 'https://raw.githubusercontent.com/khtdr/rubidu/master/dist/rubidu'" >> README.md
	@echo "chmod +x ./rubidu" >> README.md
	@echo "./rubidu --test && ./rubidu -h" >> README.md
	@echo '```' >> README.md
	@echo "# " Self Describing Grammar >> README.md
	@make grammar >> README.md
	cat README.md

clean:
	rm -rf dist

counter:
	echo 'xxx' | ruby rubidu.rb -g x-counter.rbd
