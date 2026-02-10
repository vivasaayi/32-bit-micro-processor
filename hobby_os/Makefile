KERNEL_DIR := kernel
BUILD_DIR := build
PROGRAMS_DIR := programs
OUT_DIR := out
IMAGE := $(KERNEL_DIR)/target/x86_64-unknown-none/debug/bootimage-aruvix_hobby_os.bin

.PHONY: help image run run-headless virtualbox programs test-terminal test-programs test clean

help:
	@echo "Targets:"
	@echo "  make image         - build bootable HobbyOS image"
	@echo "  make run           - launch QEMU with graphics + serial"
	@echo "  make run-headless  - launch QEMU in terminal-only mode"
	@echo "  make virtualbox    - print VDI conversion command"
	@echo "  make programs      - compile sample C/ASM host-side utilities"
	@echo "  make test-terminal - run serial shell smoke test in QEMU"
	@echo "  make test-programs - validate sample C/ASM programs compile"
	@echo "  make test          - run all tests"
	@echo "  make clean         - remove artifacts"

image:
	$(MAKE) -C $(BUILD_DIR) image

run: image
	qemu-system-x86_64 -drive format=raw,file=$(IMAGE) -serial stdio

run-headless: image
	qemu-system-x86_64 -drive format=raw,file=$(IMAGE) -nographic -serial stdio -monitor none -display none

virtualbox: image
	@echo "VBoxManage convertfromraw $(IMAGE) hobby_os.vdi --format VDI"

programs:
	@mkdir -p $(OUT_DIR)
	@gcc $(PROGRAMS_DIR)/c/hello_util.c -o $(OUT_DIR)/hello_util
	@gcc $(PROGRAMS_DIR)/c/sum_util.c -o $(OUT_DIR)/sum_util
	@as $(PROGRAMS_DIR)/asm/noop_util.s -o $(OUT_DIR)/noop_util.o
	@echo "Built sample programs in $(OUT_DIR)/"

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

clean:
	$(MAKE) -C $(BUILD_DIR) clean
	@rm -rf $(OUT_DIR)
