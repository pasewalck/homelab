MAIN_SCRIPT = ./open-ports-temp.sh
CONFIG_FILE = ./open-ports-temp.conf
SERVICE = ./open-ports-temp.service

MAIN_SCRIPT_TARGET = /etc/open-ports-temp.conf
CONFIG_FILE_TARGET = /bin/open-ports-temp
SERVICE_TARGET = /etc/systemd/system/open-ports-temp.service

all: install

.PHONY: install
install:
	@echo "Installing ..."
	@sudo install -m 755 $(MAIN_SCRIPT) $(MAIN_SCRIPT_TARGET)
	@sudo install -m 644 $(SERVICE) $(SERVICE_TARGET)
	@sudo install -m 644 $(CONFIG_FILE) $(CONFIG_FILE_TARGET)
	@sudo systemctl daemon-reload
	@echo "Installation complete!"

.PHONY: uninstall
uninstall:
	@echo "Uninstalling ..."
	@sudo systemctl disable --now open-ports-temp.service || true
	@sudo rm -f $(MAIN_SCRIPT_TARGET)
	@sudo rm -f $(SERVICE_TARGET)
	@sudo rm -f $(CONFIG_FILE_TARGET)
	@sudo systemctl daemon-reload
	@echo "Uninstallation complete!"

.PHONY: enable-reboot-service
enable-reboot-service:
	@sudo systemctl enable open-ports-temp.service

.PHONY: disable-reboot-service
disable-reboot-service:
	@sudo systemctl disable open-ports-temp.service

.PHONY: help
help:
	@echo "Usage:"
	@echo ""
	@echo "Targets:"
	@echo "  install                Install the script, config, and service file"
	@echo "  uninstall              Remove all installed files and disable the service"
	@echo "  enable-reboot-service  Enable the service to run at boot"
	@echo "  disable-reboot-service Disable the service from running at boot"
	@echo "  help                   Show this help message"
