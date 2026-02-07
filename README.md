[0]
EKS / EC2 -> Fargate 단일 서비스
260207(토) 스타벅스 + 버스

-

[1]
설계
// main
- providers
- VPC
- subnets

- cloudwatch log
- EC2 cluster
- policy doc + role + role_policy_attachment

- SG

- task
- service

// variables.tf
- aws_region
- name
- image
- container_port
- cpu
- memory

-

[2] plate // 260207 // ㅁ메가커피
- VPC
- Subnet

-

[3] //
- cloudwatch
- ecs cluster

-

[4] // IAMROLE
- iampolicydoc
- iamrole
- iamrole policy attachment
