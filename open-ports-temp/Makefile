MAIN_SCRIPT = ./open-ports-temp.sh
CONFIG_FILE = ./open-ports-temp.conf

MAIN_SCRIPT_TARGET = /etc/open-ports-temp.conf
CONFIG_FILE_TARGET = /bin/open-ports-temp

all: install

.PHONY: install
install:
	@echo "Installing ..."
	@sudo install -m 755 $(MAIN_SCRIPT) $(MAIN_SCRIPT_TARGET)
	@sudo install -m 755 $(CONFIG_FILE) $(CONFIG_FILE_TARGET)
	@echo "Installation complete!"

.PHONY: uninstall
uninstall:
	@echo "Uninstalling ..."
	@sudo rm -f $(MAIN_SCRIPT_TARGET)
	@sudo rm -f $(CONFIG_FILE_TARGET)
	@echo "Uninstallation complete!"

.PHONY: help
help:
	@echo "Usage:"
	@echo "  make install    	Install scripts"
	@echo "  make uninstall  	Remove installed scripts"