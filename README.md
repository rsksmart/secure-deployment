# secure deployment

## Requirements

* Ubuntu with:

  * gnupg >= 2.2.19
  * curl
  * git
  * docker

* Authenticated GitHub user with read permissions into the repositories and a ssh access configured for that account.

## Usage

### Install

`./deploy.sh -P PROJECT_NAME -a install`


### Update

`./deploy.sh -a update`


## Future versions

For future versions this script should give protection against downgrade of commits tagging an old commit.
