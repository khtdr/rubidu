all:
	@echo "\033[92m"Self-describing BNF"\033[33m"
	@grep -e "^\s*##" rubidu.rb | sed 's/ *## //' | sed "s/^[a-z ]*:/`printf "\033[31m"`&`printf "\033[33m"`/g"
	@echo "\033[0m"

test:
	ruby rubidu.rb test_

counter:
	echo 'xxx' | ruby rubidu.rb -g x-counter.rbd

