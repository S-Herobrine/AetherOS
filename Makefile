# AetherOS Unified Edition Build Automation Makefile
# Minimum Requirements: 128 MB RAM, 1 GB Storage

SHELL := /bin/bash
PROJECT_NAME := AetherOS
VERSION := 1.0
ARCH := amd64
OUTPUT_DIR := build/output
ISO_NAME := $(PROJECT_NAME)-$(VERSION)-Standard-$(ARCH).iso

.PHONY: all clean install-deps build test help

all: help

help:
	@echo "=================================================================="
	@echo "            AetherOS Unified OS Build System                      "
	@echo "         Minimum: 128 MB RAM | 1 GB Storage                       "
	@echo "=================================================================="
	@echo "Available build targets:"
	@echo "  make install-deps    - Install build tools (debootstrap, xorriso, etc.)"
	@echo "  make build           - Build Unified AetherOS ISO (~20 mins)"
	@echo "  make test            - Launch QEMU web test with multi-core acceleration"
	@echo "  make clean           - Remove temporary build chroots and caches"
	@echo "=================================================================="

install-deps:
	@echo "==> Installing build dependencies..."
	sudo apt update && sudo apt install -y \
		live-build debootstrap xorriso squashfs-tools \
		mtools dosfstools grub-pc-bin grub-efi-amd64-bin \
		isolinux syslinux-utils git make curl wget gnupg zram-tools zstd

build:
	@echo "==> Building AetherOS Unified Edition ISO..."
	sudo bash build/build-iso-standard.sh

test:
	@echo "==> Testing AetherOS in QEMU Web Bridge..."
	bash scripts/test-web-iso.sh

clean:
	@echo "==> Cleaning temporary build directories..."
	sudo rm -rf /tmp/aetheros-build-*
	rm -rf $(OUTPUT_DIR)/*
	@echo "==> Clean complete."
