.PHONY: test lock
test:
	bash scripts/validate.sh
lock:
	bash scripts/check-verbatim.sh --update
