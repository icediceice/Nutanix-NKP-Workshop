WORKSHOP    ?= nkp-workshop
VPS_USER     = ubuntu
VPS_HOST     = 47.130.166.135
VPS_KEY      = ~/.ssh/light-server.pem
VPS_PATH     = /var/www/static/workshop
BUILD_DIR    = /tmp/ws-build-$(WORKSHOP)

.PHONY: build-workshop deploy-workshop

build-workshop:
	cd workshops/$(WORKSHOP)/hugo && hugo --minify -d $(BUILD_DIR)

deploy-workshop: build-workshop
	rsync -az --delete -e "ssh -i $(VPS_KEY)" \
	  $(BUILD_DIR)/ $(VPS_USER)@$(VPS_HOST):$(VPS_PATH)/$(WORKSHOP)/
	@echo "Deployed: https://light.factor-io.com/workshop/$(WORKSHOP)/"
