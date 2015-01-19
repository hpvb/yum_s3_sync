# YumS3Sync

Synchronize a Yum repository over HTTP to S3. This can be useful when you want to mirror Internet Yum repositories 'locally' or want to run the synchronization from within EC2 rather than pushing it from outsede.

There are two command line tools supplied:

* ``yums3sync`` - Synchronizes a single Yum repository to a bucket:/prefix
* ``yums3syncdir`` - Scan a directory of links for repositories then synchronize all of them to bucket:/prefix

YumS3sync is smart enough to only copy files changes between runs, and does almost nothing if nothing changed on the source end. 

Syncdir is effectively a wrapper around sync to make it a little easier to synchronize a large amount of repositories without having to know exactly which ones you're synchronizing. I use it to synchronize internal Yum repositories made by other developers to AWS without having to make configuration changes.

After the syncronization you can use the repository using Yum with an S3 plugin or configure a webserver to act as a proxy between S3 and Yum. One of these two options is required if you do not want to make your S3 bucket internet-readable.

## Installation

### Gem
```
gem install yum_s3_sync
```

### Manual
Clone this git repository and build a Gem. The program should work without additional dependencies on RHEL/Centos 6 with EPEL enabled. It is tested on Ruby 1.8.7 and 2.1

## Usage

### Yums3sync

```
Usage: yums3sync [options]
    -s, --source SOURCE              HTTP source URL
    -b, --bucket BUCKET              Target bucket name
    -p, --prefix PREFIX              Target bucket prefix
    -k, --keep                       Never overwrite exitant files
    -n, --dry-run                    Don't make any changes
```

Example usage:

```
# yums3sync --source http://mrepo.corporate.com/mrepo/rhel6/x86_64/epel6/ --bucket my-org-repository --prefix rhel6/x86_64/epel6
```

This will make the contents of the 'epel6' repository available under ``my-org-repository::/rhel6/x86_64/epel6``. Running the command again will copy only changes, if any.

### Yums3syncdir

```
Usage: yums3syncdir [options]
    -s, --source SOURCEDIR           HTTP source base URL
    -b, --bucket BUCKET              Target bucket name
    -p, --prefix PREFIX              Target bucket prefix
    -x, --exclude prefix1,prefix2    Exclude prefixes
    -k, --keep                       Never overwrite exitant files
    -n, --dry-run                    Don't make any changes
``` 

Example usage:

```
# yums3syncdir --source http://mrepo.corporate.com/mrepo/rhel6/x86_64/ --bucket my-org-repository --prefix rhel6/x86_64 --exclude disc1,iso
```

Assuming ``http://mrepo.corporate.com/mrepo/rhel6/x86_64/`` has an ``index.html`` listing other repositories this will synchronize all of them to ``my-org-repository:/rhel6/x86_64``


### Serving the repository

Serving the repository is easy with an Apache (or other) reverse proxy. We first configure the S3 bucket to only allow access from certain referrers. We will use this as a secret to authenticate our proxies to S3.

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:List*",
        "s3:Get*"
      ],
      "Resource": "arn:aws:s3:::my-org-repository/*",
      "Condition": {
        "StringEquals": {
          "aws:Referer": "MySecretString"
        }
      }
    }
  ]
}
```

Next we configure Apache to serve up the repository through mod\_proxy.

```
<IfModule proxy_module>
  <IfModule proxy_http_module>
    <IfModule headers_module>
      ProxyRequests off
      ProxyErrorOverride On

      # We use '/mrepo/' to match our internal repositories.
      <LocationMatch "/mrepo/">
        ProxyPass http://my-org-repository.s3-eu-west-1.amazonaws.com/

        Header set Cache-Control "max-age=300, public"
        RequestHeader set Referer MySecretString
      </LocationMatch>


      ErrorLog logs/error_log
      LogLevel warn

      # Don't log our secret in our logfiles
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{User-Agent}i\"" proxylogger
      CustomLog logs/access_log proxylogger
    </IfModule>
  </IfModule>
</IfModule>
```

Optionally add an ELB in front of a couple of these and serve!
