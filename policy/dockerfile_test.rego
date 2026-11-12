# policy/dockerfile_test.rego – unit test cho policy Dockerfile (conftest verify -p policy/)
package dockerfile

import rego.v1

test_deny_missing_user if {
	msgs := deny with input as [{"Cmd": "from", "Value": ["node:22"]}]
	count(msgs) > 0
}

test_deny_root_user if {
	msgs := deny with input as [{"Cmd": "from", "Value": ["node:22"]}, {"Cmd": "user", "Value": ["root"]}]
	some msg in msgs
	contains(msg, "root")
}

test_deny_secret_in_env if {
	msgs := deny with input as [
		{"Cmd": "from", "Value": ["node:22"]},
		{"Cmd": "env", "Value": ["DB_PASSWORD", "abc"]},
		{"Cmd": "user", "Value": ["65532"]},
	]
	some msg in msgs
	contains(msg, "secret")
}

test_allow_non_root if {
	msgs := deny with input as [{"Cmd": "from", "Value": ["node:22"]}, {"Cmd": "user", "Value": ["65532"]}]
	count(msgs) == 0
}
