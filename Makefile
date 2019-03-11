.PHONY: install
install:
	mkdir -p ~/.config
	\cp .Xdefaults ~
	\cp -rf awesome ~/.config
	\cp -rf nano ~/.config
	\cp -rf fish ~/.config
	if test -d ~/.mozilla/firefox/*.default; \
	then \cp -rf firefox/chrome ~/.mozilla/firefox/*.default; \
	fi