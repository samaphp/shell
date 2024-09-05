#!/bin/bash
# some checks on the server after migration to a new data center to make sure everything is working as expected

check_apache() {
    response_80=$(curl -s http://localhost:80)
    response_443=$(curl -s https://localhost:443 --insecure)

    if [[ "$response_80" == *"Apache"* && "$response_443" == *"Apache"* ]]; then
        echo "[OK] Apache and all applications are working as expected."
    else
        echo "[ERROR] Apache or one of the applications is not responding as expected."
    fi
}

# Function to check MySQL service and check for a specific database
# you should have this user before migration for test.
# CREATE USER check_test@localhost IDENTIFIED BY 'check_test';
# GRANT SELECT, SHOW VIEW ON check_test.* TO check_test@localhost IDENTIFIED BY 'check_test';
check_mysql() {
    if systemctl status mysql | grep -q "active (running)"; then
        db_exists=$(mysql -ucheck_test -pcheck_test -e "SHOW DATABASES LIKE 'check_test';" | grep "check_test")
        if echo "$db_exists" | grep -q "check_test"; then
            echo "[OK] MySQL service is working as expected."
        else
            echo "[ERROR] Can not connect to the targeted database."
        fi
    else
        echo "[ERROR] MySQL service is not running."
    fi
}

check_mailhog8025() {
    response=$(curl -s http://mailhog.example.com:8025)
    if [[ "$response" == *"MailHog"* ]]; then
        echo "[OK] mailhog.example.com:8025 Local SMTP server connection is good."
    else
        echo "[ERROR] mailhog.example.com:8025 Unable to connect to Local SMTP server or MailHog is not running."
    fi
}

check_mailhog1025() {
    telnet_output=$(timeout 3 telnet mailhog.example.com 1025 2>&1)
    if echo "$telnet_output" | grep -q "Connected"; then
        echo "[OK] mailhog.example.com:1025 Telnet successfully connected on port 1025."
    else
        echo "[ERROR] Unable to connect to mailhog.example.com on port 1025 using Telnet."
    fi
}

check_python_services() {
    response=$(curl -s -X POST http://pythonservices:8081/service1 --data '{}')
    if echo "$response" | grep -q "hello"; then
        echo "[OK] pythonservices:8081 working as expected."
    else
        echo "[ERROR] pythonservices:8081 did not work as expected."
    fi
}

check_python2_services() {
    response=$(curl -s http://python2services/service4 --request GET --header 'Content-Type: application/json' --data '{"username":"test", "email":"test"}')
    if echo "$response" | grep -q "full_name"; then
        echo "[OK] python2services reachable as expected."
    else
        echo "[ERROR] python2services did not work as expected."
    fi
}

check_ssh_connection_gitlab() {
    if nc -zv git.example.com 22 2>&1 | grep -q "succeeded"; then
        echo "[OK] SSH connection to git.example.com on port 22 is successful."
    else
        echo "[ERROR] Unable to connect to git.example.com on port 22 via SSH."
    fi
}

check_gateway_connection() {
    response=$(curl -s -k -L https://gw.example.com)
    if echo "$response" | grep -q "Route Not Found"; then
        echo "[OK] gw.example.com reachable as expected."
    else
        echo "[ERROR] gw.example.com did not work as expected."
    fi
}

check_disk_space() {
    available_space=$(df -BG / | grep '/' | awk '{print $4}' | sed 's/G//')
    if [[ $available_space -ge 200 ]]; then
        echo "[OK] Sufficient disk space available: ${available_space}G."
    else
        echo "[ERROR] Insufficient disk space: ${available_space}G available, 200G required."
    fi
}

check_cpu_count() {
    cpu_count=$(nproc)
    if [[ $cpu_count -ge 32 ]]; then
        echo "[OK] CPU count is sufficient: $cpu_count vCPUs."
    else
        echo "[ERROR] Insufficient CPU count: $cpu_count vCPUs, 32 or more required."
    fi
}

check_memory() {
    total_mem=$(free -m | awk '/^Mem:/{print $2}')
    total_mem_gb=$((total_mem / 1024))
    if [[ $total_mem_gb -ge 32 ]]; then
        echo "[OK] Sufficient memory: ${total_mem_gb}GB."
    else
        echo "[ERROR] Insufficient memory: ${total_mem_gb}GB, 32GB or more required."
    fi
}

list_open_ports() {
    open_ports=$(ss -tuln | awk 'NR>1 {print $5}' | sed -E 's/.*:([0-9]+)/\1/' | sort -n | uniq | paste -sd ',' -)
    open_ports_count=$(ss -tuln | awk 'NR>1 {print $5}' | sed -E 's/.*:([0-9]+)/\1/' | sort -n | uniq | wc -l)
    expected_ports="22,53,80,443,3306"
    expected_ports_count=$(echo "$expected_ports" | tr ',' '\n' | wc -l)
    echo "[INFO] Open ports --- ($open_ports_count): $open_ports"
    echo "[INFO] Expected ports ($expected_ports_count): $expected_ports"
}

# Run the checks
check_apache
check_mysql
check_mailhog8025
check_mailhog1025
check_python_services
check_python2_services
check_ssh_connection_gitlab
check_gateway_connection
check_disk_space
check_cpu_count
check_memory
list_open_ports
