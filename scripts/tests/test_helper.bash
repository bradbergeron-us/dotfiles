# test_helper.bash — shared setup for the bats unit suite.
#
# Loaded by every scripts/tests/*.bats file via `load 'test_helper'`. Resolves
# the canonical directories the suite sources its code from so individual tests
# can reference $LIB_DIR / $SCRIPTS_DIR / $REPO_ROOT without recomputing paths.
# bats provides $BATS_TEST_DIRNAME (the directory of the running .bats file) and
# a per-test scratch dir in $BATS_TEST_TMPDIR (auto-created and auto-removed),
# which replaces the hand-rolled `mktemp -d` + EXIT-trap pattern of the old
# shell tests.
# shellcheck shell=bash
# shellcheck disable=SC2034  # exported paths are consumed by the .bats files

LIB_DIR="$(cd "${BATS_TEST_DIRNAME}/../lib" && pwd)"
SCRIPTS_DIR="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
