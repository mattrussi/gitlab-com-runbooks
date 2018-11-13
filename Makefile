.PHONY: site
site:
	scripts/generate-site

.PHONY: clean
clean:
	rm -rf public/
	rm -rf site/
