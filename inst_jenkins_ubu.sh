#!/bin/bash
# cloud-init script to install Jenkins on a EC2 Ubuntu instance, this will expose the
# Jenkins server on it's public IP on port 80
apt-get update
apt-get install python-software-properties -y
add-apt-repository ppa:openjdk-r/ppa -y
apt-get update && apt-get install openjdk-7-jdk -y
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
echo 'deb https://pkg.jenkins.io/debian-stable binary/' | tee -a /etc/apt/sources.list
apt-get update && apt-get install jenkins -y
apt autoremove -y
systemctl start jenkins
apt-get install apache2 -y
a2enmod proxy
a2enmod proxy_http
cat <<EOF > /etc/apache2/sites-available/jenkins.conf
<Virtualhost *:80>
    ServerName        $(curl http://169.254.169.254/latest/meta-data/local-hostname)
    ProxyRequests     Off
    ProxyPreserveHost On
    AllowEncodedSlashes NoDecode

    <Proxy http://localhost:8080/*>
      Order deny,allow
      Allow from all
    </Proxy>

    ProxyPass         /  http://localhost:8080/ nocanon
    ProxyPassReverse  /  http://localhost:8080/
    ProxyPassReverse  /  http://$(curl http://169.254.169.254/latest/meta-data/public-ipv4)/
</Virtualhost>
EOF
rm /etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/default-ssl.conf
echo "" >  /etc/apache2/sites-enabled/000-default.conf
a2ensite jenkins
systemctl restart apache2
systemctl restart jenkins
echo "======================"
echo "Initial Admin Password is: $(cat /var/lib/jenkins/secrets/initialAdminPassword)"
echo "======================"
