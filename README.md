# RIBY
Tips for **Ruby 3.0** in *powerpc-os400*

----
When I was in High School I was quite good at Maths and I was often asked for help by classmates.
My nickname was *Riby*, out of my family name.

That's why I decided to name this GitHub repository **RIBY**: it is here to help the few that would be so courageous to face the hurdles of installing
Ruby gems in **IBM i PASE**.
Riby also has a curious assonance with **Ruby**, the programming language we will leverage on.

I would suggest an [IBM i chroot](https://github.com/IBM/ibmichroot) approach so you do not risk compromising any of your existing PASE configurations.

But let us start from the beginning, I will add content gradually based on the feedback of the... class!

The most recent content will be on top of the README so, if you will join later on, start reading from the bottom (or follow the index).

Let's go!

----
## INDEX

1. [to pave the way](#1-to-pave-the-way)
2. [to refurbish the flat](#2-to-refurbish-the-flat)
3. [to install Ruby 3.0](#3-to-install-ruby-30)
4. [to do everything once again](#4-to-do-everything-once-again)
5. [to study IBM i through PASE with Ruby](#5-to-study-ibm-i-through-pase-with-ruby)

----

### 5. to study IBM i through PASE with Ruby

In my personal experience Ruby in PASE has always been a tool to better understand IBM i job dual nature. When IBM decided for PASE the way it is (this was more that twenty years ago), they thought it had been better to just implement an AIX runtime environment and so avoid AS/400 users' base the burden of managing another operating system.

But how can a PASE Ruby script investigate this? 

The first consideration is that **IBM i PASE libc.a** differs from **AIX libc.a**: it offers extra resources vital to sense the dual nature of an IBM i job. 

Ruby interpreter comes with the Ruby Standard Library (**RSL**). Among many other goodies, RSL provides a **libffi** wrapper for Ruby named **fiddle**. 

If you perform a dump of the ruby interpreter you can list the shared libraries it uses at load time:

```
$ which ruby
  /QOpenSys/pkgs/bin/ruby
$ dump -X64 -Hv /QOpenSys/pkgs/bin/ruby
  . . .
                        ***Import File Strings***
INDEX  PATH                          BASE                MEMBER              
0      /QOpenSys/pkgs/lib:/usr/lib:/lib                                         
1                                    libbsd.a            shr_64.o            
2                                    libutil.so.2        shr_64.o            
3                                    libpthread.a        shr_xpg5_64.o       
4                                    libgmp.so.10        shr_64.o            
5                                    libdl.a             shr_64.o            
6                                    libcrypt.a          shr_64.o            
7                                    libc.a              shr_64.o              
```

So there is no *libffi.so* involved in default Ruby execution. 

But if we search for libffi among the **.so** shared libraries that implement *powerpc-os400* RSL we discover it is there:

```
$ dump -X64 -Hv /QOpenSys/pkgs/lib/ruby/3.0.0/powerpc-os400/*.so | grep  libffi
2                                    libffi.so.6         shr_64.o            
```  

The actual shared library depending on *libffi* is `/QOpenSys/pkgs/lib/ruby/3.0.0/powerpc-os400/fiddle.so`. In order to benefit from the services of libffi wrapped by fiddle we need to **require** it (`require 'fiddle'`). What fiddle offers us is the possibility 

* to load shared libraries, 
* to find exported functions and 
* to call them.

But if a shared library is already loaded there is no need to explicitly reload it.
So we can access libc.a entries invoking `dlopen()` with *nil* argument. 

One of the functions that IBM i PASE adds to AIX libc.a is **[_ILELOADX](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/apis/pase__ileload.htm)**

Let us save the following script as *check_srvpgm.rb*:

``` 
#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer

SrvPgmNm = struct [ 'char a[21]' ]
preload  = Fiddle.dlopen(nil)
ileloadx = Fiddle::Function.new( preload['_ILELOADX'], 
                           [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],
                           Fiddle::TYPE_LONG_LONG )
searched = SrvPgmNm.malloc
searched[0, 21] = ARGV[0] 
srvpgm = ileloadx.call(searched, 1)
check = 'not ' if srvpgm == -1 
puts "'#{ARGV[0]}' is #{check}loadable from PASE\n"                          
```

Then `chmod 0755 check_srvpgm.rb` to make it executable and test it:

```
$ check_srvpgm.rb QSYS/QC2UTIL1
  'QSYS/QC2UTIL1' is loadable from PASE
$ check_srvpgm.rb QSYS/QC2UTIL8
  'QSYS/QC2UTIL8' is not loadable from PASE
```

`ls -1 /QSYS.LIB/*.SRVPGM`


### 4. to do everything once again

**Repeatability** is a measure of the likelihood that, having produced one result from an experiment, you can try the same experiment, with the same setup, and produce that exact same result.

It is fundamental for us to be able to automate what has been performed in steps 1 through 3 in a unique sequence of steps. We could also leverage *shell scripting* introducing a variable for assigning a name to the *chroot* and another for refining the choice of the *package* to be installed.
In this repository the script named [onceAgain](onceAgain) is doing that.
It accepts 0, 1 or 2 arguments. 

* The first argument (when provided) will be the name of the chroot under */QOpenSys* (default: **chRootRiby**).
* The second argument will be the name of the package to be installed in the chroot (default: **ruby** ).

Let us test the script passing no arguments (having removed previous installation):

```
$ rm -r /QOpenSys/chRootRiby
$ cd $HOME
$ git clone https://github.com/AndreaRibuoli/RIBY.git
$ RIBY/onceAgain
```

The script will allow us to create chroots at different level of *version-release* of Ruby. Let us test the script adopting the following arguments:

```
$ cd $HOME
$ RIBY/onceAgain chRootRibyPrv ruby-devel
```

----
### 3. to install Ruby 3.0

In the previous steps we organized a confortable home for our Ruby installation. 
I organized a yum repository to host current and future builds of Ruby interpreter.

To configure access to the mentioned repository we will use **git**:

```
yum -y install git
```

```
cd $HOME
```

```
git clone https://github.com/AndreaRibuoli/RIBY.git
```

```
cp ./RIBY/andrearibuoli.repo /QOpenSys/etc/yum/repos.d
```

```
yum -y install ruby
```

```
ruby -v
```

```
gem list
```

Here we are: you have **Ruby 3.0 interpreter installed in an IBM i PASE chroot!**

----
### 2. to refurbish the flat

At the end of the first step we entered our newly created chroot for the first time.

We had previously installed *yum* so it is available to list installed packages:

```
yum list installed
```

but not to install extra packages (`yum repolist all` returns *repolist: 0*)


We can notice there are some refinements required:

* if we execute `cd $HOME` we will notice that current user's home needs to be created in the chroot (`mkdir $HOME`; `chmod 0755 $HOME`)
* the */tmp* directory is missing the *sticky bit* (execute `chmod +t /tmp`)
* the */QOpenSys/etc/yum* is incomplete: */QOpenSys/etc/yum/repos.d* directory is missing so that no yum repository is identified (`mkdir /QOpenSys/etc/yum/repos.d`)

**Note**: in order to configure yum repository enter 5250 and 

CPY OBJ('*/QOpenSys/etc/yum/repos.d/ibm.repo*') TODIR('*/QOpenSys/chRootRiby/QOpenSys/etc/yum/repos.d*')

Now, if we repeat the `yum repolist all` we get:

```
bash-4.4$ yum repolist all
repo id                              repo name                         status
ibm                                  ibm                               enabled: 661
repolist: 661
```

----
### 1. to pave the way

If you do not have experience with **IBM i chroot** I would suggest you to practice a bit.
I assume you already have installed **yum** in your PASE environment so that installing IBM i chroot will be straightforward:

```
yum install ibmichroot
``` 

Creating a chroot is as simple as (the `-y` options means *Auto respond yes to the prompts*):

```
chroot_setup -y /QOpenSys/chRootRiby
``` 

Now, yum supports an option (`--installroot`) that allows us to specify a chroot (already created) as the target for our installation:
we will use it to prepare the safe environment to experiment with Ruby 3. 
First of all we install in the chroot the **yum** package itself (with its dependencies) so that we will be able to issue the next installations from the chroot:

```
yum -y --installroot=/QOpenSys/chRootRiby install yum ca-certificates-mozilla
```

We also add the package *ca-certificates-mozilla* because it will be useful later on.

Yum handles all dependencies and we will end up installing almost fifty packages! One of these is *bash* so that entering the chroot we can actually use the newly installed **bash** shell:

```
chroot /QOpenSys/chRootRiby /QOpenSys/pkgs/bin/bash
```
