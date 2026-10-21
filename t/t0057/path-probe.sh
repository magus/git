#!/bin/sh

printf 'program=%s\n' "$0"
printf 'PATH=%s\n' "${PATH-unset}"
printf 'GIT_EXEC_PATH=%s\n' "${GIT_EXEC_PATH-unset}"
printf 'OG_RESTORE_EXTERNAL_PATH=%s\n' "${OG_RESTORE_EXTERNAL_PATH-unset}"
printf 'git=%s\n' "$(command -v git)"
