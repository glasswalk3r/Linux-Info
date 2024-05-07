DISTRO_VERSION=$(shell awk -F'=' '/version/ {gsub(" ","", $$2);print $$2}' dist.ini)

.PHONY: cpanfile
cpanfile:
	@dzil build
	cp -v Linux-Info-${DISTRO_VERSION}/cpanfile .
	@dzil clean