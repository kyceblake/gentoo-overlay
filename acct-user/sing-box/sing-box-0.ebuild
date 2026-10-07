# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
EAPI=8
inherit acct-user
DESCRIPTION="sing-box service user"
ACCT_USER_ID=-1
ACCT_USER_GROUPS=( sing-box )
ACCT_USER_HOME=/var/lib/sing-box
ACCT_USER_HOME_PERMS=0750
acct-user_add_deps
