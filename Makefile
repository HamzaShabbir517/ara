# Copyright 2020 ETH Zurich and University of Bologna.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Author: Matheus Cavalcante, ETH Zurich

SHELL = /usr/bin/env bash
ROOT_DIR := $(patsubst %/,%, $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
ARA_DIR := $(shell git rev-parse --show-toplevel 2>/dev/null || echo $$MEMPOOL_DIR)

INSTALL_PREFIX      ?= install
INSTALL_DIR         ?= ${ROOT_DIR}/${INSTALL_PREFIX}
LLVM_INSTALL_DIR    ?= ${INSTALL_DIR}/riscv-llvm
ISA_SIM_INSTALL_DIR ?= ${INSTALL_DIR}/riscv-isa-sim
VERIL_INSTALL_DIR   ?= ${INSTALL_DIR}/verilator
VERIL_VERSION       ?= v4.106

CMAKE ?= cmake

# CC and CXX are Makefile default variables that are always defined in a Makefile. Hence, overwrite
# the variable if it is only defined by the Makefile (its origin in the Makefile's default).
ifeq ($(origin CC),default)
CC     = gcc
endif
ifeq ($(origin CXX),default)
CXX    = g++
endif

# Default target
all: toolchain riscv-isa-sim verilator

# Toolchain
.PHONY: toolchain toolchain-main toolchain-newlib toolchain-rt
toolchain: toolchain-main toolchain-newlib toolchain-rt

toolchain-main: Makefile
	mkdir -p $(LLVM_INSTALL_DIR)
	cd $(ROOT_DIR)/toolchain/riscv-llvm && rm -rf build && mkdir -p build && cd build && \
	$(CMAKE) -G Ninja  \
	-DCMAKE_INSTALL_PREFIX=$(LLVM_INSTALL_DIR) \
	-DLLVM_ENABLE_PROJECTS="clang;lld" \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_C_COMPILER=$(CC) \
	-DCMAKE_CXX_COMPILER=$(CXX) \
	-DLLVM_DEFAULT_TARGET_TRIPLE=riscv64-unknown-elf \
	-DLLVM_TARGETS_TO_BUILD="RISCV" \
	../llvm
	cd $(ROOT_DIR)/toolchain/riscv-llvm && \
	$(CMAKE) --build build --target install

toolchain-newlib: Makefile toolchain
	cd ${ROOT_DIR}/toolchain/newlib && rm -rf build && mkdir -p build && cd build && \
	./configure --prefix=${LLVM_INSTALL_DIR} \
	--target=riscv64-unknown-elf \
	CC_FOR_TARGET="${LLVM_INSTALL_DIR}/bin/clang -march=rv64gc -mabi=lp64d -mno-relax" \
	AS_FOR_TARGET=${LLVM_INSTALL_DIR}/bin/llvm-as \
	LD_FOR_TARGET=${LLVM_INSTALL_DIR}/bin/llvm-ld \
	RANLIB_FOR_TARGET=${LLVM_INSTALL_DIR}/bin/llvm-ranlib && \
	make && \
	make install

toolchain-rt: Makefile toolchain toolchain-newlib
	cd $(ROOT_DIR)/toolchain/riscv-llvm/compiler-rt && rm -rf build && mkdir -p build && cd build && \
	$(CMAKE) $(ROOT_DIR)/toolchain/riscv-llvm/compiler-rt -G Ninja \
	-DCMAKE_INSTALL_PREFIX=$(LLVM_INSTALL_DIR) \
	-DCMAKE_C_COMPILER_TARGET="riscv64-unknown-elf" \
	-DCMAKE_ASM_COMPILER_TARGET="riscv64-unknown-elf" \
	-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
	-DCOMPILER_RT_BAREMETAL_BUILD=ON \
	-DCOMPILER_RT_BUILD_BUILTINS=ON \
	-DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
	-DCOMPILER_RT_BUILD_MEMPROF=OFF \
	-DCOMPILER_RT_BUILD_PROFILE=OFF \
	-DCOMPILER_RT_BUILD_SANITIZERS=OFF \
	-DCOMPILER_RT_BUILD_XRAY=OFF \
	-DCMAKE_C_COMPILER_WORKS=1 \
	-DCMAKE_CXX_COMPILER_WORKS=1 \
	-DCMAKE_SIZEOF_VOID_P=4 \
	-DCMAKE_C_COMPILER="$(LLVM_INSTALL_DIR)/bin/clang" \
	-DCMAKE_C_FLAGS="-march=rv64gc -mabi=lp64d -mno-relax" \
	-DCMAKE_ASM_FLAGS="-march=rv64gc -mabi=lp64d -mno-relax" \
	-DCMAKE_AR=$(LLVM_INSTALL_DIR)/bin/llvm-ar \
	-DCMAKE_NM=$(LLVM_INSTALL_DIR)/bin/llvm-nm \
	-DCMAKE_RANLIB=$(LLVM_INSTALL_DIR)/bin/llvm-ranlib \
	-DLLVM_CONFIG_PATH=$(LLVM_INSTALL_DIR)/bin/llvm-config
	cd $(ROOT_DIR)/toolchain/riscv-llvm/compiler-rt && \
	$(CMAKE) --build build --target install && \
	ln -s $(LLVM_INSTALL_DIR)/lib/linux $(LLVM_INSTALL_DIR)/lib/clang/13.0.0/lib

# Spike
.PHONY: riscv-isa-sim
riscv-isa-sim: ${ISA_SIM_INSTALL_DIR}

${ISA_SIM_INSTALL_DIR}: Makefile
	# There are linking issues with the standard libraries when using newer CC/CXX versions to compile Spike.
	# Therefore, here we resort to older versions of the compilers.
	cd toolchain/riscv-isa-sim && mkdir -p build && cd build; \
	[ -d dtc ] || git clone git://git.kernel.org/pub/scm/utils/dtc/dtc.git && cd dtc; \
	make install SETUP_PREFIX=$(ISA_SIM_INSTALL_DIR) PREFIX=$(ISA_SIM_INSTALL_DIR) && \
	PATH=$(ISA_SIM_INSTALL_DIR)/bin:$$PATH; cd ..; \
	../configure --prefix=$(ISA_SIM_INSTALL_DIR) && make -j4 && make install

# Verilator
.PHONY: verilator
verilator: ${VERIL_INSTALL_DIR}

${VERIL_INSTALL_DIR}: Makefile
	# Checkout the right version
	cd $(CURDIR)/toolchain/verilator && git reset --hard && git fetch && git checkout ${VERIL_VERSION}
	# Compile verilator
	cd $(CURDIR)/toolchain/verilator && git clean -xfdf && autoconf && \
	./configure --prefix=$(VERIL_INSTALL_DIR) && make -j4 && make install

# RISC-V Tests
riscv_tests:
	make -C apps -j4 riscv_tests && \
	make -C hardware riscv_tests_simc

# Helper targets
.PHONY: clean

clean:
	rm -rf $(INSTALL_DIR)
