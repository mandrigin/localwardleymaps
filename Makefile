.PHONY: all build clean test \
       electron electron-build electron-dev \
       native native-release native-test native-clean \
       venv

VENV_DIR := .venv
PYTHON   := python3
NODE_VERSION := 22

# ── Top-level targets ────────────────────────────────────────────────

all: electron native            ## Build everything (Electron + native)

test: native-test               ## Run all test suites

clean: electron-clean native-clean  ## Clean all build artifacts
	rm -rf $(VENV_DIR)

# ── Electron (frontend/) ────────────────────────────────────────────

venv:
	@echo "Creating Python virtualenv..."
	$(PYTHON) -m venv $(VENV_DIR)
	$(VENV_DIR)/bin/pip install --upgrade pip setuptools

electron: venv                  ## Build Electron app (debug)
	@echo "==> Building Electron app..."
	@. $(VENV_DIR)/bin/activate && \
		. ~/.nvm/nvm.sh && \
		nvm use $(NODE_VERSION) && \
		cd frontend && \
		yarn install && \
		yarn electron:build

electron-build: electron        ## Alias for electron

electron-dev: venv              ## Run Electron app in dev mode
	@. $(VENV_DIR)/bin/activate && \
		. ~/.nvm/nvm.sh && \
		nvm use $(NODE_VERSION) && \
		cd frontend && \
		yarn install && \
		yarn electron:dev

electron-clean:
	rm -rf frontend/out frontend/dist frontend/.next

# ── Native macOS (native/) ──────────────────────────────────────────

native:                         ## Build native macOS app (debug)
	@echo "==> Building native macOS app..."
	cd native && swift build

native-release:                 ## Build native macOS app (release)
	@echo "==> Building native macOS app (release)..."
	cd native && swift build -c release

native-test:                    ## Run native macOS tests
	@echo "==> Running native tests..."
	cd native && swift test

native-clean:
	cd native && swift package clean

# ── Help ─────────────────────────────────────────────────────────────

help:                           ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
