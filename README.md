# useful-scripts

## aws-grant-access.rb

```
gem install dotenv
gem install aws-sdk
gem install ipaddress
```

Add .env into your folder.

```
AWS_ACCESS_KEY_ID='...'
AWS_SECRET_ACCESS_KEY='...'
AWS_REGION='...'
```

Start the script and update the IP for your SSH permission entry.

```
ruby aws-grant-access.rb <aws_region> <security_group_id> <ssh_port>
```
