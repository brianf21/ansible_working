#!/bin/bash
cat > /home/devops/ansible_working/inventory << EOF
rhs1.contoso.com
rhs2.contoso.com
dc.contoso.com
ms.contoso.com
10.0.0.2 ansible_host=dc.contoso.com
10.0.0.3 ansible_host=ms.contoso.com
10.0.0.4
10.0.0.5

[windows]
dc.contoso.com
ms.contoso.com
10.0.0.2
10.0.0.3

[linux]
rhs1.contoso.com
rhs2.contoso.com

[memberservers:children]
windows
linux

[group1]
fhost1.contoso.com
fhost2.contoso.com
fhost3.contoso.com
fhost4.contoso.com
fhost5.contoso.com

[group2]
fhost3.contoso.com
fhost4.contoso.com
fhost5.contoso.com
fhost6.contoso.com
fhost7.contoso.com
EOF

sudo bash -c "cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
127.0.0.1       rhs1.contoso.com rhs1
::1             rhs1.contoso.com rhs1
127.0.0.1       fhost1.contoso.com fhost1
127.0.0.1       fhost2.contoso.com fhost2
127.0.0.1       fhost3.contoso.com fhost3
127.0.0.1       fhost4.contoso.com fhost4
127.0.0.1       fhost5.contoso.com fhost5
127.0.0.1       fhost6.contoso.com fhost6
127.0.0.1       fhost7.contoso.com fhost7
EOF"

for i in $(seq 1 7); do ssh fhost$i.contoso.com -o StrictHostKeyChecking=accept-new -C hostname; done
for i in $(seq 1 7); do ssh fhost$i -o StrictHostKeyChecking=accept-new -C hostname; done

for i in $(seq 4 5); do ssh 10.0.0.$i -o StrictHostKeyChecking=accept-new -C hostname; done

sudo bash -c "cat > /etc/krb5.conf << EOF
# To opt out of the system crypto-policies configuration of krb5, remove the
# symlink at /etc/krb5.conf.d/crypto-policies which will not be recreated.
includedir /etc/krb5.conf.d/

[logging]
    default = FILE:/var/log/krb5libs.log
    kdc = FILE:/var/log/krb5kdc.log
    admin_server = FILE:/var/log/kadmind.log

[libdefaults]
    dns_lookup_realm = false
    ticket_lifetime = 24h
    renew_lifetime = 7d
    forwardable = true
    rdns = false
    pkinit_anchors = /etc/pki/tls/certs/ca-bundle.crt
    spake_preauth_groups = edwards25519
#    default_realm = EXAMPLE.COM
    default_realm = CONTOSO.COM
    default_ccache_name = KEYRING:persistent:%{uid}

[realms]
# EXAMPLE.COM = {
#     kdc = kerberos.example.com
#     admin_server = kerberos.example.com
# }

[domain_realm]
# .example.com = EXAMPLE.COM
# example.com = EXAMPLE.COM
.contoso.com = CONTOSO.COM
contoso.com = CONTOSO.COM
EOF"

cat > /home/devops/ansible_working/lab6_script1.yml << EOF
---
- name: Messing with host patterns
  hosts: '*'

  tasks:
    - name: Print out inventory hostname
      debug:
        msg: "{{ inventory_hostname }}"
...
EOF

cat > /home/devops/ansible_working/lab6_script2.yml << EOF
---
- name: Messing with host patterns
  hosts: '10.0.0.*'

  tasks:
    - name: Print out inventory hostname
      debug:
        msg: "{{ inventory_hostname }}"
...
EOF

cat > /home/devops/ansible_working/lab6_script3.yml << EOF
---
- name: Messing with host patterns
  hosts: 'fhost*'

  tasks:
    - name: Print out inventory hostname
      debug:
        msg: "{{ inventory_hostname }}"
...
EOF

cat > /home/devops/ansible_working/lab6_script4.yml << EOF
---
- name: Messing with host patterns
  hosts: group1,group2

  tasks:
    - name: Print out inventory hostname
      debug:
        msg: "{{ inventory_hostname }}"
...
EOF

