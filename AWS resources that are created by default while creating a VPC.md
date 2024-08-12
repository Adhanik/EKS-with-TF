
When you create a VPC in AWS, several default resources are automatically created along with it to ensure basic functionality. Here's a list of the key AWS resources that are created by default:

### 1. **Main Route Table**
   - **Description**: A default route table is created for the VPC, known as the "main" route table. This table is automatically associated with all subnets in the VPC unless you explicitly associate a subnet with another route table.
   - **Functionality**: It manages routing for traffic within the VPC and to/from external networks like the internet.

### 2. **Default Network ACL (Access Control List)**
   - **Description**: A default network ACL is created for the VPC. This is a stateless firewall that controls inbound and outbound traffic at the subnet level.
   - **Rules**: By default, it allows all inbound and outbound traffic.

### 3. **Default Security Group**
   - **Description**: A default security group is created for the VPC. This is a stateful firewall that controls inbound and outbound traffic at the instance level.
   - **Rules**: By default, it allows all outbound traffic and inbound traffic from other instances within the same security group.

### 4. **Default DHCP Option Set**
   - **Description**: A DHCP (Dynamic Host Configuration Protocol) option set is created by default. This specifies options for DNS servers, NTP servers, etc., that instances use when they are launched in the VPC.
   - **Default Values**: Usually, it includes the default domain name (`ec2.internal` for instances) and Amazon-provided DNS servers.

### 5. **Default VPC Peering Connection** (Only in the Default VPC, not in custom VPCs)
   - **Description**: For the default VPC that AWS automatically creates in each region, there's implicit connectivity between instances in different subnets through the default VPC peering.

### 6. **Internet Gateway** (Not automatically created in a custom VPC)
   - **Description**: If you're creating a custom VPC (not the default VPC), an Internet Gateway is not automatically created. You need to create and attach it manually if needed.

### 7. **Network Interface (ENI) for DNS Resolution**
   - **Description**: When a VPC is created, AWS automatically provides the capability for DNS resolution through a VPC resolver, which is accessible via a specific ENI in each subnet.

### Summary of Default Resources in a Custom VPC:
- **Main Route Table**
- **Default Network ACL**
- **Default Security Group**
- **Default DHCP Option Set**
- **Network Interface (ENI) for DNS Resolution**

These resources are essential for basic networking and security operations within the VPC, and they provide a foundation for further customization and configuration of your AWS environment.