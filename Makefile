.PHONY: help install update clean test lint backup doctor

# Default target
help:
	@echo "Dotfiles Management Commands:"
	@echo "  make install   - Install dotfiles and dependencies"
	@echo "  make update    - Update dependencies and plugins" 
	@echo "  make clean     - Remove broken symlinks and temp files"
	@echo "  make test      - Run tests on dotfiles"
	@echo "  make lint      - Lint shell scripts"
	@echo "  make backup    - Backup existing dotfiles"
	@echo "  make doctor    - Check system for issues"

# Install dotfiles
install:
	@echo "Installing dotfiles..."
	@chmod +x script/bootstrap
	@./script/bootstrap

# Update all dependencies
update:
	@echo "Updating dependencies..."
	@# Update Oh My Zsh
	@if [ -d "$$HOME/.oh-my-zsh" ]; then \
		echo "Updating Oh My Zsh..."; \
		cd "$$HOME/.oh-my-zsh" && git pull; \
	fi
	@# Update Vim plugins
	@echo "Updating Vim plugins..."
	@vim +PlugUpdate +qall
	@# Update npm packages
	@echo "Updating global npm packages..."
	@npm update -g
	@# Update Composer packages
	@echo "Updating Composer packages..."
	@composer global update
	@echo "Update complete!"

# Clean broken symlinks and temp files
clean:
	@echo "Cleaning up..."
	@# Find and remove broken symlinks in home directory
	@find ~ -maxdepth 1 -type l ! -exec test -e {} \; -print -delete 2>/dev/null || true
	@# Clean vim temp files
	@find ~/.vim -name "*.swp" -delete 2>/dev/null || true
	@find ~/.vim -name "*.swo" -delete 2>/dev/null || true
	@echo "Cleanup complete!"

# Test dotfiles
test: lint
	@echo "Running tests..."
	@# Check for required commands
	@command -v git >/dev/null 2>&1 || { echo "git is not installed"; exit 1; }
	@command -v zsh >/dev/null 2>&1 || { echo "zsh is not installed"; exit 1; }
	@command -v vim >/dev/null 2>&1 || { echo "vim is not installed"; exit 1; }
	@# Test zsh configuration
	@echo "Testing zsh configuration..."
	@zsh -n zsh/zshrc.symlink || { echo "zsh configuration has syntax errors"; exit 1; }
	@echo "All tests passed!"

# Lint shell scripts
lint:
	@echo "Linting shell scripts..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		find . -name "*.sh" -exec shellcheck {} \; ; \
		shellcheck script/bootstrap || true; \
	else \
		echo "shellcheck not installed. Install with: brew install shellcheck"; \
	fi

# Backup existing dotfiles
backup:
	@echo "Backing up existing dotfiles..."
	@mkdir -p ~/.dotfiles_backup_$$(date +%Y%m%d_%H%M%S)
	@for file in ~/.zshrc ~/.vimrc ~/.tmux.conf ~/.gitconfig; do \
		if [ -f "$$file" ]; then \
			cp "$$file" ~/.dotfiles_backup_$$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || true; \
		fi \
	done
	@echo "Backup complete in ~/.dotfiles_backup_$$(date +%Y%m%d_%H%M%S)"

# Check system for common issues
doctor:
	@echo "Running dotfiles doctor..."
	@echo ""
	@echo "=== System Information ==="
	@echo "OS: $$(uname -s)"
	@echo "Shell: $$SHELL"
	@echo ""
	@echo "=== Checking Dependencies ==="
	@# Check required tools
	@for cmd in git zsh vim tmux ag; do \
		if command -v $$cmd >/dev/null 2>&1; then \
			printf "✓ %-10s %s\n" "$$cmd" "$$($$cmd --version 2>&1 | head -1)"; \
		else \
			printf "✗ %-10s not installed\n" "$$cmd"; \
		fi \
	done
	@echo ""
	@echo "=== Checking Symlinks ==="
	@# Check if symlinks are properly set up
	@for link in ~/.zshrc ~/.vimrc ~/.tmux.conf ~/.gitconfig; do \
		if [ -L "$$link" ]; then \
			printf "✓ %-20s -> %s\n" "$$link" "$$(readlink $$link)"; \
		else \
			printf "✗ %-20s not a symlink\n" "$$link"; \
		fi \
	done
	@echo ""
	@echo "=== Checking Plugin Managers ==="
	@# Check vim-plug
	@if [ -f ~/.vim/autoload/plug.vim ]; then \
		echo "✓ vim-plug installed"; \
	else \
		echo "✗ vim-plug not installed"; \
	fi
	@# Check Oh My Zsh
	@if [ -d ~/.oh-my-zsh ]; then \
		echo "✓ Oh My Zsh installed"; \
	else \
		echo "✗ Oh My Zsh not installed"; \
	fi

# Make scripts executable
permissions:
	@chmod +x script/bootstrap
	@chmod +x bin/*.sh
	@echo "Permissions updated!"