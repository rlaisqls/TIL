- [`ioctl()`](https://man7.org/linux/man-pages/man2/ioctl.2.html)는 하드웨어의 제어와 상태 정보를 얻기 위해 제공되는 함수이다. 

- 데이터를 읽고 쓰는 등의 기능은 `read()`, `write()`를 사용하지만, 하드웨어를 제어하거나 상태 정보를 확인하려면 `ioctl()`를 이용해야한다.

```c
#include <sys/ioctl.h>
int ioctl(int d, int request, ...);
```
- `d`: open한 디바이스 드라이버의 fd 값이다
- `request`: 디바이스에게 전달할 명령이다. 이 명령에 따라서 디바이스를 컨트롤 할 수 있다.

- `/usr/include/asm/ioctl.h` 헤더파일에 ioctl의 커맨드 번호를 작성하는데 사용해야하는 매크로가 정의되어있다.
  - `_IO(int type, int number)`: type, number 값만 전달하는 단순한 ioctl에 사용
  - `IOR(int type, int number, data_type)`: 디바이스 드라이버에서 데이터를 읽는 ioctl에 사용
  - `_IOW(int type, int number, data_type)`: 디바이스 드라이버에서 데이터를 쓰는 ioctl에 사용
  - `_IORW(int type, int number, data_type)`: 디바이스 드라이버에서 데이터를 쓰고 읽는 ioctl에 사용
  - 위 매크로 이외에도 [`ioctl.h`](https://github.com/torvalds/linux/blob/master/include/uapi/asm-generic/ioctl.h) 헤더파일에 다양한 매크로가 있다.

  - 각 매크로에 들어가는 인자는 다음과 같다
    - `type`: 디바이스 드라이버에 고유하게 할당된 1바이트 정수
    - `number`: ioctl 명령마다의 고유 번호
    - `data_type`: 클라이언트와 드라이버간에 교환되는 바이트 수를 계산하는데 사용되는 유형

    - 데이터의 입력, 출력, 쓰기가 가능한 매크로를 다음과 같이 선언할 수 있다.

        ```c
        struct ioctl_info{
            unsigned long size;
            unsigned int buf[128];
        };
        
        #define             IOCTL_MAGIC         'G'
        #define             SET_DATA            _IOW(IOCTL_MAGIC, 2 , ioctl_info )
        #define             GET_DATA            _IOR(IOCTL_MAGIC, 3 , ioctl_info )
        ```

        위 코드에서 SET_DATA 매크로는 `IOW()` 매크로를 사용했으며 type에는 `'G'`를 할당했다. <br> 또한 number에는 IOR 매크로와 서로 다른 번호를 할당했다. data_type에는 `ioctl_info` 구조체를 할당했다.

### IOCTL 사용법

```c
// chardev.h
#ifndef CHAR_DEV_H_
#define CHAR_DEV_H_
#include <linux/ioctl.h>
  
struct ioctl_info{
       unsigned long size;
       char buf[128];
};
   
#define             IOCTL_MAGIC         'G'
#define             SET_DATA            _IOW(IOCTL_MAGIC, 2 ,struct ioctl_info)
#define             GET_DATA            _IOR(IOCTL_MAGIC, 3 ,struct ioctl_info)
  
#endif
```

```c
// chardev.c
#include <linux/init.h>
#include <linux/module.h>
#include <linux/types.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/sched.h>
#include <linux/device.h>
#include <linux/slab.h>
#include <asm/current.h>
#include <linux/uaccess.h>
  
#include "chardev.h"
MODULE_LICENSE("Dual BSD/GPL");
  
#define DRIVER_NAME "chardev"
      
static const unsigned int MINOR_BASE = 0;
static const unsigned int MINOR_NUM  = 1;
static unsigned int chardev_major;
static struct cdev chardev_cdev;
static struct class *chardev_class = NULL;
 
static int     chardev_open(struct inode *, struct file *);
static int     chardev_release(struct inode *, struct file *);
static ssize_t chardev_read(struct file *, char *, size_t, loff_t *);
static ssize_t chardev_write(struct file *, const char *, size_t, loff_t *);
static long chardev_ioctl(struct file *, unsigned int, unsigned long);
 
struct file_operations s_chardev_fops = {
    .open    = chardev_open,
    .release = chardev_release,
    .read    = chardev_read,
    .write   = chardev_write,
    .unlocked_ioctl = chardev_ioctl,
};
 
static int chardev_init(void)
{
    int alloc_ret = 0;
    int cdev_err = 0;
    int minor = 0;
    dev_t dev;
  
    printk("The chardev_init() function has been called.");
      
    alloc_ret = alloc_chrdev_region(&dev, MINOR_BASE, MINOR_NUM, DRIVER_NAME);
    if (alloc_ret != 0) {
        printk(KERN_ERR  "alloc_chrdev_region = %d\n", alloc_ret);
        return -1;
    }
    //Get the major number value in dev.
    chardev_major = MAJOR(dev);
    dev = MKDEV(chardev_major, MINOR_BASE);
  
    //initialize a cdev structure
    cdev_init(&chardev_cdev, &s_chardev_fops);
    chardev_cdev.owner = THIS_MODULE;
  
    //add a char device to the system
    cdev_err = cdev_add(&chardev_cdev, dev, MINOR_NUM);
    if (cdev_err != 0) {
        printk(KERN_ERR  "cdev_add = %d\n", alloc_ret);
        unregister_chrdev_region(dev, MINOR_NUM);
        return -1;
    }
  
    chardev_class = class_create(THIS_MODULE, "chardev");
    if (IS_ERR(chardev_class)) {
        printk(KERN_ERR  "class_create\n");
        cdev_del(&chardev_cdev);
        unregister_chrdev_region(dev, MINOR_NUM);
        return -1;
    }
  
    device_create(chardev_class, NULL, MKDEV(chardev_major, minor), NULL, "chardev%d", minor);
    return 0;
}
  
static void chardev_exit(void)
{
    int minor = 0;
    dev_t dev = MKDEV(chardev_major, MINOR_BASE);
      
    printk("The chardev_exit() function has been called.");
 
    device_destroy(chardev_class, MKDEV(chardev_major, minor));
  
    class_destroy(chardev_class);
    cdev_del(&chardev_cdev);
    unregister_chrdev_region(dev, MINOR_NUM);
}
 
static int chardev_open(struct inode *inode, struct file *file)
{
    printk("The chardev_open() function has been called.");
    return 0;
}
  
static int chardev_release(struct inode *inode, struct file *file)
{
    printk("The chardev_close() function has been called.");
    return 0;
}
  
static ssize_t chardev_write(struct file *filp, const char __user *buf, size_t count, loff_t *f_pos)
{
    printk("The chardev_write() function has been called.");  
    return count;
}
  
static ssize_t chardev_read(struct file *filp, char __user *buf, size_t count, loff_t *f_pos)
{
    printk("The chardev_read() function has been called.");
    return count;
}
  
static struct ioctl_info info; //헤더파일에 선언된 ioctl_info
static long chardev_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
    printk("The chardev_ioctl() function has been called.");
  
    switch (cmd) {
        case SET_DATA:
            printk("SET_DATA\n");
            if (copy_from_user(&info, (void __user *)arg, sizeof(info))) {
                return -EFAULT;
            }
        printk("info.size : %ld, info.buf : %s",info.size, info.buf);
            break;
        case GET_DATA:
            printk("GET_DATA\n");
            if (copy_to_user((void __user *)arg, &info, sizeof(info))) {
                return -EFAULT;
            }
            break;
        default:
            printk(KERN_WARNING "unsupported command %d\n", cmd);
  
        return -EFAULT;
    }
    return 0;
}
 
module_init(chardev_init);
module_exit(chardev_exit);
```

- 유저 영역에서 `ioctl()`을 호출하면, 시스템 콜을 통해서 sys_ioctl이 호출되고 file_operations 구조체에 등록된 ioctl 함수가 수행된다. 이게 바로 위 코드에선 `chardev_ioctl()`이다.

- ioctl 두번째 인자로 들어온 커맨드에 따라서 분기를 하게 되는데, `SET_DATA` 커맨드이면 선언한 매크로가 수행되고, `copy_from_user()` 함수를 통해 arg에 담긴 값이 inof 구조체에 저장된다. 즉 유저영역의 값이 커널영역에 저장된다. `GET_DATA` 커맨드가 들어오면 `copy_to_user()` 함수에 의해 커널에 저장된 값을 arg로 복사한다.
  
- makefile을 이용해서 빌드해보자.

    ```makefile
    obj-m += chardev.o

    all:
        make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules
    clean:
        make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
    ```

    ```bash
    ╭─rlaisqls@ubuntu ~/Desktop/kernel_study/develop_kermod/start_ioctl 
    ╰─$ make                                                                                         1 ↵
    make -C /lib/modules/5.4.0-53-generic/build M=/home/rlaisqls/Desktop/kernel_study/develop_kermod/start_ioctl modules
    make[1]: Entering directory '/usr/src/linux-headers-5.4.0-53-generic'
    CC [M]  /home/rlaisqls/Desktop/kernel_study/develop_kermod/start_ioctl/chardev.o
    Building modules, stage 2.
    MODPOST 1 modules
    CC [M]  /home/rlaisqls/Desktop/kernel_study/develop_kermod/start_ioctl/chardev.mod.o
    LD [M]  /home/rlaisqls/Desktop/kernel_study/develop_kermod/start_ioctl/chardev.ko
    make[1]: Leaving directory '/usr/src/linux-headers-5.4.0-53-generic'
    ╭─rlaisqls@ubuntu ~/Desktop/kernel_study/develop_kermod/start_ioctl 
    ╰─$ ls
    chardev.c  chardev.ko   chardev.mod.c  chardev.o  modules.order
    chardev.h  chardev.mod  chardev.mod.o  Makefile   Module.symvers
    ╭─rlaisqls@ubuntu ~/Desktop/kernel_study/develop_kermod/start_ioctl 
    ╰─$
    ```

- 성공적으로 빌드 되었다. 이제 insmod로 `chardev.ko` 모듈을 올리면 `/dev/chardev0` 디바이스 파일이 생성될 것이다.

    ```bash
    ╭─rlaisqls@ubuntu ~/Desktop/kernel_study/develop_kermod/start_ioctl 
    ╰─$ ls -al /dev | grep 'chardev*'
    crw-------   1 root     root    240,   0 Nov 17 23:51 chardev0
    ```

- 이제 테스트 코드로 `ioctl()`이 정상적으로 동작하는지 확인해보자.

    ```c
    // test.c
    #include <stdio.h>
    #include <stdlib.h>
    #include <fcntl.h>
    #include <unistd.h>
    #include <errno.h>
    #include <string.h>
    #include <sys/ioctl.h>
    #include "chardev.h"
    
    int main()
    {
        int fd;
        struct ioctl_info set_info;
        struct ioctl_info get_info;
    
        set_info.size = 100;
        strncpy(set_info.buf,"lazenca.0x0",11);
    
        if ((fd = open("/dev/chardev0", O_RDWR)) < 0){
            printf("Cannot open /dev/chardev0. Try again later.\n");
        }
    
        if (ioctl(fd, SET_DATA, &set_info) < 0){
            printf("Error : SET_DATA.\n");
        }
    
    
        if (ioctl(fd, GET_DATA, &get_info) < 0){
            printf("Error : SET_DATA.\n");
        }
    
        printf("get_info.size : %ld, get_info.buf : %s\n", get_info.size, get_info.buf);
    
        if (close(fd) != 0){
            printf("Cannot close.\n");
        }
        return 0;
    }
    ```

- `chardev.h`에 구현한 ioctl_info 구조체 변수를 두개 선언한다.`(set_info, get_info)`.`strncpy()` 함수를 이용하여 `set_info.buf` 필드에 문자열을 복사한다.

- 그다음 생성된 `/dev/chardev0` 파일을 열고, `ioctl()` 함수로 `set_info` 구조체를 커널영역의 버퍼에 복사한다. 즉 위에서 복사한 문자열이 커널 버퍼에 복사될 것이다.

- 마지막으로 `ioctl()` 함수로 GET_DATA 매크로와 get_info 구조체를 인자로 주어 아까 복사한 데이터를 get_info 구조체 변수에 복사한다. `ioctl()`을 통해 정상적으로 데이터를 읽어왔다면, `get_info.buf` 필드에 `"lazenca.0x0"` 이 출력될 것이다.

    ```c
    [  265.554111] The chardev_init() function has been called.
    [  603.361097] The chardev_open() function has been called.
    [  603.361100] The chardev_ioctl() function has been called.
    [  603.361100] SET_DATA
    [  603.361102] info.size : 100, info.buf : lazenca.0x0
    [  603.361103] The chardev_ioctl() function has been called.
    [  603.361104] GET_DATA
    root@ubuntu:/home/rlaisqls/Desktop/kernel_study/develop_kermod/start_ioctl# ./test
    get_info.size : 100, get_info.buf : lazenca.0x0
    ```

- dmesg 결과와 `./test` 를 실행해보면, 생각한대로 잘 출력된다. 즉 `ioctl()`이 정상동작하여 input, output이 잘 구현되었다.

---
참고
- https://man7.org/linux/man-pages/man2/ioctl.2.html
- https://github.com/torvalds/linux/blob/master/include/uapi/asm-generic/ioctl.h