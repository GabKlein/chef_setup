#!/bin/bash

#echo "deb http://apt.opscode.com/ `lsb_release -cs`-0.10 main" | tee /etc/apt/sources.list.d/opscode.list
#mkdir -p /etc/apt/trusted.gpg.d
#gpg --keyserver keys.gnupg.net --recv-keys 83EF826A
#gpg --export packages@opscode.com | sudo tee /etc/apt/trusted.gpg.d/opscode-keyring.gpg > /dev/null
#apt-get update
#apt-get install opscode-keyring -y
#apt-get upgrade -y
#sudo apt-get install chef chef-server -y
#!/bin/bash -x

rabbitmqctl add_vhost /chef
rabbitmqctl add_user chef changeme
rabbitmqctl set_permissions -p /chef chef ".*" ".*" ".*"
cd /home/ubuntu
su - ubuntu -c "mkdir -p ~/.chef"
su - ubuntu -c "sudo cp /etc/chef/validation.pem /etc/chef/webui.pem ~/.chef"
su - ubuntu -c "sudo chown -R ubuntu ~/.chef"
su - ubuntu -c "knife configure -i" <<EOF

http://localhost:4000


/home/ubuntu/.chef/webui.pem

/home/ubuntu/.chef/validation.pem

EOF

dns_public=`ec2metadata --public-hostname`

su - ubuntu -c "knife client delete ip-10-117-79-4.ec2.internal -y"
su - ubuntu -c "sudo knife client create -a -n -f /etc/chef/client.pem `hostname -f`"
sed -e "s/^chef_server_url.*/chef_server_url\ \"http:\/\/$dns_public\:4000\"/g" /etc/chef/client.rb > /etc/chef/client.rb.tmp && mv /etc/chef/client.rb.tmp /etc/chef/client.rb

/etc/init.d/chef-server restart
/etc/init.d/chef-server-webui restart

su - ubuntu -c "mkdir /tmp/.chef"
su - ubuntu -c "mkdir /tmp/.chef/cookbooks"
su - ubuntu -c "cd /tmp/.chef/cookbooks && git init && touch test && git add test && git commit -m 'first commit'"
su - ubuntu -c "knife client create my-username -n -a -f /tmp/.chef/my-username.pem"
su - ubuntu -c "cat > /tmp/.chef/knife.rb" <<EOF
log_level                :info
log_location             STDOUT
node_name                'my-username'
client_key               '~/.chef/my-username.pem'
validation_client_name   'chef-validator'
validation_key           '/etc/chef/validation.pem'
chef_server_url          'http://$dns_public:4000'
cache_type               'BasicFile'
cache_options( :path => '~/.chef/checksums' )
cookbook_path			 ['.chef/cookbooks/']
EOF
su - ubuntu -c "cd /tmp && tar czvf /home/ubuntu/chef-cleint-config.tar.gz .chef"
rm -rf /tmp/.chef

