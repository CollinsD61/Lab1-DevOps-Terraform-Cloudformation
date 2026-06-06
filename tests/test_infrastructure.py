import os
import boto3
import pytest

# Initialize boto3 clients
# It uses the default credentials configured in AWS CLI
ec2_client = boto3.client('ec2')

# Environment tag used to discover resources
ENV_TAG = os.environ.get('ENVIRONMENT_TAG', 'lab-devops')

@pytest.fixture(scope="module")
def vpc_info():
    """Finds and returns the VPC deployed for the lab."""
    response = ec2_client.describe_vpcs(
        Filters=[
            {'Name': 'tag:Environment', 'Values': [ENV_TAG]}
        ]
    )
    vpcs = response.get('Vpcs', [])
    assert len(vpcs) > 0, f"No VPC found with Environment tag: {ENV_TAG}"
    return vpcs[0]

@pytest.fixture(scope="module")
def subnets_info(vpc_info):
    """Retrieves all subnets associated with the VPC."""
    response = ec2_client.describe_subnets(
        Filters=[
            {'Name': 'vpc-id', 'Values': [vpc_info['VpcId']]}
        ]
    )
    return response.get('Subnets', [])

@pytest.fixture(scope="module")
def security_groups_info(vpc_info):
    """Retrieves all security groups in the VPC."""
    response = ec2_client.describe_security_groups(
        Filters=[
            {'Name': 'vpc-id', 'Values': [vpc_info['VpcId']]}
        ]
    )
    return response.get('SecurityGroups', [])

@pytest.fixture(scope="module")
def route_tables_info(vpc_info):
    """Retrieves all route tables associated with the VPC."""
    response = ec2_client.describe_route_tables(
        Filters=[
            {'Name': 'vpc-id', 'Values': [vpc_info['VpcId']]}
        ]
    )
    return response.get('RouteTables', [])

def test_vpc_exists_and_cidr(vpc_info):
    """Verify that the VPC exists and has the correct CIDR block (10.0.0.0/16)."""
    assert vpc_info['State'] == 'available', "VPC is not available"
    assert vpc_info['CidrBlock'] == '10.0.0.0/16', f"VPC CIDR is {vpc_info['CidrBlock']}, expected 10.0.0.0/16"
    
    # Check DNS support
    vpc_id = vpc_info['VpcId']
    dns_support = ec2_client.describe_vpc_attribute(VpcId=vpc_id, Attribute='enableDnsSupport')
    dns_hostnames = ec2_client.describe_vpc_attribute(VpcId=vpc_id, Attribute='enableDnsHostnames')
    assert dns_support['EnableDnsSupport']['Value'] is True, "DNS Support is disabled in VPC"
    assert dns_hostnames['EnableDnsHostnames']['Value'] is True, "DNS Hostnames is disabled in VPC"

def test_subnets_count_and_types(subnets_info):
    """Verify that we have at least one public and one private subnet."""
    assert len(subnets_info) >= 2, f"Expected at least 2 subnets, found {len(subnets_info)}"
    
    public_subnets = [s for s in subnets_info if s.get('MapPublicIpOnLaunch') == True]
    private_subnets = [s for s in subnets_info if s.get('MapPublicIpOnLaunch') == False]
    
    assert len(public_subnets) >= 1, "No public subnet found (MapPublicIpOnLaunch should be True)"
    assert len(private_subnets) >= 1, "No private subnet found (MapPublicIpOnLaunch should be False)"
    
    # Verify CIDR blocks
    public_cidrs = [s['CidrBlock'] for s in public_subnets]
    private_cidrs = [s['CidrBlock'] for s in private_subnets]
    
    assert '10.0.1.0/24' in public_cidrs, "Expected Public Subnet CIDR 10.0.1.0/24 not found"
    assert '10.0.2.0/24' in private_cidrs, "Expected Private Subnet CIDR 10.0.2.0/24 not found"

def test_internet_gateway_attached(vpc_info):
    """Verify that an Internet Gateway is attached to the VPC."""
    response = ec2_client.describe_internet_gateways(
        Filters=[
            {'Name': 'attachment.vpc-id', 'Values': [vpc_info['VpcId']]}
        ]
    )
    igws = response.get('InternetGateways', [])
    assert len(igws) == 1, f"Expected 1 Internet Gateway attached, found {len(igws)}"

def test_nat_gateway_deployed(vpc_info, subnets_info):
    """Verify that a NAT Gateway is deployed in the public subnet."""
    public_subnet_id = next(s['SubnetId'] for s in subnets_info if s.get('MapPublicIpOnLaunch') == True)
    
    response = ec2_client.describe_nat_gateways(
        Filters=[
            {'Name': 'vpc-id', 'Values': [vpc_info['VpcId']]},
            {'Name': 'subnet-id', 'Values': [public_subnet_id]}
        ]
    )
    nat_gws = response.get('NatGateways', [])
    active_nat_gws = [n for n in nat_gws if n['State'] in ['pending', 'available']]
    assert len(active_nat_gws) >= 1, "No active or pending NAT Gateway found in the public subnet"

