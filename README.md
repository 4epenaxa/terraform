# ansible - Sberuniversity

Task 01 - playbook

Task 02.01 - roles

Task 02.02 - templates

Task 02.03 - blocks, tags

# terraform

terraform for cloud.ru

Задача:

    1. развернуть в VPC две виртуальные машины. 1 и 2 без доступа в интернет;
    2. создать NAT-шлюз и предоставить VM1 доступ в интернет через него;
    3. развернуть на VM1 сервер nginx и опубликовать его в интернет с помощью NAT-шлюза;
    4. развернуть на VM2 сервер nginx и опубликовать веб-серверы с VM1 и VM2 в интернет с помощью ELB(Elastic Load Balancer).


# Terraform - VMware

tfvars:

vcd_url = "https://vcd30-02.cloud.ru/api"
org_name = "CSA-student-15-4oRDHMJNBB"
org_vdc = "CSA-student-15-VDC01"
edge_name = "CSA-student-15-VDC01-EDGE01"

vcd_storage_policy = "Gold"
ova = "photon-hw11-4.0-1526e30ba0x.ova"