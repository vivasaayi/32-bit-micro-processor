KERNEL_DIR := kernel
BUILD_DIR := build
PROGRAMS_DIR := programs
OUT_DIR := out
IMAGE := $(KERNEL_DIR)/target/x86_64-unknown-none/debug/bootimage-aruvix_hobby_os.bin
PROGRAM_BUNDLE := $(OUT_DIR)/program_bundle

.PHONY: help image run run-headless virtualbox vdi programs bundle-programs test-terminal test-programs test readiness clean

help:
	@echo "Targets:"
	@echo "  make image           - build bootable HobbyOS image"
	@echo "  make run             - launch QEMU with graphics + serial"
	@echo "  make run-headless    - launch QEMU in terminal-only mode"
	@echo "  make virtualbox      - print VDI conversion command"
	@echo "  make vdi             - build image and create hobby_os.vdi via VBoxManage"
	@echo "  make programs        - compile sample C/ASM host-side utilities"
	@echo "  make bundle-programs - package sample programs into out/program_bundle/"
	@echo "  make test-terminal   - run serial shell smoke test in QEMU"
	@echo "  make test-programs   - validate sample C/ASM programs compile"
	@echo "  make test            - run all available tests"
	@echo "  make readiness       - print readiness notes for DOS-like goals"
	@echo "  make clean           - remove artifacts"

image:
	$(MAKE) -C $(BUILD_DIR) image

run: image
	qemu-system-x86_64 -drive format=raw,file=$(IMAGE) -serial stdio

run-headless: image
	qemu-system-x86_64 -drive format=raw,file=$(IMAGE) -nographic -serial stdio -monitor none -display none

virtualbox: image
	@echo "VBoxManage convertfromraw $(IMAGE) hobby_os.vdi --format VDI"

vdi: image
	@bash scripts/create_vdi.sh "$(IMAGE)" hobby_os.vdi

programs:
	@mkdir -p $(OUT_DIR)
	@gcc $(PROGRAMS_DIR)/c/hello_util.c -o $(OUT_DIR)/hello_util
	@gcc $(PROGRAMS_DIR)/c/sum_util.c -o $(OUT_DIR)/sum_util
	@as $(PROGRAMS_DIR)/asm/noop_util.s -o $(OUT_DIR)/noop_util.o
	@echo "Built sample programs in $(OUT_DIR)/"

bundle-programs: programs
	@mkdir -p $(PROGRAM_BUNDLE)
	@cp -f $(OUT_DIR)/hello_util $(PROGRAM_BUNDLE)/
	@cp -f $(OUT_DIR)/sum_util $(PROGRAM_BUNDLE)/
	@cp -f $(OUT_DIR)/noop_util.o $(PROGRAM_BUNDLE)/
	@printf "hello_util\nsum_util\nnoop_util.o\n" > $(PROGRAM_BUNDLE)/manifest.txt
	@echo "Program bundle created at $(PROGRAM_BUNDLE)/"

test-terminal: image
	@python3 scripts/test_terminal.py

test-programs:
	@mkdir -p $(OUT_DIR)
	@gcc -Wall -Wextra -Werror $(PROGRAMS_DIR)/c/hello_util.c -o $(OUT_DIR)/hello_util.test
	@gcc -Wall -Wextra -Werror $(PROGRAMS_DIR)/c/sum_util.c -o $(OUT_DIR)/sum_util.test
	@as $(PROGRAMS_DIR)/asm/noop_util.s -o $(OUT_DIR)/noop_util.test.o
	@./$(OUT_DIR)/sum_util.test 20 22 | grep -q '^42$$'
	@echo "Program build tests passed"

test: test-programs test-terminal

readiness:
	@cat docs/readiness.md

clean:
	$(MAKE) -C $(BUILD_DIR) clean
	@rm -rf $(OUT_DIR)
