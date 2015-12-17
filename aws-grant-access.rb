#!/usr/bin/env ruby

# Licensed under the Apache License, Version 2.0 (the "License").

require 'rubygems'
require 'dotenv'
Dotenv.load

require 'aws-sdk'
require 'ipaddress'

require 'pry'

if ARGV.length != 1
  puts "Usage:-"
  puts "  ruby aws-grant-access.rb <security_group_name>"
  exit
end

group_name = ARGV.join

def revoke_ingress(ec2_client, sg_id, port, cidr_ip)
  ec2_client.revoke_security_group_ingress(
      group_id: sg_id,
      ip_permissions: [
          {
              ip_protocol: 'tcp',
              from_port: port,
              to_port: port,
              ip_ranges: [
                  {
                      cidr_ip: cidr_ip
                  }
              ]
          }
      ]
  )
end

def authorize_ingress(ec2_client, sg_id, port, cidr_ip)
  ec2_client.authorize_security_group_ingress(
      group_id: sg_id,
      ip_permissions: [
          {
              ip_protocol: 'tcp',
              from_port: port,
              to_port: port,
              ip_ranges: [
                  {
                      cidr_ip: cidr_ip
                  }
              ]
          }
      ]
  )
end

ec2_client = Aws::EC2::Client.new

group_results = ec2_client.describe_security_groups({
  group_names: [group_name]
})

security_group = group_results.security_groups.first
security_group.ip_permissions.each do |permission|
  next if not permission.from_port == 22 && permission.to_port == 22

  old_ip = permission.ip_ranges.first.cidr_ip
  new_ip = `curl -s http://ipecho.net/plain`

  if IPAddress.valid?(new_ip)
    revoke_ingress(ec2_client, security_group.group_id, 22, permission.ip_ranges.first.cidr_ip)
    authorize_ingress(ec2_client, security_group.group_id, 22, "#{new_ip}/32")
    puts "Updated!"
  else
    puts "Update failed!"
  end
end
