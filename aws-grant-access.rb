#!/usr/bin/env ruby

# Licensed under the Apache License, Version 2.0 (the "License").

require 'rubygems'
require 'dotenv'
Dotenv.load

require 'aws-sdk'
require 'ipaddress'

if ARGV.length != 3
  puts "Usage:-"
  puts "  ruby aws-grant-access.rb <aws_region> <security_group_id> <ssh_port>"
  exit
end

region_name = ARGV[0]
group_id = ARGV[1]
ssh_port = ARGV[2].to_i

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

ec2_client = Aws::EC2::Client.new(region: region_name)

group_results = ec2_client.describe_security_groups({
  group_ids: [group_id]
})

security_group = group_results.security_groups.first
security_group.ip_permissions.each do |permission|
  next if not permission.from_port == ssh_port && permission.to_port == ssh_port

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
