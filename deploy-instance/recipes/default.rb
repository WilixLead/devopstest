#
# Cookbook Name:: test
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
package 'apache2' do
  action :remove
end

execute 'SET REDIRECT from 80 to 8000' do
  user 'root'
  command '-t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8000'
end

execute 'SET REDIRECT REWERSE from 80 to 8000' do
  user 'root'
  command '-t nat -I OUTPUT -p tcp -d 127.0.0.1 --dport 80 -j REDIRECT --to-ports 8000'
end

execute 'Save firewall settings' do
  user 'root'
  command 'iptables-save'
end

execute 'Enable forwarding' do
  user 'root'
  command 'echo 1 > /proc/sys/net/ipv4/ip_forward'
end

execute 'Save forwarding' do
  user 'root'
  command 'sysctl -w net.ipv4.ip_forward=1'
end

