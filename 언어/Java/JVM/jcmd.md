
Jcmd is a recommended tool from JDK 7 onwards for enhanced JVM diagnostics with no or minimum performance overhead.

Jcmd is a **utility that sends diagnostic command requests to a running JVM**. It must be used on the same machine on which JVM is running. Additional details are available in its [documentation](https://docs.oracle.com/en/java/javase/11/tools/jcmd.html#GUID-59153599-875E-447D-8D98-0078A5778F05).

The command syntax is as follows:

```bash
jcmd [<options>] [<vmid> <arguments>]
```

The available `<options>` are:

- `-J`: supplies arguments to the Java VM that is running the jcmd command. You can use multiple `-J` options, for example: `jcmd -J-Xmx10m -J-Dcom.ibm.tools.attach.enable=yes`
- `-h`: prints the jcmd help
- `<vmid>` is the Attach API virtual machine identifier for the Java™ VM process. This ID is often, but not always, the same as the operating system process ID. One example where the ID might be different is if you specified the system property -Dcom.ibm.tools.attach.id when you started the process. You can use the jps command to find the VMID.

The available arguments are:

- `help`: shows the diagnostic commands that are available for this VM. This list of commands can vary between VMs.
- `help <command>`: shows help information for the specified diagnostic command
- `<command> [<command_arguments>]`: runs the specified diagnostic command, with optional command arguments

## Usage

### Getting the PID

We know that each process has an associated process id known as PID. Hence to get the associated PID for our application, we can use jcmd which will list all applicable Java processes as below:

```bash
root@c6b47b129071:/# jcmd
65 jdk.jcmd/sun.tools.jcmd.JCmd
18 /home/pgm/demo-0.0.1-SNAPSHOT.jar
root@c6b47b129071:/# 
```

Here, we can see the PID of our running application is 18.

### Get List of Possible jcmd Usage

Let’s find out possible options available with the jcmd PID help command to start with:

```bash
root@c6b47b129071:/# jcmd 18 help
18:
The following commands are available:
Compiler.CodeHeap_Analytics
Compiler.codecache
Compiler.codelist
Compiler.directives_add
Compiler.directives_clear
Compiler.directives_print
Compiler.directives_remove
Compiler.queue
GC.class_histogram
GC.class_stats
GC.finalizer_info
GC.heap_dump
GC.heap_info
GC.run
GC.run_finalization
JFR.check
JFR.configure
JFR.dump
JFR.start
JFR.stop
JVMTI.agent_load
JVMTI.data_dump
ManagementAgent.start
ManagementAgent.start_local
ManagementAgent.status
ManagementAgent.stop
Thread.print
VM.class_hierarchy
VM.classloader_stats
VM.classloaders
VM.command_line
VM.dynlibs
VM.flags
VM.info
VM.log
VM.metaspace
VM.native_memory
VM.print_touched_methods
VM.set_flag
VM.stringtable
VM.symboltable
VM.system_properties
VM.systemdictionary
VM.uptime
VM.version
help
```

The available diagnostic commands may be different in different versions of HotSpot VM.

## jcmd Commands

Let’s explore some of the most useful jcmd command options to diagnose our running JVM.

### VM.version

This is to get JVM basic details as shown below:

```bash
root@c6b47b129071:/# jcmd 18 VM.version
18:
OpenJDK 64-Bit Server VM version 11.0.11+9-Ubuntu-0ubuntu2.20.04
JDK 11.0.11
root@c6b47b129071:/# 
```

Here we can see that we are using OpenJDK 11 for our sample application.

### VM.system_properties

This will print all the system properties set for our VM. There can be several hundred lines of information displayed:

```bash
root@c6b47b129071:/# jcmd 18 VM.system_properties
18:
#Thu Jul 22 10:56:13 IST 2021
awt.toolkit=sun.awt.X11.XToolkit
java.specification.version=11
sun.cpu.isalist=
sun.jnu.encoding=ANSI_X3.4-1968
java.class.path=/home/pgm/demo-0.0.1-SNAPSHOT.jar
java.vm.vendor=Ubuntu
sun.arch.data.model=64
catalina.useNaming=false
java.vendor.url=https\://ubuntu.com/
user.timezone=Asia/Kolkata
java.vm.specification.version=11
...
```

### VM.flags
For our sample application, this will print all VM arguments used, either given by us or used default by JVM. Here, we can notice various default VM arguments as below:

```bash
root@c6b47b129071:/# jcmd 18 VM.flags            
18:
-XX:CICompilerCount=3 -XX:CompressedClassSpaceSize=260046848 -XX:ConcGCThreads=1 -XX:G1ConcRefinementThreads=4 -XX:G1HeapRegionSize=1048576 -XX:GCDrainStackTargetSize=64 -XX:InitialHeapSize=536870912 -XX:MarkStackSize=4194304 -XX:MaxHeapSize=536870912 -XX:MaxMetaspaceSize=268435456 -XX:MaxNewSize=321912832 -XX:MinHeapDeltaBytes=1048576 -XX:NonNMethodCodeHeapSize=5830732 -XX:NonProfiledCodeHeapSize=122913754 -XX:ProfiledCodeHeapSize=122913754 -XX:ReservedCodeCacheSize=251658240 -XX:+SegmentedCodeCache -XX:ThreadStackSize=256 -XX:+UseCompressedClassPointers -XX:+UseCompressedOops -XX:+UseFastUnorderedTimeStamps -XX:+UseG1GC 
root@c6b47b129071:/#
```

Similarly, other commands, like VM.command_line, VM.uptime, VM.dynlibs, also provide other basic and useful details about various other properties used.

All of the above commands are to majorly get different JVM-related details. Now let’s look into some more commands that can help in some troubleshooting related to JVM.

### Thread.print

This command is to get the instant thread dump. Hence, it will print the stack trace of all running threads. Following is the way to use it, which can give long output depending on the number of threads in use:

```bash
root@c6b47b129071:/# jcmd 18 Thread.print
18:
2021-07-22 10:58:08
Full thread dump OpenJDK 64-Bit Server VM (11.0.11+9-Ubuntu-0ubuntu2.20.04 mixed mode, sharing):

Threads class SMR info:
_java_thread_list=0x00007f21cc0028d0, length=25, elements={
0x00007f2210244800, 0x00007f2210246800, 0x00007f221024b800, 0x00007f221024d800,
0x00007f221024f800, 0x00007f2210251800, 0x00007f2210253800, 0x00007f22102ae800,
0x00007f22114ef000, 0x00007f21a44ce000, 0x00007f22114e3800, 0x00007f221159d000,
0x00007f22113ce800, 0x00007f2210e78800, 0x00007f2210e7a000, 0x00007f2210f20800,
0x00007f2210f22800, 0x00007f2210f24800, 0x00007f2211065000, 0x00007f2211067000,
0x00007f2211069000, 0x00007f22110d7800, 0x00007f221122f800, 0x00007f2210016000,
0x00007f21cc001000
}

"Reference Handler" #2 daemon prio=10 os_prio=0 cpu=2.32ms elapsed=874.34s tid=0x00007f2210244800 nid=0x1a waiting on condition  [0x00007f221452a000]
   java.lang.Thread.State: RUNNABLE
	at java.lang.ref.Reference.waitForReferencePendingList(java.base@11.0.11/Native Method)
	at java.lang.ref.Reference.processPendingReferences(java.base@11.0.11/Reference.java:241)
	at java.lang.ref.Reference$ReferenceHandler.run(java.base@11.0.11/Reference.java:213)

"Finalizer" #3 daemon prio=8 os_prio=0 cpu=0.32ms elapsed=874.34s tid=0x00007f2210246800 nid=0x1b in Object.wait()  [0x00007f22144e9000]
   java.lang.Thread.State: WAITING (on object monitor)
	at java.lang.Object.wait(java.base@11.0.11/Native Method)
	- waiting on <0x00000000f7330898> (a java.lang.ref.ReferenceQueue$Lock)
	at java.lang.ref.ReferenceQueue.remove(java.base@11.0.11/ReferenceQueue.java:155)
	- waiting to re-lock in wait() <0x00000000f7330898> (a java.lang.ref.ReferenceQueue$Lock)
	at java.lang.ref.ReferenceQueue.remove(java.base@11.0.11/ReferenceQueue.java:176)
	at java.lang.ref.Finalizer$FinalizerThread.run(java.base@11.0.11/Finalizer.java:170)

"Signal Dispatcher" #4 daemon prio=9 os_prio=0 cpu=0.40ms elapsed=874.33s tid=0x00007f221024b800 nid=0x1c runnable  [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE
```

Detailed discussion on capturing a thread dump using other options can be found here.

### GC.class_histogram

Let’s use another jcmd command that will provide important information about heap usage. Additionally, this will list all classes (either external or application-specific) with many instances. Again, the list can be of hundreds of lines depending on the number of classes in use:

```bash
root@c6b47b129071:/# jcmd 18 GC.class_histogram
18:
 num     #instances         #bytes  class name (module)
-------------------------------------------------------
   1:         41457        2466648  [B (java.base@11.0.11)
   2:         38656         927744  java.lang.String (java.base@11.0.11)
   3:          6489         769520  java.lang.Class (java.base@11.0.11)
   4:         21497         687904  java.util.concurrent.ConcurrentHashMap$Node (java.base@11.0.11)
   5:          6570         578160  java.lang.reflect.Method (java.base@11.0.11)
   6:          6384         360688  [Ljava.lang.Object; (java.base@11.0.11)
   7:          9668         309376  java.util.HashMap$Node (java.base@11.0.11)
   8:          7101         284040  java.util.LinkedHashMap$Entry (java.base@11.0.11)
   9:          3033         283008  [Ljava.util.HashMap$Node; (java.base@11.0.11)
  10:          2919         257000  [I (java.base@11.0.11)
  11:           212         236096  [Ljava.util.concurrent.ConcurrentHashMap$Node; (java.base@11.0.11)
```

However, if this doesn’t give a clear picture, we can get a heap dump. Let’s look at it next.

### GC.heap_dump

This command will give an instant JVM heap dump. Therefore we can extract heap dump into a file to analyze later as below:

```bash
root@c6b47b129071:/# jcmd 18 GC.heap_dump ./demo_heap_dump
18:
Heap dump file created
root@c6b47b129071:/# 
```

Here, demo_heap_dump is the heap dump file name. In addition, this will be created at the same location where our application jar is located.

### JFR Command Options

In our earlier article, we discussed Java application monitoring using JFR and JMC. Now, let’s look into the jcmd commands that we can use to analyze performance issues with our application.

[JFR](https://docs.oracle.com/en/java/javase/11/troubleshoot/diagnostic-tools.html#GUID-D38849B6-61C7-4ED6-A395-EA4BC32A9FD6) (Java Flight Recorder) is a profiling and event collection framework built into the JDK.

JFR allows us to **gather detailed low-level information about how JVM and Java applications are behaving**. In addition, we can use JMC to visualize the data collected by JFR. Hence, JFR and JMC together create a complete toolchain to continuously collect low-level and detailed runtime information.

Although how to use JMC is not in the scope of this article, we will see how we can create a JFR file using jcmd. JFR is a commercial feature. Hence by default, it’s disabled.  However, that can be enabled using `jcmd PID VM.unlock_commercial_features`.

Now let’s generate a JFR file using the jcmd command as below:

```bash
root@c6b47b129071:/# jcmd 18 JFR.start name=demo_recording settings=profile delay=10s duration=20s filename=./demorecording.jfr
18:
Recording 1 scheduled to start in 10 s. The result will be written to:

/demorecording.jfr
root@c6b47b129071:/# jcmd 18 JFR.check
18:
Recording 1: name=demo_recording duration=20s (delayed)
root@c6b47b129071:/# jcmd 18 JFR.check
18:
Recording 1: name=demo_recording duration=20s (running)
root@c6b47b129071:/# jcmd 18 JFR.check
18:
Recording 1: name=demo_recording duration=20s (stopped)
```

We have created a sample JFR recording file name `demorecording.jfr` at the same location where our jar application is located. Additionally, this recording is of 20seconds and configured as per requirements.

In addition, we can check the status of the JFR recording using the JFR.check command. And, we can instantly stop and discard the recording using the JFR.stop command. On the other hand, the JFR.dump command can be used to instantly stop and dump the recording.

### VM.native_memory

This is one of the best commands that can provide a lot of useful details about heap and non-heap memory on a JVM. Therefore, this can be used to tune memory usage and detect any memory leak. As we know, JVM memory can be broadly classified as heap and non-heap memory. And to get the details of complete JVM memory usage, we can use this utility. In addition, this can be useful in defining memory size for a container-based application.

To use this feature we need to restart our application with additional VM argument i.e. `–XX:NativeMemoryTracking=summary` or `-XX:NativeMemoryTracking=detail`. Note that enabling NMT causes a 5% -10% performance overhead.

This will give us a new PID to diagnose:

```bash
root@c6b47b129071:/# jcmd 19 VM.native_memory
19:

Native Memory Tracking:

Total: reserved=1159598KB, committed=657786KB
-                 Java Heap (reserved=524288KB, committed=524288KB)
                            (mmap: reserved=524288KB, committed=524288KB) 
 
-                     Class (reserved=279652KB, committed=29460KB)
                            (classes #6425)
                            (  instance classes #5960, array classes #465)
                            (malloc=1124KB #15883) 
                            (mmap: reserved=278528KB, committed=28336KB) 
                            (  Metadata:   )
                            (    reserved=24576KB, committed=24496KB)
                            (    used=23824KB)
                            (    free=672KB)
                            (    waste=0KB =0.00%)
                            (  Class space:)
                            (    reserved=253952KB, committed=3840KB)
                            (    used=3370KB)
                            (    free=470KB)
                            (    waste=0KB =0.00%)
 
-                    Thread (reserved=18439KB, committed=2699KB)
                            (thread #35)
                            (stack: reserved=18276KB, committed=2536KB)
                            (malloc=123KB #212) 
                            (arena=39KB #68)
 
-                      Code (reserved=248370KB, committed=12490KB)
                            (malloc=682KB #3839) 
                            (mmap: reserved=247688KB, committed=11808KB) 
 
-                        GC (reserved=62483KB, committed=62483KB)
                            (malloc=10187KB #7071) 
                            (mmap: reserved=52296KB, committed=52296KB) 
 
-                  Compiler (reserved=146KB, committed=146KB)
                            (malloc=13KB #307) 
                            (arena=133KB #5)
 
-                  Internal (reserved=460KB, committed=460KB)
                            (malloc=428KB #1421) 
                            (mmap: reserved=32KB, committed=32KB) 
 
-                     Other (reserved=16KB, committed=16KB)
                            (malloc=16KB #3) 
 
-                    Symbol (reserved=6593KB, committed=6593KB)
                            (malloc=6042KB #72520) 
                            (arena=552KB #1)
 
-    Native Memory Tracking (reserved=1646KB, committed=1646KB)
                            (malloc=9KB #113) 
                            (tracking overhead=1637KB)
 
-        Shared class space (reserved=17036KB, committed=17036KB)
                            (mmap: reserved=17036KB, committed=17036KB) 
 
-               Arena Chunk (reserved=185KB, committed=185KB)
                            (malloc=185KB) 
 
-                   Logging (reserved=4KB, committed=4KB)
                            (malloc=4KB #191) 
 
-                 Arguments (reserved=18KB, committed=18KB)
                            (malloc=18KB #489) 
 
-                    Module (reserved=124KB, committed=124KB)
                            (malloc=124KB #1521) 
 
-              Synchronizer (reserved=129KB, committed=129KB)
                            (malloc=129KB #1089) 
 
-                 Safepoint (reserved=8KB, committed=8KB)
                            (mmap: reserved=8KB, committed=8KB) 
 
```

Here, we can notice details about different memory types apart from Java Heap Memory. The Class defines the JVM memory used to store class metadata. Similarly, the Thread defines the memory that our application threads are using. And the Code gives the memory used to store JIT-generated code, the Compiler itself has some space usage, and GC occupies some space too.

In addition, the reserved can give an estimation of the memory required for our application. And the committed shows the minimum allocated memory.

## Diagnose Memory Leak

Let’s see how we can identify if there is any memory leak in our JVM. Hence to start with, we need to first have a baseline. And then need to monitor for some time to understand if there is any consistent increase in memory in any of the memory types mentioned above.

Let’s first baseline the JVM memory usage as below:

```bash
root@c6b47b129071:/# jcmd 19 VM.native_memory baseline
19:
Baseline succeeded
```

Now, use the application for normal or heavy usage for some time. In the end, just use diff to identify the change since baseline as below:

```bash
root@c6b47b129071:/# jcmd 19 VM.native_memory summary.diff
19:

Native Memory Tracking:

Total: reserved=1162150KB +2540KB, committed=660930KB +3068KB

-                 Java Heap (reserved=524288KB, committed=524288KB)
                            (mmap: reserved=524288KB, committed=524288KB)
 
-                     Class (reserved=281737KB +2085KB, committed=31801KB +2341KB)
                            (classes #6821 +395)
                            (  instance classes #6315 +355, array classes #506 +40)
                            (malloc=1161KB +37KB #16648 +750)
                            (mmap: reserved=280576KB +2048KB, committed=30640KB +2304KB)
                            (  Metadata:   )
                            (    reserved=26624KB +2048KB, committed=26544KB +2048KB)
                            (    used=25790KB +1947KB)
                            (    free=754KB +101KB)
                            (    waste=0KB =0.00%)
                            (  Class space:)
                            (    reserved=253952KB, committed=4096KB +256KB)
                            (    used=3615KB +245KB)
                            (    free=481KB +11KB)
                            (    waste=0KB =0.00%)
 
-                    Thread (reserved=18439KB, committed=2779KB +80KB)
                            (thread #35)
                            (stack: reserved=18276KB, committed=2616KB +80KB)
                            (malloc=123KB #212)
                            (arena=39KB #68)
 
-                      Code (reserved=248396KB +21KB, committed=12772KB +213KB)
                            (malloc=708KB +21KB #3979 +110)
                            (mmap: reserved=247688KB, committed=12064KB +192KB)
 
-                        GC (reserved=62501KB +16KB, committed=62501KB +16KB)
                            (malloc=10205KB +16KB #7256 +146)
                            (mmap: reserved=52296KB, committed=52296KB)
 
-                  Compiler (reserved=161KB +15KB, committed=161KB +15KB)
                            (malloc=29KB +15KB #341 +34)
                            (arena=133KB #5)
 
-                  Internal (reserved=495KB +35KB, committed=495KB +35KB)
                            (malloc=463KB +35KB #1429 +8)
                            (mmap: reserved=32KB, committed=32KB)
 
-                     Other (reserved=52KB +36KB, committed=52KB +36KB)
                            (malloc=52KB +36KB #9 +6)
 
-                    Symbol (reserved=6846KB +252KB, committed=6846KB +252KB)
                            (malloc=6294KB +252KB #76359 +3839)
                            (arena=552KB #1)
 
-    Native Memory Tracking (reserved=1727KB +77KB, committed=1727KB +77KB)
                            (malloc=11KB #150 +2)
                            (tracking overhead=1716KB +77KB)
 
-        Shared class space (reserved=17036KB, committed=17036KB)
                            (mmap: reserved=17036KB, committed=17036KB)
 
-               Arena Chunk (reserved=186KB, committed=186KB)
                            (malloc=186KB)
 
-                   Logging (reserved=4KB, committed=4KB)
                            (malloc=4KB #191)
 
-                 Arguments (reserved=18KB, committed=18KB)
                            (malloc=18KB #489)
 
-                    Module (reserved=124KB, committed=124KB)
                            (malloc=124KB #1528 +7)
 
-              Synchronizer (reserved=132KB +3KB, committed=132KB +3KB)
                            (malloc=132KB +3KB #1111 +22)
 
-                 Safepoint (reserved=8KB, committed=8KB)
                            (mmap: reserved=8KB, committed=8KB)
```

Over time as GC works, we’ll notice an increase and decrease in memory usage. However, if there is an uncontrolled increase in memory usage, then this could be a memory leak issue. Hence, we can identify the memory leak area, like Heap, Thread, Code, Class, etc., from these stats. And if our application needs more memory, we can tune corresponding VM arguments respectively.

If the memory leak is in Heap, we can take a heap dump (as explained earlier) or maybe just tune Xmx. Similarly, if the memory leak is in Thread, we can look for unhandled recursive instructions or tune Xss.

---
reference
- https://docs.oracle.com/javase/8/docs/technotes/tools/windows/jcmd.html
- https://sheerheart.tistory.com/entry/JVM-%ED%8A%B8%EB%9F%AC%EB%B8%94-%EC%8A%88%ED%8C%85-%EB%B0%8F-%EB%B6%84%EC%84%9D%EC%9D%84-%EC%9C%84%ED%95%9C-%EB%AA%85%EB%A0%B9%EC%96%B4%EB%93%A4#google_vignette
- https://www.ibm.com/docs/en/semeru-runtime-ce-z/11?topic=tools-java-command-jcmd-tool
- https://bell-sw.com/announcements/2021/10/14/jcmd-everywhere-locally-containerized-and-remotely/