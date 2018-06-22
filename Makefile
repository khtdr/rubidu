all:
	make test
	make grammar
	make build

grammar:
	@echo "\033[92m"BNF Grammar"\033[33m"
	@grep -e "^\s*##" lib/bnf_parser.rb | sed 's/ *## //' | sed "s/^[a-z ]*:/`printf "\033[31m"`&`printf "\033[33m"`/g"
	@echo "\033[0m"

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

docs:
	@echo "\033[92m"Installation"\033[0m"
	@echo '```bash' > README.md
	@echo "curl -O 'https://github.com/khtdr/.../dist/rubidu'" >> README.md
	@echo "chmod +x ./rubidu" >> README.md
	@echo "TEST=true ./rubidu && ./rubidu -h" >> README.md
	@echo '```' >> README.md
	@cat README.md

clean:
	rm -rf dist

counter:
	echo 'xxx' | ruby rubidu.rb -g x-counter.rbd
