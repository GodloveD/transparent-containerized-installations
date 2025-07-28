# **Transparent Containerized Installations**

### _How to install a containerized application as though it were bare metal with Apptainer!_

You can install applications in [Apptainer](https://apptainer.org/) containers and then use them as
though they were installed on bare metal. The [shell script in this
repository](./lolcow-installer.sh) shows you how. This is useful if you work in a multi-tenant
environment (like a [High Performance
Computing](https://en.wikipedia.org/wiki/High-performance_computing) center) and you are responsible
for installing and maintaining software on behalf of users. You can also use it on your own system
to install software in a modular and portable way. For instance, maybe you work on a team of
developers, and you want to maintain multiple versions of the application you are working on.

This method was originally developed by staff scientists at the [National Institutes of
Health](https://hpc.nih.gov/). See [this repo](https://github.com/NIH-HPC/singularity-def-files) for
many more examples.

---

The general idea is to set up a directory structure like the one that follows.

```text
/installation/directory
└── lolcow
    └── v0.1.0
        ├── bin
        │   ├── cowsay -> ../libexec/wrapper.sh
        │   ├── fortune -> ../libexec/wrapper.sh
        │   └── lolcat -> ../libexec/wrapper.sh
        ├── libexec
        │   ├── app.sif
        │   └── wrapper.sh
        └── src
            └── app.def
```

The script called `wrapper.sh` contains instructions for converting commands (in this case `cowsay`,
`fortune`, and `lolcat`) into commands that are executed in the container image `app.sif`.

```shell
#!/bin/bash
export APPTAINER_BINDPATH=""
cmd=$(basename "$0")
dir="$(dirname $(readlink -f ${BASH_SOURCE[0]}))"
img="app.sif"
apptainer exec "${dir}/${img}" $cmd "$@"
```

Once the pieces are in place, you can add the `bin` directory to your path and then execute the
commands without using any special container calls. And other users on the same system can run
containerized commands without knowing a single thing about Linux containers!

The script [`lolcow-installer.sh`](./lolcow-installer.sh) will perform the steps required to install
a containerized application. But it is really just meant to be a guide. Once you have an application
installed in this way, it is easy to simply copy the parent directory to a new location, replace the
`.sif` and `.def` files with a new container image and definition file (optional) respectively, and
then create new symlinks for whatever commands you want to expose from within the container.  