cat > /home/devops/ansible_working/lab6_script5.yml << EOF
---
- name: Messing with host patterns
  hosts: group1,&group2

  tasks:
    - name: Print out inventory hostname
      debug:
        msg: "{{ inventory_hostname }}"
...
EOF

cat > /home/devops/ansible_working/lab6_script6.yml << EOF
---
- name: Messing with host patterns
  hosts: group1,!fhost1.contoso.com

  tasks:
    - name: Print out inventory hostname
      debug:
        msg: "{{ inventory_hostname }}"
...
EOF

cat > /home/devops/ansible_working/lab6_script7.yml << EOF
---
- name: Messing with host patterns
  hosts: group1,!group2

  tasks:
    - name: Print out inventory hostname
      debug:
        msg: "{{ inventory_hostname }}"
...
EOF

cat > /home/devops/ansible_working/lab6_script8.yml << EOF
---
- name: Cleanup server before running play
  import_playbook: lab6_script9.yml

- name: Setup web/database server
  hosts: rhs1.contoso.com,rhs2.contoso.com

  tasks:

    - name: Install or update required software
      yum:
        name:
          - firewalld
          - httpd
          - mariadb-server
          - php
          - php-mysqlnd
        state: latest
      notify: 
        - restart firewalld
        - restart httpd
        - restart mariadb

    - name: firewalld enabled and running
      service:
        name: firewalld
        enabled: true
        state: started

    - name: firewalld permits http service
      firewalld:
        zone: public
        service: http
        state: enabled
        permanent: true
        immediate: true

    - name: httpd enabled and running
      service:
        name: httpd
        enabled: true
        state: started

    - name: mariadb enabled and running
      service:
        name: mariadb
        enabled: true
        state: started

    - name: Push test index.html to server
      copy:
        src: files/index.html
        dest: /var/www/html/

  handlers:

    - name: restart firewalld
      service:
        name: firewalld
        state: restarted

    - name: restart httpd
      service:
        name: httpd
        state: restarted

    - name: restart mariadb
      service:
        name: mariadb
        state: restarted
...
EOF

cat > /home/devops/ansible_working/lab6_script9.yml << EOF
---
- name: Remove software for lab
  hosts: rhs1.contoso.com,rhs2.contoso.com

  tasks:

    - name: Remove software
      yum:
        name:
          - httpd
          - mariadb-server
          - php
          - php-mysqlnd
        state: absent
...
EOF

cat > /home/devops/ansible_working/lab6_script10.yml << EOF
---
- name: Cleanup server before running play
  import_playbook: lab6_script9.yml

- name: Setup web/database server
  hosts: rhs1.contoso.com,rhs2.contoso.com

  tasks:

    - name: Install or update required software
      yum:
        name:
          - firewalld
          - httpd
          - mariadb-server
          - php
          - php-mysqlnd
        state: latest
      notify: 
        - restart firewalld
        - restart httpd
        - restart mariadb
      tags:
        - fw
        - web
        - db

    - name: firewalld enabled and running
      service:
        name: firewalld
        enabled: true
        state: started
      tags: fw

    - name: firewalld permits http service
      firewalld:
        zone: public
        service: http
        state: enabled
        permanent: true
        immediate: true
      tags: fw

    - name: httpd enabled and running
      service:
        name: httpd
        enabled: true
        state: started
      tags: web

    - name: mariadb enabled and running
      service:
        name: mariadb
        enabled: true
        state: started
      tags: db

    - name: Push test index.html to server
      copy:
        src: files/index.html
        dest: /var/www/html/
      tags: web

    - include_tasks: lab6_script11.yml

  handlers:

    - name: restart firewalld
      service:
        name: firewalld
        state: restarted

    - name: restart httpd
      service:
        name: httpd
        state: restarted

    - name: restart mariadb
      service:
        name: mariadb
        state: restarted
...
EOF

cat > /home/devops/ansible_working/lab6_script11.yml << EOF
- action: uri url=http://{{ inventory_hostname }} return_content=yes
  register: webpage

- name: Show the web content
  debug:
    msg: "{{ webpage.content }}"

- fail:
    msg: 'Cannot get to the page'
  when: "'This is some web content' not in webpage.content"
EOF
