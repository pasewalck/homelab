
PREFIX = /usr/local/bin
SYSTEM_DIR = /etc/systemd/system
ACTIVE_DIR = /etc/c-scheduled-tasks/active
AVAILABLE_DIR = /etc/c-scheduled-tasks/available
DATA_DIR = /etc/c-scheduled-tasks

all: install

.PHONY: install
install:
	@echo "Installing ..."

	@mkdir -p $(PREFIX)
	@mkdir -p $(ACTIVE_DIR)
	@mkdir -p $(AVAILABLE_DIR)

	@install -m 0755 src/c-scheduled-tasks-add.sh $(PREFIX)/c-scheduled-tasks-add
	@install -m 0755 src/c-scheduled-tasks-run.sh $(PREFIX)/c-scheduled-tasks-run

	@install -m 0644 src/system/c-scheduled-tasks-daily.service $(SYSTEM_DIR)/
	@install -m 0644 src/system/c-scheduled-tasks-daily.timer $(SYSTEM_DIR)/

	@systemctl daemon-reload
	@systemctl enable c-scheduled-tasks-daily.timer

	@echo "Installation complete!"

.PHONY: uninstall
uninstall:
	@echo "Uninstalling ..."

	@systemctl disable --now c-scheduled-tasks-daily.timer 2>/dev/null || true
	@systemctl daemon-reload

	@rm -f $(PREFIX)/c-scheduled-tasks-add
	@rm -f $(PREFIX)/c-scheduled-tasks-run
	@rm -f $(SYSTEM_DIR)/c-scheduled-tasks-daily.service
	@rm -f $(SYSTEM_DIR)/c-scheduled-tasks-daily.timer

	@rm -rf $(DATA_DIR)

	@echo "Uninstallation complete!"

.PHONY: help
help:
	@echo "Usage:"
	@echo "  make install    - Install scheduled tasks system"
	@echo "  make uninstall  - Remove scheduled tasks system"
	@echo "  make help       - Show this help"
