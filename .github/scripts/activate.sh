#!/usr/bin/env bash

# Copyright (C) 2020-2022 F4PGA Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

set -e

F4PGA_FAM=${F4PGA_FAM:=xc7}

case "$F4PGA_FAM" in
  xc7) F4PGA_DIR_ROOT='install';;
  eos-s3) F4PGA_DIR_ROOT='quicklogic-arch-defs';;
esac

export PATH="$F4PGA_INSTALL_DIR/$F4PGA_FAM/$F4PGA_DIR_ROOT/bin:$PATH"
source "$F4PGA_INSTALL_DIR/$F4PGA_FAM/conda/etc/profile.d/conda.sh"

conda activate $F4PGA_FAM
