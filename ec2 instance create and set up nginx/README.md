Playbook for ansible to create EC2:

1. VPC
2. internet gateway
3. vpc subnet
4. security group
5. instances

You can set you vars in create/vars/main.yml:

* prod_name #this add tags to resources
* region
* EC2_instance_type
* EC2_image # image OS
* set up your firewall
* set how much instances you need to create

In future playbook will deploy and setup nginx.
