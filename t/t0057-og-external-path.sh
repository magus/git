#!/bin/sh

test_description='og caller PATH for external Git commands'

. ./test-lib.sh

test_expect_success !MINGW 'set up external and Git program directories' '
	mkdir user-bin git-core &&
	cp "$TEST_DIRECTORY/t0057/path-probe.sh" user-bin/git-path-probe &&
	cp "$TEST_DIRECTORY/t0057/path-probe.sh" user-bin/git &&
	cp "$TEST_DIRECTORY/t0057/path-probe.sh" git-core/git &&
	chmod +x user-bin/git-path-probe user-bin/git git-core/git &&
	caller_path="$TRASH_DIRECTORY/user-bin:$PATH" &&
	git_program_path="$TRASH_DIRECTORY/git-core"
'

test_expect_success !MINGW 'external command receives the caller PATH when requested' '
	cat >expect <<-EOF &&
	program=$TRASH_DIRECTORY/user-bin/git-path-probe
	PATH=$git_program_path:$caller_path
	GIT_EXEC_PATH=$git_program_path
	OG_RESTORE_EXTERNAL_PATH=unset
	git=$git_program_path/git
	EOF
	(
		sane_unset OG_RESTORE_EXTERNAL_PATH &&
		GIT_EXEC_PATH="$git_program_path" PATH="$caller_path" \
			"$GIT_BUILD_DIR/git" path-probe
	) >actual &&
	test_cmp expect actual &&

	cat >expect <<-EOF &&
	program=$TRASH_DIRECTORY/user-bin/git-path-probe
	PATH=$caller_path
	GIT_EXEC_PATH=$git_program_path
	OG_RESTORE_EXTERNAL_PATH=unset
	git=$TRASH_DIRECTORY/user-bin/git
	EOF
	OG_RESTORE_EXTERNAL_PATH=1 GIT_EXEC_PATH="$git_program_path" PATH="$caller_path" \
		"$GIT_BUILD_DIR/git" path-probe >actual &&
	test_cmp expect actual
'

test_expect_success !MINGW 'Git program directory keeps precedence and its PATH' '
	cp user-bin/git-path-probe git-core/git-path-probe &&
	test_when_finished "rm -f git-core/git-path-probe" &&
	cat >expect <<-EOF &&
	program=$git_program_path/git-path-probe
	PATH=$git_program_path:$caller_path
	GIT_EXEC_PATH=$git_program_path
	OG_RESTORE_EXTERNAL_PATH=unset
	git=$git_program_path/git
	EOF
	OG_RESTORE_EXTERNAL_PATH=1 GIT_EXEC_PATH="$git_program_path" PATH="$caller_path" \
		"$GIT_BUILD_DIR/git" path-probe >actual &&
	test_cmp expect actual
'

test_expect_success !MINGW 'alias exec-path change keeps the original Git program PATH' '
	cp user-bin/git-path-probe git-core/git-path-probe &&
	test_when_finished "rm -f git-core/git-path-probe" &&
	new_git_program_path="$TRASH_DIRECTORY/new-git-core" &&
	alias_value="--exec-path=\"$new_git_program_path\" path-probe" &&
	cat >expect <<-EOF &&
	program=$git_program_path/git-path-probe
	PATH=$git_program_path:$caller_path
	GIT_EXEC_PATH=$new_git_program_path
	OG_RESTORE_EXTERNAL_PATH=unset
	git=$git_program_path/git
	EOF
	OG_RESTORE_EXTERNAL_PATH=1 GIT_EXEC_PATH="$git_program_path" PATH="$caller_path" \
		"$GIT_BUILD_DIR/git" -c "alias.path-alias=$alias_value" path-alias >actual &&
	test_cmp expect actual
'

test_expect_success !MINGW 'alias exec-path change does not hide an external command' '
	new_git_program_path="$TRASH_DIRECTORY/new-git-core" &&
	mkdir "$new_git_program_path" &&
	cp user-bin/git-path-probe "$new_git_program_path/git-path-probe" &&
	alias_value="--exec-path=\"$new_git_program_path\" path-probe" &&
	cat >expect <<-EOF &&
	program=$TRASH_DIRECTORY/user-bin/git-path-probe
	PATH=$caller_path
	GIT_EXEC_PATH=$new_git_program_path
	OG_RESTORE_EXTERNAL_PATH=unset
	git=$TRASH_DIRECTORY/user-bin/git
	EOF
	OG_RESTORE_EXTERNAL_PATH=1 GIT_EXEC_PATH="$git_program_path" PATH="$caller_path" \
		"$GIT_BUILD_DIR/git" -c "alias.path-alias=$alias_value" path-alias >actual &&
	test_cmp expect actual
'

test_expect_success !MINGW 'shell aliases and hooks keep their current environment' '
	cp user-bin/git-path-probe .git/hooks/pre-commit &&
	for command in alias hook
	do
		case "$command" in
		alias)
			set -- -c alias.path-alias=!./user-bin/git-path-probe path-alias
			;;
		hook)
			set -- hook run pre-commit
			;;
		esac &&
		(
			sane_unset OG_RESTORE_EXTERNAL_PATH &&
			GIT_EXEC_PATH="$git_program_path" PATH="$caller_path" \
				"$GIT_BUILD_DIR/git" "$@"
		) >expect &&
		OG_RESTORE_EXTERNAL_PATH=1 GIT_EXEC_PATH="$git_program_path" PATH="$caller_path" \
			"$GIT_BUILD_DIR/git" "$@" >actual &&
		test_cmp expect actual || return 1
	done
'

test_done
