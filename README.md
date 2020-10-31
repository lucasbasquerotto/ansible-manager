# (Under Construction) Controller Layer

This repository corresponds to the controller layer used to deploy projects.

You can see demos of deployments of projects [here](#). Those demos uses the [Controller Output Vars](#) that are generated by this layer, so that you can run those projects more easily.

The demos are great for what they are meant to be: demos, prototypes. They shouldn't be used for development (bad DX if you need real time changes without having to clone newer versions of repositories, you are unable to clone repositories in specific locations defined by you in the project folder). They also shouldn't be used in production environments due to bad security (the vault value used for decryption is `123456`, and changes to the [project environment repository](#) may be lost if you forget to push them).

The following instructions assume that they are being run from the parent folder of this repository, the `<root>` folder (the folder that will contain the data for all projects).

## Setup

The machine that will deploy the projects should have the following tools:

- Bash 4+

- Git

- A container engine (like [docker](https://www.docker.com/) or [podman](https://podman.io/))

To be able to deploy the projects, the controller will need to know which projects to deploy. That information is declared in the [main environment repository](#main-environment-repository). You can manually clone the repository with git at the folder `ctl/env-main` (or point a symlink located at `ctl/env-main` to another location on you machine) or run the following command that will do that for you:

```bash
./ctl/run setup
```

The above command will ask you to enter the repository which willl be cloned (`git clone <git_env_main_repository>`). An alternative is to enter the repository directly like the following:

```bash
./ctl/run setup <git_env_main_repository>
```

If you have a symlink at `ctl/env-main` pointing to an empty directory, the git repository will be cloned at that target repository.

To make things more practical, you can create a repository to become the root folder of your environment and then make an instruction that runs the entire setup step in a more straightforward way.

This [repository](#) does that, and you can fork it and change only the `env.sh` file, defining in it the controller repository and branch, your main environment repository, and optionally the location of this repository relatively to the root directory (a symlink will be created at `ctl/env-main`).

## Main Environment Repository

The main environemnt repository will be a hub containing information about the projects to deploy. It will be located at `ctl/env-main` and must have the following files:

- **Main Environment Options File**: `env.sh`

File that will be sourced during launch to know which container engine should run the projects nad also which image it will run. It also has other useful [options](#main-environment-options) and [examples](#main-environment-options-file---examples) explained below.

## Main Environment Options

| Option | Default | Description |
| ------ | ------- | ----------- |
| <nobr>`container` | | The container repository. |
| <nobr>`root` | `false` | When `true`, runs the container in the [Controller Preparation Step](#controller-preparation-step) as root (with `sudo`). |
| <nobr>`container_type` | `docker` | The container engine CLI used when running the container. The command to run the container is the value of this option. The commands accepted by the CLI are assumed to be compatible with the ones from the docker CLI. |
| <nobr>`use_subuser` | `false` | When `true`, runs the container in the [Controller Preparation Step](#controller-preparation-step), as well as the container to run the steps in the next layer, with the user `<subuser_prefix><project_name>` (the user will be created if it doesn't exists already, and the home directory will be `users/project-<project_name>`). |
| <nobr>`subuser_prefix` | | The prefix used to create the user that will run the containers. The username will be `<subuser_prefix><project_name>`. When `use_subuser` is `true`, this option is required and cannot be empty. |

## Main Environment Options File - Examples

An example of the file for a development environment is as follows:

```bash
export container=lucasbasquerotto/ansible:0.0.2
export container_type=podman
```

Another example:

```bash
export container=lucasbasquerotto/ansible:0.0.2
export root=true
```

_The above example will use docker as the container engine (`container_type`)._

An example of the file for a production environment is as follows:

```bash
export container=lucasbasquerotto/ansible:0.0.2
export container_type=podman
export use_subuser=true
export subuser_prefix=project-
```

# Controller Preparation Step

This step is the first and only step executed in the controller layer to launch the project (deployment). The [main environment repository](#main-environment-repository) must be present at `ctl/env-main` so that this step can be run.

This file should have the following

## Main Vault File

The main vault file for a project is located at `secrets/projects/<project_name>/vault` and contains the value to decrypt:

1) The [ssh key file](#) to clone the [project environment repository](#).

2) The [project vault file](#).

The encryption should be done with [ansible-vault](#encrypt-with-ansible).

## Launch Options

Below are the options that can be used to launch a project (when running `ctl/run launch ...`):

| Option        | Description |
| ------------- | ----------- |
| <nobr>`-d`<br>`--dev` | Runs the project in a development environment. It allows to map paths to repositories to share the repository across multiple projects and avoid cleaning live changes made to the repository that were still not commited (will not update the repository to the version specified, which allows to develop and test changes without the need to push those changes). |
| <nobr>`-e`<br>`--enter` | Enters the container that runs the preparation step in the controller layer, instead of executing it. The command that would be executed can be seen by running (inside the container) `cat tmp/cmd`. This command doesn't work with the `--inside` option. |
| <nobr>`-f`<br>`--fast` | Skips the [Controller Preparation Step](#controller-preparation-step) and may skip preparation steps in subsequent layers (if thos layers use this option and forwards it to the next layer).<br><br>_Using the cloud layer defined at http://github.com/lucasbasquerotto/cloud, this will skips the [Controller Preparation Step](#controller-preparation-step), [Cloud Preparation Step](#) and [Cloud Context Preparation Step](#), running only the [Cloud Context Main Step](#) for each context._ |
| <nobr>`-i`<br>`--inside` | Considers that the current environment is already inside an environment that has the necessary stuff to run the project, without the need to run it inside a container (the environment may already be a container). See [Running Inside a Container](#) and [Running Without Containers](#) for more information. |
| <nobr>`-p`<br>`--prepare` | Only runs the preparation step and expects that the subsequent layers accept this option so as to run only the preparation step in that layer, and forwards the option to subsequent layers, if needed.<br><br>This has a particular feature that allows to pass arguments to each step that will handle it (as long as subsequent layers handle it). For example, passing the args `-vv` after the project name would generally be used only by the last step, but in this case it will be used as args to run the [Controller Preparation Step](#controller-preparation-step) and no args to subsequent steps.<br><br>You can pass `--` to indicate the end of the arguments for a given step, so the following args `-a -b -- -c -- -d` will pass the args `-a -b` to the [Controller Preparation Step](#controller-preparation-step), and `-c -- -d` to the next step. You can use `--skip` to skip a given step (you shouldn't pass `--` in this case). For example, `--skip -c -- -d` will skip the [Controller Preparation Step](#controller-preparation-step) and pass `-c -- -d` to the next step.<br><br>_Using the cloud layer defined at http://github.com/lucasbasquerotto/cloud, this will run the steps [Controller Preparation Step](#controller-preparation-step), [Cloud Preparation Step](#) and [Cloud Context Preparation Step](#), but won't run the [Cloud Context Main Step](#). You will have 3 steps in this case, so if you run `ctl/run launch <project_name> -- --skip -vv`, the [Controller Preparation Step](#controller-preparation-step) will run without args, the [Cloud Preparation Step](#) will be skipped and the [Cloud Context Preparation Step](#) will run in [verbose mode](https://docs.ansible.com/ansible/latest/cli/ansible-playbook.html#cmdoption-ansible-playbook-v)_ |
| <nobr>`-V`<br>`--no-vault` | By default, the launch expects an unencrypted [vault file](#main-vault-file) at `secrets/projects/<project_name>/vault`. This option runs the [Cloud Context Preparation Step](#) without the vault file (this step shouldn't use encrypted values to be decrypted using a vault file, otherwise an error will be thrown). |
| <nobr>`--ctl` | Runs only the [Controller Preparation Step](#controller-preparation-step) and generates the [Controller Output Vars](#). Usiful to generate the variables that will be used in a demo that doesn't need the controller layer, like the [official demo](#). |
| <nobr>`--debug` | Runs in verbose mode and forwars this option to the subsequent step. |

## Launch Examples

General deployment:

```bash
./ctl/run launch <project_name>
```

_(Or `ctl/run l <project_name>`, or even `ctl/launch <project_name>`)_

For development (will map repositories to specified paths and make permissions less strict):

```bash
./ctl/run launch -d <project_name>
```

Fast deployment (will skip the preparation steps; avoid using it in production environments):

```bash
./ctl/run launch -f <project_name>
```

Prepare the project environment (will not deploy the project, just prepare it to be deployed, like cloning/pulling git repositories, generating files from templates, moving files, and so on):

```bash
./ctl/run launch -p <project_name>
```

_(If you run `ctl/run launch -pf <project_name>` all steps will be skipped)_

The first time you run a project, you will be asked to you enter the valt pass to decrypt files for that project, unless you choose to run with the `--no-vault` argument:

```bash
./ctl/run launch --no-vault <project_name>
```

_(The generated project vault file will be at `<root>/secrets/<project_name>/vault`)_

# Encrypt with Ansible

## 1. Generate a ssh key pair and encrypt the private key

```bash
./ctl/run enter
# inside the container
ssh-keygen -t rsa -C "some-name" -f /main/tmp/id_rsa
# [enter the passphrase twice]
ansible-vault encrypt id_rsa
# [enter the vault password twice]
chown "$UID":"$GID" id_rsa id_rsa.pub
exit
```

The generated files will be in the `<root>/ctl/tmp` folder.

## 2. Encrypt strings

```bash
./ctl/run enter
# inside the container
# replace <file> with the name of the variable that will be created
# E.g.: if the variable is called db_pass, use it instead of <file>
ansible-vault encrypt_string --vault-id workspace@prompt --stdin-name '<file>'
# [enter the vault password twice]
# [enter the value to be encripted and press Ctrl+d twice]
exit
```

Then, copy the value displayed in the terminal and paste in the file you want to use it.

## 3. Encrypt files

```bash
# move the file(s) to the <root>/ctl/tmp folder (<root>/ctl/tmp/<file>)
./ctl/run enter
# inside the container
# replace <file> with the file name that you moved to the tmp folder
ansible-vault encrypt --vault-id workspace@prompt `<file>`
# [enter the vault password twice]
# [enter the value to be encripted and press Ctrl+d twice]
exit
```

The generated files will replace the previous files.
