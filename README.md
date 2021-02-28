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
6. [to gain confidence on Ruby language](#6-to-gain-confidence-on-ruby-language)
7. [to get acquainted with QSYS/QC2xx service programs](#7-to-get-acquainted-with-qsysqc2xx-service-programs)
8. [to execute a service program entry call from PASE](#8-to-execute-a-service-program-entry-call-from-pase)
9. [o gather information on space pointers from PASE](#9-to-gather-information-on-space-pointers-from-pase)

----
### 9. to gather information on space pointers from PASE

We introduced the idea that ILE mode has full access to memory allocated by PASE. The opposite is not granted: not all storage allocated by ILE can be visible in PASE. We will verify this aspect.

We will compare different ILE APIs that can be used to reserve storage blocks:

1. `malloc`
2. `_C_TS_malloc`
3. `_C_TS_malloc64`     
4. `Qp2malloc`

When ILE **malloc** is used in a compiled program it can be implicitly re-mapped to \_C\_TS\_malloc
as soon as `TERASPACE(*YES *TSIFC)` parameter is specified. If we invoke ILE malloc from Ruby this will *always* use **single-level store** storage. And will also have 16711568 bytes (0xFEFF90) as maximum size.
The maximum amount of **teraspace storage** that can be allocated by each call to \_C\_TS\_malloc() is instead 2147483424 bytes (0x80000000 - 0xE0 = 0x7FFFFF20). When more bytes are needed on a single request the \_C\_TS\_malloc64 is available (it accepts an *unsigned long long int* to specify the size required).

The template for Qp2malloc is: 

```
void* Qp2malloc(QP2_dword_t size, QP2_ptr64_t *mem_pase); 
```

QP2_dword_t is an *unsigned long long int* so Qp2malloc is not limited in the size value and offers an extra service: sets the 8 bytes buffer (we are addressing with the second argument) as the PASE address to the newly allocated teraspace storage. 

Let us start with this last API. We soon notice that while we were able to specify an ARG\_MEMPTR in the argument list there is no such thing as a **RESULT\_MEMPTR**. If we invoke \_ILECALLX specifying **-11** as the result\_type we receive an error **ILECALL\_INVALID\_RESULT (2)** (*The result_type value is invalid*). 

On the other hand the specifications for \_ILECALLX offer an extra option: any **positive value** for the result\_type can be used when the function result is an aggregate (structure or union). An aggregate function result is returned in a buffer allocated by the caller and passed to the target ILE procedure using a special field in the argument list (bytes 17-32 of the *base*). We will use this technique to receive the ILE pointer.   

We will prepare an ILEpointer variable and pass its address in the aggregate field.

We will use this approach with `malloc`, `_C_TS_malloc` and `_C_TS_malloc64` respectively. In these three APIs there is no opportunity to directly read back a PASE pointer. The question that arises is how we can convert a buffer containing a generic ILE pointer (in its original format) while in PASE. 


----
### 8. to execute a service program entry call from PASE 

By means of **fiddle** we managed to dinamically call **_ILELOADX** and **_ILESYMX** from a Ruby script.
Fiddle offered us the support to -relatively easily- declare the argument list and return code types involved.
It also offered us the ability to prepare memory consistently when calls are to be performed.

The object oriented nature of the Ruby language enabled the designers of **fiddle** to simplify the final usage of 
shared library entries. With `Fiddle::Function.new` we simply pass the function templates: the object instance we are returned with is then capable of handling the parameters provided in a subsequent elegant `call` method.

As we approach the **[_ILECALLX](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/apis/pase__ilecall.htm)** documentation we understand the difference! The burden of invoking a service program entry with a prepared set of arguments is all on our shoulders!

We will start with simple working examples: we will be collecting ideas on how to design and implement an abstraction that will offer the ability to use ILE Service Programs (**\*SRVPGM**) from Ruby with the same ease *fiddle* is offering for shared libraries.

Let us first investigate our ILE C `system` example.    

ILE C `system` returns an integer but receives an ILE native pointer (that is a quad-word).  
We need to allocate a 16-byte aligned 16-byte chunk of memory prepared with the PASE address in the last 8 bytes.
During the *\_ILECALLX* processing the PASE address in converted into a proper IBM i space pointer and finally the system call gets executed.

All storage in the `private address space` of the running PASE/AIX process is shared with the current IBM i job: ILE APIs have access to it. Passing parameters to **_ILECALLX** is far from simple in a PASE C program but it is definitely complex in a dynamic style. Let us shed some light on the deatails.

First of all we have to prepare the template for *_ILECALLX* that **fiddle** will use. The C notation is:

```
 int _ILECALLX(const ILEpointer  *target,
               ILEarglist_base   *ILEarglist,
               const arg_type_t  *signature,
               result_type_t     result_type,
               int               flags);
```

In */usr/include/as400_types.h* we find the definition of *result\_type\_t*:

```
typedef int16        result_type_t;
```

In */usr/include/as400_types.h* we find the definition of *int16*:

```
typedef signed short         int16;
```

So far we know that we can prepare a Fiddle Function for **\_ILECALLX** this way:

```
ilecallx = Fiddle::Function.new( preload['_ILECALLX'],                                                                        
            [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_INT],
            Fiddle::TYPE_INT )                                                                                 
```

In a previous Ruby script (enhanced by *fiddle*) we already defined an `ILEpointer` type as `ILEpointer = struct [ 'char b[16]' ]`. It was valued by a call to **\_ILESYMX**. 

The secret of using fiddle's `struct` in PASE is that **the actual memory reserved will be acquired with a PASE `malloc`**. This is a fundamental detour from how memory is usually handled by the Ruby interpreter (engineered to natively integrate with the garbage collector). 

PASE `malloc` variant differs from AIX one: it is **always returning a 16-byte aligned address**, this implies that by using fiddle's `struct` we are guaranteed that those 16 bytes are suitable to hold a teraspace address when handled in ILE job mode.   

The ILEarglist is (again) required to be 16-byte aligned.
Apart from the global alignment of this struct we have an opening standard **base** struct followed by a variable sequence of arguments that need to be padded with extra bytes consistently with the data type length of the actual argument. 
The logic to be consistent with is summurized by the following table:

| Argument Length | Alignment       |
| --------------- |:---------------:|
| 1 byte	        |      any        |
| 2 bytes	        |    2 bytes      |
| 3-4 bytes       |    4 bytes      |
| 5-8 bytes       |    8 bytes      |
| 9 or more bytes |   16 bytes      |

Let us keep these details in mind and try to apply them in invoking ILE `system` from Ruby PASE: we just have one argument.
As soon as the *ILEarglist\_base* is 32 bytes long, the first argument will be implictly 16-byte aligned too. Being the only argument we do not have to care too much this time.

We will try with: 

```
ILEarglist = struct [ 'char b1[16]', 'char b2[16]', 'char b3[16]' ]
```

The **signature** is a pointer to a list of `arg_type_t` values.
The typedef introducing `arg_type_t` declares it as a signed short. So we have to prepare an array of shorts ready to be interpreted.
The actual number of arguments processed by the *\_ILECALLX* function is determined by the number of entries in the signature list, which is determined by the location of the first 0 value in the list that ends the processing.
We need 2 short integers to invoke ILE `system`: 

1. the first qualifies the ILE pointer argument and will be set to ARG\_MEMPTR (i.e. **-11**)
2. the second closes the list and will be set to ARG\_END (**0**)

This is a struct that does not need to be passed to ILE so that its own alignment is not relevant (we can allocate it as a regular Ruby string).


We will ignore the return code of `system` by setting **result_type** to 0.

We need to provide enough contiguos storage following *ILEarglist\_base* for a 16 bytes (quad-word), i.e. the ILE pointer.

The [Ruby script I am presenting](invoke_system.rb) summarizes the steps described. Ruby can encode an **EBCDIC** content (through the support of **IBM037** encoding). That content is passed on as command argument in the `int system(const char *command)` ILE C standard library function.

----
### 7. to get acquainted with QSYS/QC2xx service programs 

In IBM i ILE the role of **libc.a** is played by a group of service programs. 
If we search for `system`, a C standard library function, we will find it inside a service program named **QSYS/QC2SYS**. 
The QSYS/QC2SYS service program can be loaded from PASE so we can imagine to extend our Ruby script dinamically introducing support for ILE native `system` function.

The C template for `system` is inside include file member `QSYSINC/H(STDLIB)`:

```
int      system   ( const char *command ); 
``` 

After obtaining accessability to a service program with *[_ILELOADX](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/apis/pase__ileload.htm)* we can look for a specific entry with **[_ILESYMX](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/apis/pase__ilesym.htm)**

 ```
 int _ILESYMX(ILEpointer          *export,
              unsigned long long  actmark,
              const char          *symbol);  
 ```

In order for *fiddle* to be able to handle \_ILESYMX we need to prepare memory for an **ILEpointer**.

``` ruby

 . . . 
ILEpointer = struct [ 'char b[16]' ]
 . . .
ilesymx = Fiddle::Function.new( preload['_ILESYMX'],
            [Fiddle::TYPE_VOIDP, Fiddle::TYPE_LONG_LONG, Fiddle::TYPE_VOIDP],
            Fiddle::TYPE_INT )
 . . .
ILEfunction = ILEpointer.malloc
rc = ilesymx.call(ILEfunction, srvpgm, ARGV[1])
raise "Searching for function entry '#{ARGV[1]}' in service program #{ARGV[0]} failed" if rc != 1
```

I prepared **[check_srvpgm_entry.rb](check_srvpgm_entry.rb)** accepting 2 arguments: 

1. qualified service program name 
2. function entry name

If successful nothing occurs; in case of error we get:

```
bash-4.4$ ./check_srvpgm_entry.rb QSYS/QC2UTIL1 mallocz
./check_srvpgm_entry.rb:22:in `<main>': Searching for function entry 'mallocz' in service program QSYS/QC2UTIL1 failed (RuntimeError)
```
----
### 6. to gain confidence on Ruby language

Assuming you are now confident in using a specific Ruby for powerpc-os400 release let us install it (out of a chroot). If you prefer not to officially add an extra repository (*andrearibuoli.repo*) you can download required RPMs **inside the chroot** and install them locally **out of the chroot**.

We cannot install Ruby directly:
```
$ /QOpenSys/pkgs/bin/bash
bash-4.4$ export PATH=/QOpenSys/pkgs/bin:$PATH
bash-4.4$ yum list | grep ruby
bash-4.4$
``` 

We first perform:

```
bash-4.4$ chroot /QOpenSys/chRootRiby/ yum install yum-utils

```

So we fetch the RPMs (no installation) via chroot using one of the utilities **yum-utils** provide:

```
bash-4.4$ chroot /QOpenSys/chRootRiby yumdownloader ruby
ruby-3.0.0-2.ibmi7.3.ppc64.rpm                              |  24 MB  00:07     
bash-4.4$ chroot /QOpenSys/chRootRiby yumdownloader ruby-devel
ruby-devel-3.0.0-2.ibmi7.3.ppc64.rpm                        | 335 kB  00:00
bash-4.4$ 
```

We are authorized to access the chroot from the outside so we perform our installation (the order matters):

```
yum localinstall /QOpenSys/chRootRiby/ruby-3.0.0-2.ibmi7.3.ppc64.rpm 
yum localinstall /QOpenSys/chRootRiby/ruby-devel-3.0.0-2.ibmi7.3.ppc64.rpm 
```

Note that some prerequite packages may be missing and will be installed directly from *ibm.repo*.
Now Ruby interpreter is available for all users.

Ruby is an excellent tool for system administration. 
Let us use it combining previous study of **fiddle** and **_ILELOADX**.  

Ruby supports **Regular Expressions**. 

If we perform `ls -1 \QSYS.LIB\*.SRVPGM` we get the list of service programs provided by IBM in QSYS.
Building on this idea we decide to print out a list of those that cannot be loaded from PASE.

This is done with [the script named nonLoadables](nonLoadables).

```
bash-4.4$ RIBY/nonLoadables 
'QSYS/QGLDCLNT64' is not loadable from PASE
'QSYS/QLGICUNORM' is not loadable from PASE
'QSYS/QLGICUSORT' is not loadable from PASE
'QSYS/QP0LCNVMSG' is not loadable from PASE
'QSYS/QP0WSTTS64' is not loadable from PASE
'QSYS/QQQSVREG' is not loadable from PASE
'QSYS/QQQSVXML' is not loadable from PASE
   . . .
'QSYS/QYUSVPDCOL' is not loadable from PASE
'QSYS/QZLSSRV5' is not loadable from PASE
'QSYS/QZRUDBG' is not loadable from PASE
```

It is not clear -to me- why some SRVPGM are loadable from PASE while others are not (as a general rule).

### 5. to study IBM i through PASE with Ruby

In my personal experience Ruby in PASE has always been a tool to better understand IBM i job dual nature. When IBM decided for PASE the way it is (this was more that twenty years ago), they thought it had been better to just implement an AIX runtime environment and so avoid AS/400 users' base the burden of managing another operating system.

But how can a PASE Ruby script investigate this? 

The first consideration is that **IBM i PASE libc.a** differs from **AIX libc.a**: it offers extra resources vital to sense the dual nature of an IBM i job. 

Ruby interpreter comes with the Ruby Standard Library (**RSL**). Among many other goodies, RSL provides a **libffi** wrapper for Ruby named **fiddle**. 

If you perform a dump of the ruby interpreter you can list the shared libraries it uses at load time. As soon as we installed Ruby interpreter only inside the chroot we will execute:

```
$ chroot /QOpenSys/chRootRiby which ruby
  /QOpenSys/pkgs/bin/ruby
```

and:

```
$ chroot /QOpenSys/chRootRiby dump -X64 -Hv /QOpenSys/pkgs/bin/ruby
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

So there is no *libffi.so* involved in default Ruby execution. The actual shared library depending on *libffi* is `/QOpenSys/pkgs/lib/ruby/3.0.0/powerpc-os400/fiddle.so`. 

```
$ chroot /QOpenSys/chRootRiby dump -X64 -Hv /QOpenSys/pkgs/lib/ruby/3.0.0/powerpc-os400/fiddle.so

/QOpenSys/pkgs/lib/ruby/3.0.0/powerpc-os400/fiddle.so:

. . .

                        ***Import File Strings***
INDEX  PATH                          BASE                MEMBER              
0      /QOpenSys/pkgs/lib:/usr/lib:/lib                                         
1                                    libdl.a             shr_64.o            
2                                    libffi.so.6         shr_64.o            
3                                    libc.a              shr_64.o            
4                                    libgcc_s.so.1       shr_64.o            
5                                    ..                                      

```

In order to benefit from the services of libffi wrapped by fiddle we need to **require** it (`require 'fiddle'`). What fiddle offers us is the possibility 

* to load shared libraries, 
* to find exported functions and 
* to call them.

When a shared library is already loaded there is no need to explicitly reload it.
So we can access **libc.a** entries invoking a `dlopen()` with *nil* argument. 

One of the functions that IBM i PASE adds to original AIX libc.a is **[_ILELOADX](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/apis/pase__ileload.htm)**

We can run the Interactive RuBy (**irb**) from the chroot:

```
$ chroot /QOpenSys/chRootRiby /QOpenSys/pkgs/bin/irb
irb(main):001:0> require 'fiddle'
=> true
irb(main):002:0> quit
$ 
```

We can also copy a script distributed with RIBY called **[check_srvpgm.rb](check_srvpgm.rb)** in our
home folder in the chroot:

```
cp ${HOME}/RIBY/check_srvpgm.rb /QOpenSys/chRootRiby${HOME}
```

and execute it passing as an argument the service program we want to load from PASE:

```
$ chroot /QOpenSys/chRootRiby ${HOME}/check_srvpgm.rb QSYS/QC2UTIL1
  'QSYS/QC2UTIL1' is loadable from PASE
```

if the service program cannot be loaded (e.g. does not exist) we receive the following message:

```
$ chroot /QOpenSys/chRootRiby ${HOME}/check_srvpgm.rb QSYS/QC2UTIL8
  'QSYS/QC2UTIL8' is not loadable from PASE
```

Note that accessing native (ILE) service programs is not limited by chroot: only the authorities of current user profile matter!

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
