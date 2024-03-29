mod_name=$(shell basename `pwd`)
bin_dir=bin
img_dir=img
src_dir=src
zip_dir=zip
pwd_file=hideg.pwd
ocm_file=$(mod_name).ocmod.zip
ymd=202001010000.00


# ckeck module license type
ifeq ($(shell test -e "EULA.txt" && echo -n yes),yes)
    lic_file=EULA.txt
	ignore_src="yes"
else ifeq ($(shell test -e "LICENSE.txt" && echo -n yes),yes)
    lic_file=LICENSE.txt
endif

# check availiability of necessary tools
ifeq (, $(shell which fcl))
    $(error "ERROR: fcl not found!");
else ifeq (, $(shell which hideg))
    $(error "ERROR: hideg not found!")
endif

default: zip

# making zip-file
zip: enc
	if [ -d $(zip_dir) ]; then rm -f "$(zip_dir)/$(ocm_file)"; else mkdir -p "$(zip_dir)"; fi

	@echo Setting date/time...
	@find "$(src_dir)" -exec touch -a -m -t $(ymd) {} \;
	@echo Setting date/time [DONE]

	@echo Making ZIP...;
	cd "$(src_dir)" && zip -9qrX "../$(zip_dir)/$(ocm_file)" * "../$(lic_file)"

	@echo Making ZIP [DONE]

	@echo
	@echo Module \""$(mod_name)"\" successfully compiled!
	@echo

# packing/encrypting bin-file
enc: pwd
	@echo
	@echo ----------------
	@if [ -f "$(pwd_file)" ]; then \
		echo Making FCL...; \
		mkdir -p "$(bin_dir)"; \
		fcl make -q -f -E$(bin_dir) -E$(img_dir) -E.git -Ehideg.pwd "$(bin_dir)/$(mod_name)"; \
		echo Making FCL [DONE]; \
		echo Making HIDEG...; \
		hideg "$(bin_dir)/$(mod_name).fcl"; \
		echo Making HIDEG [DONE]; \
		rm -f "$(bin_dir)/$(mod_name).fcl"; \
	fi

# check pwd-file
pwd: git
	@if [ ! -f "$(pwd_file)" ]; then \
		hideg; \
	fi

# exclude src dir for paid modules and add for free
git:
	@if [ ! -z $(ignore_src) ]; then \
		grep -xqF -- "$(src_dir)" ".gitignore" || printf "\n$(src_dir)\n" >> ".gitignore"; \
	else \
		grep -v "$(src_dir)" ".gitignore" > ".gitignore.tmp"; \
		mv -f .gitignore.tmp .gitignore; \
	fi

# decrypting/unpacking bin
dec: pwd
	@if [ -f "$(pwd_file)" -a -f "$(bin_dir)/$(mod_name).fcl.g" ]; then \
		hideg "$(bin_dir)/$(mod_name).fcl.g"; \
		fcl extr -f "$(bin_dir)/$(mod_name).fcl"; \
	elif [ -a -f "$(bin_dir)/$(mod_name).fcl" ]; then \
		fcl extr -f "$(bin_dir)/$(mod_name).fcl"; \
	fi

# show list of files in fcl-file
list: pwd
	@if [ -f "$(pwd_file)" -a -f "$(bin_dir)/$(mod_name).fcl.g" ]; then \
		hideg "$(bin_dir)/$(mod_name).fcl.g"; \
		fcl list "$(bin_dir)/$(mod_name).fcl"; \
		rm -f "$(bin_dir)/$(mod_name).fcl"; \
	elif [ -a -f "$(bin_dir)/$(mod_name).fcl" ]; then \
		fcl list -f "$(bin_dir)/$(mod_name).fcl"; \
	fi
