.PHONY: app debug run test clean install

app:            ## Universal release build → build/ClipVault.app
	@scripts/build-app.sh

debug:          ## Debug build for the current architecture only
	@CONFIG=debug ARCHS="$$(uname -m)" scripts/build-app.sh

run: debug      ## Build and launch the app
	@open build/ClipVault.app

test:           ## Run logic checks (works with Command Line Tools only)
	@scripts/smoke-test.sh

install: app    ## Copy the built app into /Applications
	@rm -rf /Applications/ClipVault.app
	@cp -R build/ClipVault.app /Applications/ClipVault.app
	@echo "Installed to /Applications/ClipVault.app"

clean:
	@rm -rf build .build