def test_route_tables_routes(route_tables_info, subnets_info):
    """Verify routing: Public subnet routes to IGW, Private subnet routes to NAT GW."""
    public_subnet_id = next(s['SubnetId'] for s in subnets_info if s.get('MapPublicIpOnLaunch') == True)
    private_subnet_id = next(s['SubnetId'] for s in subnets_info if s.get('MapPublicIpOnLaunch') == False)
    
    public_rt_found = False
    private_rt_found = False
    
    for rt in route_tables_info:
        # Check associations
        associations = rt.get('Associations', [])
        subnet_ids = [assoc.get('SubnetId') for assoc in associations if assoc.get('SubnetId')]
        
        routes = rt.get('Routes', [])
        
        if public_subnet_id in subnet_ids:
            # Check route to Internet Gateway (igw-xxxxx)
            has_igw_route = any(route.get('GatewayId', '').startswith('igw-') for route in routes if route.get('DestinationCidrBlock') == '0.0.0.0/0')
            assert has_igw_route, "Public route table does not have a 0.0.0.0/0 route to an Internet Gateway"
            public_rt_found = True
            
        if private_subnet_id in subnet_ids:
            # Check route to NAT Gateway (nat-xxxxx)
            has_nat_route = any(route.get('NatGatewayId', '').startswith('nat-') for route in routes if route.get('DestinationCidrBlock') == '0.0.0.0/0')
            assert has_nat_route, "Private route table does not have a 0.0.0.0/0 route to a NAT Gateway"
            private_rt_found = True
            
    assert public_rt_found, "Route table for public subnet not found or not associated explicitly"
    assert private_rt_found, "Route table for private subnet not found or not associated explicitly"

def test_security_groups_ingress_rules(security_groups_info):
    """Verify security group rules match requirements."""
    public_sg = next((sg for sg in security_groups_info if 'public-ec2-sg' in sg['GroupName']), None)
    private_sg = next((sg for sg in security_groups_info if 'private-ec2-sg' in sg['GroupName']), None)
    
    assert public_sg is not None, "Public EC2 security group not found"
    assert private_sg is not None, "Private EC2 security group not found"
    
    # 1. Verify Public EC2 SG allows port 22
    public_ssh_allowed = False
    for rule in public_sg.get('IpPermissions', []):
        if rule.get('FromPort') == 22 and rule.get('ToPort') == 22 and rule.get('IpProtocol') == 'tcp':
            public_ssh_allowed = True
            # Confirm it's restricted (ideally we check cidr, but we just verify it exists here)
            assert len(rule.get('IpRanges', [])) > 0, "No IP ranges allowed for public SSH"
            
    assert public_ssh_allowed, "Public SG does not allow SSH (port 22) inbound"
    
    # 2. Verify Private EC2 SG allows SSH (port 22) ONLY from Public SG
    private_ssh_allowed_from_public_sg = False
    for rule in private_sg.get('IpPermissions', []):
        if rule.get('FromPort') == 22 and rule.get('ToPort') == 22 and rule.get('IpProtocol') == 'tcp':
            # Check if source is a security group and matches the public security group id
            user_groups = rule.get('UserIdGroupPairs', [])
            for pair in user_groups:
                if pair.get('GroupId') == public_sg['GroupId']:
                    private_ssh_allowed_from_public_sg = True
            # Confirm no general CIDR is allowed to SSH directly to private
            assert len(rule.get('IpRanges', [])) == 0, "Private SG permits SSH from direct IP ranges, violating security requirement!"
            
    assert private_ssh_allowed_from_public_sg, "Private SG does not restrict SSH inbound exclusively to the Public EC2 SG"

def test_ec2_instances_running(vpc_info, subnets_info):
    """Verify that Public and Private EC2 instances are created and running."""
    public_subnet_id = next(s['SubnetId'] for s in subnets_info if s.get('MapPublicIpOnLaunch') == True)
    private_subnet_id = next(s['SubnetId'] for s in subnets_info if s.get('MapPublicIpOnLaunch') == False)
    
    response = ec2_client.describe_instances(
        Filters=[
            {'Name': 'vpc-id', 'Values': [vpc_info['VpcId']]},
            {'Name': 'instance-state-name', 'Values': ['pending', 'running']}
        ]
    )
    
    reservations = response.get('Reservations', [])
    instances = []
    for res in reservations:
        instances.extend(res.get('Instances', []))
        
    assert len(instances) >= 2, f"Expected at least 2 instances, found {len(instances)}"
    
    public_inst = [i for i in instances if i['SubnetId'] == public_subnet_id]
    private_inst = [i for i in instances if i['SubnetId'] == private_subnet_id]
    
    assert len(public_inst) >= 1, "No running instance found in the Public Subnet"
    assert len(private_inst) >= 1, "No running instance found in the Private Subnet"
    
    # Verify public instance has public IP
    assert public_inst[0].get('PublicIpAddress') is not None, "Public instance does not have a Public IP"
    # Verify private instance does not have public IP
    assert private_inst[0].get('PublicIpAddress') is None, "Private instance incorrectly has a Public IP"
