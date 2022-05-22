# Deploy

Build and deploy a Phoenix application via SSH to a remote system.

## Installation

```
mix archive.install github faheetah/mix_deploy
```

## Usage

Specify the project name (under mix.exs -> project -> app) and a remote host:path to deploy to using the following syntax:

```
mix deploy NAME TARGET_HOST:TARGET_PATH
```

For example, to deploy a project called "myapp" to 192.0.2.11 under /srv/myapp/, where the application is called with /srv/myapp/bin/myapp:

```
mix deploy myapp 192.0.2.11.com:/srv/myapp/
``
