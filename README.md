# sama-infra

Terraform of Sama stack

```
infra/ -> cloud infrastructure, e.g. VPCs, RDS, ALBs, etc
sama-service/ -> deployment of sama-service, i.e. ASGs and Target Groups
monitorig/ -> prometheus + grafana 
bastion/ -> bastion EC2 instance
logging/ -> Cloudwatch logging configuration
```

### Deployment

```
make dev-deploy-{green|blue}
```