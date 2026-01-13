.PHONY: build clean venv

VENV_DIR := .venv
PYTHON := python3
NODE_VERSION := 22

# Create virtualenv and install dependencies
venv:
	@echo "Creating Python virtualenv..."
	$(PYTHON) -m venv $(VENV_DIR)
	@echo "Installing setuptools (provides distutils)..."
	$(VENV_DIR)/bin/pip install --upgrade pip setuptools

# Build electron app
build: venv
	@echo "Building electron app..."
	@. $(VENV_DIR)/bin/activate && \
		. ~/.nvm/nvm.sh && \
		nvm use $(NODE_VERSION) && \
		cd frontend && \
		yarn install && \
		yarn electron:build

# Clean build artifacts
clean:
	rm -rf $(VENV_DIR)
	rm -rf frontend/out
	rm -rf frontend/dist
	rm -rf frontend/.next
