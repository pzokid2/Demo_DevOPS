# policy/dockerfile.rego – Policy-as-Code cho Dockerfile (namespace: dockerfile)
# Chạy: conftest test Dockerfile --parser dockerfile -p policy/ -n dockerfile
package dockerfile

import rego.v1

# Lệnh USER cuối cùng là user lúc chạy container
runtime_users := [i | some i, ins in input; ins.Cmd == "user"]

last_user := input[max(runtime_users)].Value[0] if count(runtime_users) > 0

root_names := {"root", "0"}

# POL-02 / CIS Docker 4.1: phải có USER
deny contains msg if {
	count(runtime_users) == 0
	msg := "POL-02 [CIS Docker 4.1]: Dockerfile không có USER, container sẽ chạy bằng root"
}

# POL-02: USER cuối không được là root ("root", "0", "root:root", "0:0")
deny contains msg if {
	last_user
	split(last_user, ":")[0] in root_names
	msg := sprintf("POL-02 [CIS Docker 4.1]: USER cuối là '%s' (root)", [last_user])
}

# POL-01: không nhúng secret vào ENV/ARG
secret_pattern := `(?i)(password|passwd|secret|api[_-]?key|token)`

deny contains msg if {
	some ins in input
	ins.Cmd in {"env", "arg"}
	some v in ins.Value
	regex.match(secret_pattern, v)
	msg := sprintf("POL-01 [GDPR Art.32]: có thể có secret trong %s: %s", [upper(ins.Cmd), v])
}

# POL-03: không EXPOSE cổng quản trị/CSDL
admin_ports := {"22", "3306", "5432", "27017", "6379"}

deny contains msg if {
	some ins in input
	ins.Cmd == "expose"
	some p in ins.Value
	split(p, "/")[0] in admin_ports
	msg := sprintf("POL-03 [CIS Docker 5.8]: EXPOSE cổng quản trị/CSDL %s", [p])
}

# POL-04: không dùng :latest (cảnh báo)
warn contains msg if {
	some ins in input
	ins.Cmd == "from"
	endswith(ins.Value[0], ":latest")
	msg := sprintf("POL-04: base image '%s' dùng :latest", [ins.Value[0]])
}

# Khuyến nghị HEALTHCHECK (cảnh báo; image distroless không có shell nên là ngoại lệ đã biết)
warn contains msg if {
	not any_healthcheck
	msg := "CIS Docker 4.6: không có HEALTHCHECK (ngoại lệ đã biết với image distroless)"
}

any_healthcheck if {
	some ins in input
	ins.Cmd == "healthcheck"
}
