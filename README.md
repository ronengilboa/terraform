# terraform
deploy 2 servers with tr to aws
Will create 2 vpc's with each one with subnet, route table, internet gateway, and security group.
the grafana server will also use an IAM role for monitoring AWS.
grafana is installed on ubuntu and wiki is AMI.
CloudWatch is installed using the grafana resource.
Dashboard is created using the grafana resource using a template to insert the right instance id to the dashboard.

