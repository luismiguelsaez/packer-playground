
### Look for images ( CLI )
```
aws ec2 describe-images --region us-east-1 --filters \
  "Name=architecture,Values=x86_64" \
  "Name=name,Values=ubuntu/images/*ubuntu-*-18.04-amd64-server-*" \
  "Name=state,Values=available" \
  "Name=root-device-type,Values=ebs" \
  "Name=owner-id,Values=099720109477" \
  "Name=virtualization-type,Values=hvm"
```
