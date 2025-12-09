# catalog
resource "vcd_catalog" "catalogx1" {
    name                = "test-deploy-catalog-x1"
    delete_force        = "true"
    delete_recursive    = "true"
}
resource "vcd_catalog_vapp_template" "ova" {
    catalog_id  = vcd_catalog.catalogx1.id
    name        = "test-deploy-ova-x1"
    description = "PhotonOS 4.0 GA"
    ova_path    = "./${var.ova}"
}
## vapp #1
# resource "vcd_vapp" "test-deploy-vapp-app" {
#     name        = "test-deploy-vapp-app"
# }
# ## vm #1
# resource "vcd_vapp_vm" "test-deploy-vm-app" {
#     vapp_name           = vcd_vapp.test-deploy-vapp-app.name
#     name                = "test-deploy-vm-app"
#     vapp_template_id    = vcd_catalog_vapp_template.ova.id
#     memory              = 384
#     cpus                = 1
#     accept_all_eulas    = "true"
#     depends_on          = [vcd_vapp.test-deploy-vapp-app]
#     customization {
#         enabled                     = "true"
#         allow_local_admin_password  = "true"
#         auto_generate_password      = "false"
#         admin_password              = "P@ssw0rd"
#     }
# }
# output "vm-name" {
#     value = vcd_vapp_vm.test-deploy-vm-app.name
# }


# # nsxt edge
# data "vcd_resource_list" "list_of_resources" {
#     name = "list_of_resources"
#     resource_type = "vcd_nsxt_edgegateway"
# }
# # Shows the list of resource types for VCD provider
# output "resource_list" {
#     value = data.vcd_resource_list.list_of_resources.list
# }

# nsxt edge
data "vcd_org_vdc" "my_vdc" {
    name = var.org_vdc
}
data "vcd_nsxt_edgegateway" "nsxt-edge" {
    name        = var.edge_name
    owner_id    = data.vcd_org_vdc.my_vdc.id
}

# nsxt networks
resource "vcd_network_routed_v2" "test-deploy-net-web" {
    name            = "test-deploy-net-web"
    edge_gateway_id = data.vcd_nsxt_edgegateway.nsxt-edge.id
    gateway         = var.gateway_web_ip
    prefix_length   = 24
    static_ip_pool {
        start_address   = var.server_web_ip
        end_address     = var.server_web_ip
    }
}

# nsxt port profiles
resource "vcd_nsxt_app_port_profile" "web-profile" {
    name        = "test-deploy-web-profile"
    scope       = "TENANT"
    context_id  = data.vcd_org_vdc.my_vdc.id
    app_port {
        protocol    = "TCP"
        port        = ["80"]
    }
}

resource "vcd_nsxt_nat_rule" "dnat" {
    edge_gateway_id     = data.vcd_nsxt_edgegateway.nsxt-edge.id
    name                = "test-deploy-dnat-rule"
    rule_type           = "DNAT"
    firewall_match      = "MATCH_EXTERNAL_ADDRESS"
    external_address    = data.vcd_nsxt_edgegateway.nsxt-edge.primary_ip
    dnat_external_port  = "80"
    internal_address    = var.server_web_ip
    app_port_profile_id = vcd_nsxt_app_port_profile.web-profile.id
    depends_on          = [vcd_nsxt_app_port_profile.web-profile]
}

# nsxt ipset
resource "vcd_nsxt_ip_set" "server_web_set" {
    edge_gateway_id = data.vcd_nsxt_edgegateway.nsxt-edge.id
    name            = "test-deploy-server-web-set"
    description     = var.server_web_ip
    ip_addresses    = [var.server_web_ip]
}
resource "vcd_nsxt_ip_set" "edge_ip_set" {
    edge_gateway_id = data.vcd_nsxt_edgegateway.nsxt-edge.id
    name            = "test-deploy-edge-ip-set"
    description     = data.vcd_nsxt_edgegateway.nsxt-edge.primary_ip
    ip_addresses    = [data.vcd_nsxt_edgegateway.nsxt-edge.primary_ip]
}

# nsxt firewall
resource "vcd_nsxt_firewall" "rules" {
    edge_gateway_id = data.vcd_nsxt_edgegateway.nsxt-edge.id
    depends_on      = [vcd_nsxt_ip_set.server_web_set]
    rule {
        action                  = "ALLOW"
        name                    = "test-deploy-web-from-internet"
        direction               = "IN_OUT"
        ip_protocol             = "IPV4"
        destination_ids         = [vcd_nsxt_ip_set.edge_ip_set.id]
        app_port_profile_ids    = [vcd_nsxt_app_port_profile.web-profile.id]
    }
}

# vapp
resource "vcd_vapp" "test-deploy-vapp-web" {
    name        = "test-deploy-vapp-web"
    depends_on  = [vcd_network_routed_v2.test-deploy-net-web]
}

# vapp networks
resource "vcd_vapp_org_network" "vapp_web_network" {
    vapp_name               = vcd_vapp.test-deploy-vapp-web.name
    org_network_name        = vcd_network_routed_v2.test-deploy-net-web.name
    depends_on              = [vcd_vapp.test-deploy-vapp-web]
    reboot_vapp_on_removal  = true
}

# vms
resource "vcd_vapp_vm" "test-deploy-vm-web" {
    vapp_name           = vcd_vapp.test-deploy-vapp-web.name
    name                = "test-deploy-vm-web"
    vapp_template_id    = vcd_catalog_vapp_template.ova.id
    memory              = 384
    cpus                = 1
    accept_all_eulas    = "true"
    depends_on          = [vcd_vapp.test-deploy-vapp-web, vcd_vapp_org_network.vapp_web_network]
    network {
        type                = "org"
        name                = vcd_network_routed_v2.test-deploy-net-web.name
        ip_allocation_mode  = "POOL"
        is_primary          = "true"
        connected           = "true"
    }
    customization {
        enabled                     = "true"
        allow_local_admin_password  = "true"
        auto_generate_password      = "false"
        admin_password              = "P@ssw0rd"
        initscript                  = "mkdir /tmp/node && cd /tmp/node && echo 'CSA-Lab WEB server on 80 port' > index.html && /bin/systemctl stop iptables && /usr/bin/python3 -m http.server 80 &"
    }
}

# output
output "web_address_for_check" {
    value = "http://${data.vcd_nsxt_edgegateway.nsxt-edge.primary_ip}"
}