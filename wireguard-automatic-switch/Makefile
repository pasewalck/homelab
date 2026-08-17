
BIN_DIR = /usr/local/bin
SYSTEM_DIR = /etc/systemd/system
CONF_DIR = /etc/wireguard-automatic-switch

all: install

.PHONY: install
install:
	@echo "Installing ..."

	@mkdir -p $(BIN_DIR)
	@mkdir -p $(SYSTEM_DIR)
	@mkdir -p $(CONF_DIR)

	@install -m 0755 src/wireguard-automatic-switch.sh $(BIN_DIR)/wireguard-automatic-switch

	@install -m 0644 src/system/wireguard-automatic-switch.service $(SYSTEM_DIR)/wireguard-automatic-switch.service
	@install -m 0644 src/system/wireguard-automatic-switch.timer $(SYSTEM_DIR)/wireguard-automatic-switch.timer

	@if [ ! -f "$(CONF_DIR)/main.conf" ]; then \
        install -m 0644 src/sample.main.conf $(CONF_DIR)/main.conf; \
    fi

	@echo "Installation complete!"

.PHONY: enable
enable:
	@systemctl daemon-reload
	@systemctl enable wireguard-automatic-switch.timer
	@systemctl start wireguard-automatic-switch.timer

.PHONY: disable
disable:
	@systemctl disable --now wireguard-automatic-switch-daily.timer 2>/dev/null || true
	@systemctl daemon-reload

.PHONY: uninstall
uninstall:
	@echo "Uninstalling ..."

	@systemctl disable --now wireguard-automatic-switch-daily.timer 2>/dev/null || true
	@systemctl daemon-reload

	@rm -f $(BIN_DIR)/wireguard-automatic-switch.sh
	@rm -f $(SYSTEM_DIR)/wireguard-automatic-switch-daily.service
	@rm -f $(SYSTEM_DIR)/wireguard-automatic-switch-daily.timer

	@echo "Uninstallation complete!"

.PHONY: logs
logs:
	journalctl -u wireguard-automatic-switch.service --since "5 minutes ago"

.PHONY: status
status:
	@systemctl status wireguard-automatic-switch.timer

.PHONY: help
help:
	@echo "Usage:"
	@echo "  make install    - Install scheduled tasks system"
	@echo "  make uninstall  - Remove scheduled tasks system"
	@echo "  make help       - Show this help"
