
# How to build the instances with Terraform

First I will have to create a `GCP-account.json` file and fill it with you GCP connection info like project_id, client_id, private_key... this can also be achievable with a better option which is generating directly this file form the GCP IAM console. the json file is being called in the `provider.tf` in order for terraform to use its info to access my GCP account.

Then I will place the files below in a directory, cd to it and run `terraform init` this will prepare the directory as a terraform directory and will download the GCP pluging that terraform uses.

```
provider.tf
vars.tf
main.tf
```

Once done, I go ahead and run `terraform apply` and I issue a `yes` when prompted and set back and let terraform do its magic! 

# How am I going to proceed to set up Chef?

After spinning out the compute instances with Terraform, I will start by installing chef server and chef workstation. 
Then I will make the workstation machine able to communicate with chef server (the easiest way) so that I can use knife 
command to talk with the server.

Once done, the next step will be to bootstrap the linux and windows nodes, this means install the chef-client agent in
the node in a fashionable and remote way so that they'll turn to be manageable by chef server.

Only after this is done, I will start writing some basic recipes and apply them to the nodes to feel and witness the 
magic of using Chef!

I will try to make a better guide with screenshots later when I'll get more time. For now I hope this helps.

## 1- Chef Server installation

##### server prerequisites: set a hostname and fqdn
`$ sudo hostnamectl set-hostname chef-server.example.com --static`

##### add an entry for the new hostname to /etc/hosts
`[chef-server_IP] chef-server.example.com chef-server`

##### restart network service
`$ sudo systemctl restart network`

##### server installation: I'll be using version 13.0.17-1, other versions are available at https://downloads.chef.io
```
$ sudo yum install -y wget
$ sudo wget https://packages.chef.io/files/stable/chef-server/13.0.17/el/7/chef-server-core-13.0.17-1.el7.x86_64.rpm
$ sudo rpm -ivh chef-server-core-13.0.17-1.el7.x86_64.rpm
```
##### initial configuration
`$ sudo chef-server-ctl reconfigure`

##### creation of organisation and admin user
```
$ sudo mkdir chef
$ sudo chef-server-ctl user-create chefadmin badr chakkouri badr.chakkouri@gmail.com 'password' --filename ~/chef/chefadmin.pem
$ sudo chef-server-ctl org-create badrdevops "BadrDevOps" --association_user chefadmin --filename ~/chef/BadrDevOps.pem
```
##### install chef manage (chef server GUI)
```
$ sudo chef-server-ctl install chef-manage
$ sudo chef-server-ctl reconfigure
$ sudo chef-manage-ctl reconfigure
```
##### the chef manage is accessible at https://chef-server/organization/[the_org_name]

## Chef Workstation installation

##### for workstation installation, I'll be using version 0.9.42-1, other versions are available at https://downloads.chef.io
```
$sudo yum install -y wget
$ sudo wget https://packages.chef.io/files/stable/chef-workstation/0.9.42/el/7/chef-workstation-0.9.42-1.el7.x86_64.rpm
$ sudo rpm -ivh chef-workstation-0.9.42-1.el7.x86_64.rpm
```
##### after installing the chef workstation it's time to link it thr chef server
##### go to https://chef-server/organizations/[the_org_name]/getting_started and download the starter kit and accept the warning
##### upload and unzip te starter kit zip file
##### the starter kit comes with the config file for the knife command knife.rb
##### the connection can be established by fetching the SSL certificates generated at the download of the 
```
$ cd ~/chef-repo
$ sudo knife ssl fetch
```
##### the command below will show the org name as [the_org_name]-validator and it will mean that the connection to the server has been established.
`$ sudo knife client list`

## Chef nodes bootstrapping

##### nodes bootstrapping meaning linking the nodes to the server in other terms installing the chef-client and its configuration
##### for Linux nodes:
##### I need first to have SSH user pass authentication enabled, this is achievable by enabling it in /etc/ssh/sshd_config and restarting sshd

`$ knife bootstrap [node_IP] -N [node_name] -x username -P password --sudo`

##### for windows nodes:
##### I need winrm to be enabled and chef workstation and chef server to be added to winrm trusted hosts and ports 5985/5986 to be allowed
##### I'll use powershell to enable winrm with: Enable-PSRemoting cmdlet
##### Then I'll edit the trusted hosts: Set-Item WSMan:\localhost\Client\TrustedHosts [chef-server], [chef-workstation]
##### Then I'll restart winrm with Restart-Service winrm

`$ knife bootstrap -o winrm [node_IP] -N [node_name] -U windows_user -P windows_user_pass`

## Chef usage logic, generating cookbooks, writing recipes and applying them

##### I first generate a new cookbook: cd to chef-repo/cookbooks,then
`$ chef generate cookbook cookbook_name`

##### to write the recipe, I cd to chef-repo/cookbooks/cookbook_name/recipe and modify the default.rb file as in the example below

##### for linux,
##### I'll go with an example of installing nginx and replacing the default index.html file. 
##### My custom index.html is created under chef-repo/cookbooks/cookbook_name/files and chef will use it to replace the default index.html 

```
#first I install the package nginx
    package 'nginx' do
        action : install
    end
#then I enable and start the service nginx
    service 'nginx' do
        action [ :enable, :start ]
    end
#My custom index.html is created under chef-repo/cookbooks/cookbook_name/files and chef will use it to replace the default one using the code below
    cookbook_file '/var/www/html/index.html' do
        source 'index.html'
        mode '0777'
    end
```

##### for windows, 
##### I'll go as simple as creating a file with simple content

```
file 'c:\\users\\badr_chakkouri\\desktop\\test.txt' do
    content 'hello world!'
    action :create
end
```

##### Then I will write a recipe and upload the cookbook to chefserver: cd cookbook_name/recipe and write the recipe in default.rb, then
`$ knife upload .`

##### I will then add the uploaded cookbook to a node run_list
`$ knife node run_list add node_name "recipe[recipe_name]"`

##### Here's how to apply run_list to a windows node:
`$ knife winrm 'name:windows-node' 'chef-client' -x user_name -P user_password`

##### Here's how to apply run_list to a linux node:
`$knife ssh 'name:linux-node' 'sudo chef-client' -x user_name -P user_password`
