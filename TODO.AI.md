# TODO

Pre-existing `script-lint` violations found while linting an unrelated
diff (2026-09-04, casjay-base/centos AUDIT.AI.md #25 companion commit).
None of these are in code touched by that commit — logged here rather
than fixed inline to keep that commit's diff scoped to its actual change.

## scripts/min.sh

- [ ] Rename internal functions to the required `__` prefix: `devnull`,
      `port_in_use`, `system_service_exists`, `system_service_active`,
      `system_service_enable`, `system_service_disable`, `does_user_exist`,
      `does_group_exist`, `test_pkg`, `remove_pkg`, `install_pkg`,
      `detect_selinux`, `disable_selinux`, `get_user_ssh_key`,
      `run_init_check` (rename definition + every call site for each)
- [ ] Add `--` before the grep query at lines 526, 548, 890
- [ ] Split lines exceeding 180 chars: 187, 259, 702, 986, 1306, 1307
- [ ] Bare `return` with no code at line 448 — use `return 0`/`1`/`"$?"`
- [ ] Bare `exit` with no code at line 1706 — use `exit 0`/`1`/`"$?"`

## scripts/server.sh

- [ ] Rename internal functions to the required `__` prefix: `port_in_use`,
      `system_service_exists`, `system_service_active`,
      `system_service_enable`, `system_service_disable`, `does_user_exist`,
      `does_group_exist`, `test_pkg`, `remove_pkg`, `install_pkg`,
      `detect_selinux`, `disable_selinux`, `get_user_ssh_key`,
      `run_init_check`, `grab_remote_file` (rename definition + every call
      site for each)
- [ ] Add `--` before the grep query at lines 54, 81 (x2), 88, 135, 304,
      399, 400, 455, 474, 903
- [ ] Split lines exceeding 180 chars: 142, 208, 574, 848, 907, 908, 919,
      992, 1127, 1128
- [ ] Bare `return` with no code at line 384 — use `return 0`/`1`/`"$?"`
- [ ] Bare `exit` with no code at line 1468 — use `exit 0`/`1`/`"$?"`

## Pre-existing `script-lint` violations found 2026-09-09 (fail2ban
jail.local conditional-enable companion commit)

Broader `grep` missing-`--` sweep found by the same script-lint agent;
supersedes the narrower line lists above for this category (the two new
occurrences this commit introduced were fixed inline, not logged here).

- [ ] scripts/min.sh: add `--` before the grep query at lines 155, 161,
      228, 230–236, 329, 367, 474–490 (and other matches — re-run
      `script-lint` for the full current list before fixing)
- [ ] scripts/server.sh: add `--` before the grep query at lines 98, 104,
      144, 155–167, 181, 183–189, 193, 240 (and other matches — re-run
      `script-lint` for the full current list before fixing)
