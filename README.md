# secure deployment

## Requirements

* Ubuntu with:

  * gnupg >= 2.2.19
  * curl
  * git
  * npm (only for the token bridge project)
  * docker

* Authenticated GitHub user with read permissions into the repositories and a ssh access configured for that account.

## Usage

`./deploy.sh -P PROJECT_NAME -d DESTINATION`

### Available project names

* rskj (used for testing, will be removed)
* powpeg-node-setup
* tokenbridge

## Future versions

For future versions this script should give protection against downgrade of commits tagging an old commit.
