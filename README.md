# kitchen-dockerwin

An experimental Test Kitchen driver that supports Windows-based via Docker on a Windows workstation

**NOTE: `kitchen verify` is not yet supported when using this tool with InSpec.**

# Quickstart

You'll need an environment with Docker for Windows installed, running and configured to run Windows Containers, and a working ChefDK installation (alternatively Ruby + Devkit + Test Kitchen gem).

## Install the gem

```
gem install kitchen-dockerwin
```

If you are installing inside a Chef Workstation installation:

```
chef gem install kitchen-dockerwin
```

## Dockerfile

Whilst not necessary, the example shown assumes you have created your own Docker image with Chef Client inside, this will dramatically speed up the testing process because the Chef Client will not need to be installed each time.

An example `Dockerfile` follows:

```
FROM mcr.microsoft.com/windows/servercore:ltsc2019
RUN ["powershell", "-executionpolicy unrestricted", "-noninteractive", "-command", ". { iwr -useb https://omnitruck.chef.io/install.ps1 } | iex; install;"]
```

Example command line to build image:

```
PS> docker build -t stuartpreston/chef-client:15
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

transport:
  name: dockercli

verifier:
  name: dummy

platforms:
  - name: windows2019
    driver:
      image: stuartpreston/chef-client:15
      skip_pull: true

suites:
  - name: default
```

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