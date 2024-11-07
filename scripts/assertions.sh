# This file is sourced in rather than executed a a top level script.
# Provides useful bash assertions.

function assertion_failed() {
  local msg="$1"
  echo "Assertion failed: ${msg}"
  echo "Aborting."
  exit 1
}

function assert_exists() {
  local path="$1"
  if [ ! -e "${path}" ]; then
    assertion_failed "${path} does not exist."
  fi
}

function assert_is_dir() {
  local path="$1"
  assert_exists "${path}"
  if [ ! -d "${path}" ]; then
    assertion_failed "${path} is not a dir."
  fi
}

function assert_is_file() {
  local path="$1"
  assert_exists "${path}"
  if [ ! -f "${path}" ]; then
    assertion_failed "${path} is not a file."
  fi
}

function assert_dir_empty() {
  local path="$1"
  assert_exists "${path}"
  if [ $(ls -A "${path}") ]; then
     assertion_failed "Dir ${path} is not empty."
  fi
}

function assert_executable() {
  local path="$1"
  assert_is_file "${path}"
  if [ ! -x "${path}" ]; then
     assertion_failed "File ${path} is not executable."
  fi 
}


