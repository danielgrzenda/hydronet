.DEFAULT_GOAL := help

.PHONY: help
help: ## a guide to the make commands available in this project
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'


OSFLAG :=
ARCHFLAG :=
M1FLAG = FALSE
ifeq ($(OS),Windows_NT)
	OSFLAG += WIN32
	ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
		ARCHFLAG += AMD64
	endif
	ifeq ($(PROCESSOR_ARCHITECTURE),x86)
		ARCHFLAG += IA32
	endif
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		OSFLAG += LINUX
	endif
	ifeq ($(UNAME_S),Darwin)
		OSFLAG += OSX
	endif
		UNAME_P := $(shell uname -p)
	ifeq ($(UNAME_P),x86_64)
		ARCHFLAG += AMD64
	endif
		ifneq ($(filter %86,$(UNAME_P)),)
			ARCHFLAG += -D IA32
		endif
	ifneq ($(filter arm%,$(UNAME_P)),)
		ARCHFLAG += -D ARM
		# ARM on Mac -> M1 chip
		ifeq ($(UNAME_S),Darwin)
			M1FLAG = TRUE
		endif
	endif
endif

# deal with M1's idiosyncrasy here
ifeq ($(M1FLAG),FALSE)
	gpu_num := $(shell nvidia-smi --list-gpus | wc -l)
else
	gpu_num := 0
endif

# add some standard project variables
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))
current_abs_path := $(subst Makefile,,$(mkfile_path))

project_name := hydronet
ifeq ($(gpu_num),0)
	accelerator := cpu
else
	accelerator := gpu
endif
dev_tag := $(project_name)_dev_docker


.PHONY: info
info: ## print important configurations on this computer
	@echo Operating System: $(OSFLAG)
	@echo Computer Architecture: $(ARCHFLAG)
	@echo Number of Accelerators: $(gpu_num)
	@echo M1 Accelerator: $(M1FLAG)

.PHONY: paths
paths: ## print the paths assosicated with make commands
	@echo $(mkfile_path)
	@echo $(current_dir)
	@echo $(current_abs_path)

.PHONY: docker-build
docker-build: ## build a new development docker container
	cd $(current_abs_path)
	docker build -f ./infra/containers/dev.dockerfile -t $(dev_tag) .

.PHONY: docker-run
docker-run: ## run the most recently built development docker container
	cd $(current_abs_path)
ifeq ($(gpu_num),0)
	docker run -v $(current_abs_path):/$(project_name) --name run_$(project_name)_$(accelerator) --rm -i -t $(dev_tag) bash
else
	docker run -v $(current_abs_path):/$(project_name) --gpus all --name run_$(project_name)_$(accelerator) --rm -i -t $(dev_tag) bash
endif


.PHONY: docker-jupyter
docker-jupyter: ## run a jupyter server from the most recently built docker container
	cd $(current_abs_path)
ifeq ($(gpu_num),0)
	docker run -v $(current_abs_path):/$(project_name) --name jupyter_$(project_name)_$(accelerator) --rm -p 8888:8888 -t $(dev_tag) jupyter lab --port=8888 --ip='*' --NotebookApp.token='' --NotebookApp.password='' --no-browser --notebook-dir=/ --allow-root
else
	docker run -v $(current_abs_path):/$(project_name) --gpus all --name jupyter_$(project_name)_$(accelerator) --rm -p 8888:8888 -t $(dev_tag) jupyter lab --port=8888 --NotebookApp.token='' --NotebookApp.password='' --ip='*' --no-browser --notebook-dir=/ --allow-root
endif

