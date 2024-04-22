# Your challenge

You need to create the appropriate security configuration for Jeff's site. Your first challenge is to set up firewall rules and virtual machine tags. You also need to ensure that SSH is only available to the bastion via IAP.

For the firewall rules, make sure that:

The bastion host does not have a public IP address.
You can only SSH to the bastion and only via IAP.
You can only SSH to juice-shop via the bastion.
Only HTTP is open to the world for juice-shop.
Tips and tricks:

Pay close attention to the network tags and the associated VPC firewall rules.
Be specific and limit the size of the VPC firewall rule source ranges.
Overly permissive permissions will not be marked correct.

Suggested order of action.

1. Check the firewall rules. Remove the overly permissive rules.
2. Navigate to Compute Engine in the Cloud console and identify the bastion host. The instance should be stopped. Start the instance.
3. The bastion host is the one machine authorized to receive external SSH traffic. Create a firewall rule that allows SSH (tcp/22) from the IAP service. The firewall rule must be enabled for the bastion host instance using a network tag of SSH IAP network tag.
4. The juice-shop server serves HTTP traffic. Create a firewall rule that allows traffic on HTTP (tcp/80) to any address. The firewall rule must be enabled for the juice-shop instance using a network tag of HTTP network tag.
5. You need to connect to juice-shop from the bastion using SSH. Create a firewall rule that allows traffic on SSH (tcp/22) from acme-mgmt-subnet network address. The firewall rule must be enabled for the juice-shop instance using a network tag of SSH internal network tag.
6. In the Compute Engine instances page, click the SSH button for the bastion host. Once connected, SSH to juice-shop.
