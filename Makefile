.PHONY: fmt

all: fmt

fmt:
	 find -name "*.jsonnet" -type f -not -path "./dashboards/vendor/*" | xargs -n1 jsonnetfmt --string-style l -i
