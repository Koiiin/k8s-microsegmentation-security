\# Command History



\## Rancher Server



```bash

docker run -d --restart=unless-stopped \\

&#x20; --name rancher \\

&#x20; --privileged \\

&#x20; -p 80:80 \\

&#x20; -p 443:443 \\

&#x20; -v /opt/rancher:/var/lib/rancher \\

&#x20; -e CATTLE\_BOOTSTRAP\_PASSWORD='REDACTED' \\

&#x20; rancher/rancher:stable

