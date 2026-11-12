# policy/compose.rego – Policy-as-Code cho docker-compose.yml (namespace: compose)
# Chạy: conftest test docker-compose.yml -p policy/ -n compose
package compose

import rego.v1

services := object.get(input, "services", {})

# POL-02 [CIS Docker 5.4]: không chạy privileged
deny contains msg if {
	some name, svc in services
	svc.privileged == true
	msg := sprintf("POL-02 [CIS Docker 5.4]: service '%s' chạy privileged: true", [name])
}

# POL-02 [CIS Docker 5.3]: phải drop toàn bộ capability
deny contains msg if {
	some name, svc in services
	not "ALL" in object.get(svc, "cap_drop", [])
	msg := sprintf("POL-02 [CIS Docker 5.3]: service '%s' không có cap_drop: [ALL]", [name])
}

# POL-02 [CIS Docker 5.31]: không mount Docker socket
deny contains msg if {
	some name, svc in services
	some v in object.get(svc, "volumes", [])
	contains(sprintf("%v", [v]), "docker.sock")
	msg := sprintf("POL-02 [CIS Docker 5.31]: service '%s' mount Docker socket", [name])
}

# POL-03 [CIS Docker 5.8, GDPR Art.32]: cổng chỉ gắn vào loopback hoặc IP mạng lab
deny contains msg if {
	some name, svc in services
	some p in object.get(svc, "ports", [])
	port := sprintf("%v", [p])
	not bound_to_lab(port)
	msg := sprintf("POL-03 [CIS Docker 5.8]: service '%s' publish cổng '%s' ra mọi interface", [name, port])
}

bound_to_lab(port) if startswith(port, "127.0.0.1:")

bound_to_lab(port) if regex.match(`^192\.168\.1\.[0-9]+:`, port)

# POL-01 [PCI DSS 8.3, GDPR Art.32]: không ghi secret thẳng trong environment
deny contains msg if {
	some name, svc in services
	some k, v in object.get(svc, "environment", {})
	entry := env_entry(k, v)
	regex.match(`(?i)^[A-Z0-9_]*(PASSWORD|PASSWD|SECRET|TOKEN|API_KEY)[A-Z0-9_]*=.+`, entry)
	msg := sprintf("POL-01 [PCI DSS 8.3]: service '%s' khai báo secret trực tiếp trong environment", [name])
}

env_entry(k, v) := v if is_number(k)

env_entry(k, v) := sprintf("%s=%v", [k, v]) if is_string(k)

# POL-02 [CIS Docker 5.25]: nên bật no-new-privileges (cảnh báo)
warn contains msg if {
	some name, svc in services
	not "no-new-privileges:true" in object.get(svc, "security_opt", [])
	msg := sprintf("POL-02 [CIS Docker 5.25]: service '%s' chưa đặt no-new-privileges", [name])
}
