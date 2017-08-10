# Bash

Powerful `.bashrc` and `.bash_profile` coming together with colorful output. It adds additional information
to your command prompt and many useful aliases.

Features:
* shows number of active background jobs
* shows number of open *tmux* sockets
* *hostname* color can be based on host unique identifier to simplify server identification by the user when working with multiple open SSH sessions
* shows checked-out branch name when current directory is within Git repository
* shows last command return code if it differs from 0


## Installation

The most convenient way of installation is to checkout the repository and symlink the relevant scripts.
Assuming the installation in home directory:
```bash
git clone git@github.com:Charlietje/bash.git
cd bash
./__deploy.sh
or
./__deploy.sh username@host

```


## Application aliases

Many Unix commands have already newer and more feature-rich replacements. Following aliases are defined in
`bash_aliases.sh`:

|Command:       |Replacement:    |
| ------------- | -------------- |
|df             |pydf            |
|less           |most            |
|tail           |multitail       |
|top            |htop            |
|tracepath      |mtr             |
|traceroute     |mtr             |

To install them, run following command:

```bash
aptitude install most multitail pydf mtr htop
```

If you don't have them installed, script falls back to the original command.


