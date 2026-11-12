# policy/compose_test.rego – unit test cho policy compose (conftest verify -p policy/)
package compose

import rego.v1

test_deny_privileged if {
	msgs := deny with input as {"services": {"app": {"privileged": true, "cap_drop": ["ALL"]}}}
	some msg in msgs
	contains(msg, "privileged")
}

test_deny_public_port if {
	msgs := deny with input as {"services": {"db": {"ports": ["5432:5432"], "cap_drop": ["ALL"]}}}
	some msg in msgs
	contains(msg, "POL-03")
}

test_deny_inline_secret_list if {
	msgs := deny with input as {"services": {"app": {"cap_drop": ["ALL"], "environment": ["DB_PASSWORD=abc"]}}}
	some msg in msgs
	contains(msg, "POL-01")
}

test_deny_inline_secret_map if {
	msgs := deny with input as {"services": {"app": {"cap_drop": ["ALL"], "environment": {"API_KEY": "abc"}}}}
	some msg in msgs
	contains(msg, "POL-01")
}

test_deny_docker_socket if {
	msgs := deny with input as {"services": {"app": {"cap_drop": ["ALL"], "volumes": ["/var/run/docker.sock:/var/run/docker.sock"]}}}
	some msg in msgs
	contains(msg, "Docker socket")
}

test_allow_hardened_service if {
	msgs := deny with input as {"services": {"app": {
		"ports": ["127.0.0.1:3002:8080"],
		"cap_drop": ["ALL"],
		"security_opt": ["no-new-privileges:true"],
	}}}
	count(msgs) == 0
}
