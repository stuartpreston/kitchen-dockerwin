# kitchen-dockerwin

An experimental Test Kitchen driver that supports Windows Containers via Docker on a Windows workstation.

# Quickstart

You'll need a workstation (Windows 10, Windows Server 2016 or higher) with Docker for Windows installed, running and configured to be able to run Windows Containers, and a working ChefDK installation (alternatively Ruby + Devkit + Test Kitchen gem).

## Docker Configuration

Edit the configuration file (usually located at `C:\ProgramData\docker\config\daemon.json`) and replace the configuration with the following, (i.e. adding the "hosts" value):

```
{
  "registry-mirrors": [],
  "insecure-registries": [],
  "debug": true,
  "experimental": false,
  "hosts": ["tcp://0.0.0.0:2375"]
}
```
Restart Docker. You may wish to remove any previously-running images using `docker rm $(docker ps -a -q)`

Ensure that Docker is running in Windows Container mode (right click the Docker icon in the System Notification area > **Switch to Windows containers** to be sure).

## Install the gem (assumes Chef Workstation/Chef DK installation)

```
chef gem install kitchen-dockerwin
```

## Create base container image

Whilst you can use any compatible Windows Server image for your kernel, converge time will be improved if you can build your own image that adds the Chef Infra Client to the Windows Server Core image.

To build your own image, create a `Dockerfile` as follows:

```
FROM mcr.microsoft.com/windows/servercore:ltsc2019
RUN ["powershell.exe", "-executionpolicy unrestricted", "-noninteractive", "-command", ". { iwr -useb https://omnitruck.chef.io/install.ps1 } | iex; install; remove-item $env:TEMP\\*.msi -force"]
```

Example command line to build the Docker image:

```
PS> docker build . -t stuartpreston/chef-client:latest
```

## Example kitchen.yml

```yml
---
driver:
  name: dockerwin

provisioner:
  name: chef_zero
  product_name: chef
  install_strategy: skip
  chef_client_path: c:\opscode\chef\bin\chef-client.bat

verifier:
  name: inspec

platforms:
  - name: windows2019
    driver:
      image: stuartpreston/chef-client:latest
      skip_pull: true

suites:
  - name: default
```

# Troubleshooting

## "No such container"
```
>>>>>>     Failed to complete #verify action: [{"message":"No such container: f362e060cdc97feb4ff12ac22d072891558a80c93f207e31e8ccb9d7924fc6b4"}
] on default-windows2019
```
Probable cause: Stale state file. If the container has been killed and removed (check with `docker ps -a`), then remove the .kitchen/*.yml file and retry.

# Known Issues/Limitations

* No support for Linux Containers on Windows (yet!)
* Some Chef Infra Client features are unsupported when running in Windows Containers, such as resources that are dependent on the WMI stack (including WinRM)
* `kitchen destroy` (i.e. kill and remove container) can take in excess of 1 minute on Windows.

# License

Apache License 2.0

Copyright (c) 2019, Stuart Preston

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.