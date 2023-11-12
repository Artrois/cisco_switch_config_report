#!/bin/bash

# Create a CSV file to store the summary with "|" as the delimiter
csv_file="switch_summary.csv"
echo -e "Hostname,Is L3 Switch,Trunk Ports,Allowed VLANs,VLAN IPs,Standby IPs,Default Gateway" > "$csv_file"

# Loop through each file in the current directory with a ".txt" extension
for config_file in *-confg; do
    # Extract switch details from the configuration file
    hostname=$(grep "hostname" "$config_file" | awk '{print $2}')
    #ip_address=$(grep "ip address" "$config_file" | grep -v "no ip address" | awk '{print $3}' | tr '\n' '|')
    is_l3_switch=$(grep -q "ip routing" "$config_file" && echo "Yes" || echo "No")
    #is_routing_enabled=$(grep -q "routing" "$config_file" && echo "Yes" || echo "No")
    
    #trunk_ports=$(awk '/interface GigabitEthernet[0-9]+/ { intf=$2 } /switchport mode trunk/ { print intf }' "$config_file" | tr '\n' '|')
    trunk_ports=$(grep -A7 -E "interface (Gigabit|Fast)Ethernet[0-9]" "$config_file" | awk '/interface (Gigabit|Fast)Ethernet[0-9]+/ { intf=$2; is_shutdown=0 } /shutdown/ { is_shutdown=1 } /switchport mode trunk/ && !is_shutdown { print intf }' | tr '\n' '|')
    #allowed_vlans=$(awk '/interface GigabitEthernet[0-9]+/ { intf=$2 } /switchport trunk allowed vlan/ { print intf, $5 }' "$config_file" | tr '\n' '|')
    #allowed_vlans=$(grep -A7 "interface GigabitEthernet[0-9]" "$config_file" | awk '/interface GigabitEthernet[0-9]+/ { intf=$2; is_shutdown=0 } /shutdown/ { is_shutdown=1 } /switchport trunk allowed vlan/ && !is_shutdown { print intf, $5 }' | tr '\n' '|')
    allowed_vlans=$(grep -A7 -E "interface (Gigabit|Fast)Ethernet[0-9]" "$config_file" | awk '/interface (Gigabit|Fast)Ethernet[0-9]+/ { intf=$0; is_shutdown=0; allowed_vlans=""; for (i=1; i<=7; i++) { getline; if (/shutdown/) { is_shutdown=1; break } if (/switchport trunk allowed vlan/) { allowed_vlans=$5 } } if (!is_shutdown && allowed_vlans) print intf, allowed_vlans }' | tr '\n' '|')
    vlan_ips=$(grep -A7 "interface Vlan[0-9]" "$config_file" | awk '/interface Vlan[0-9]+/ && !/Loopback0/ { intf=$2 } /ip address/ && !/no ip address/ && !/shutdown/ { print intf, $3 }' | tr '\n' '|')
    #vlan_ips=$(grep -A7 "interface Vlan[0-9]" "$config_file" | awk '/interface Vlan[0-9]+/ && !/Loopback0/ { intf=$2; is_shutdown=0 } /shutdown/ { is_shutdown=1 } /ip address/ && !/no ip address/ && !is_shutdown { print intf, $3 }' | tr '\n' '|')
    standby_ips=$(awk '/interface Vlan[0-9]+/ { intf=$2 } /standby [0-9]+ ip/ { print intf, $4 }' "$config_file" | tr '\n' '|')
    default_gateway=$(awk '/ip default-gateway/ { print $3 }' "$config_file")

    # Print details to the console
    echo "Hostname: $hostname"
    #echo "IP Address: $ip_address"
    echo "Is L3 Switch: $is_l3_switch"
    #echo "Is Routing Enabled: $is_routing_enabled"
    echo "Trunk Ports: $trunk_ports"
    echo "Allowed VLANs: $allowed_vlans"
    echo "VLAN IPs: $vlan_ips"
    echo "Standby IPs: $standby_ips"
    echo "Default Gateway: $default_gateway"
    echo ""

    # Print details to the CSV file
    echo "$hostname,$is_l3_switch,$trunk_ports,\"$allowed_vlans\",\"$vlan_ips\",\"$standby_ips\",\"Gwy: $default_gateway\"" >> "$csv_file"
done
