# 修改无线MAC脚本
![Shell](https://img.shields.io/badge/-Shell-brightgreen) ![Bash](https://img.shields.io/badge/-Bash-brightgreen) 

## 重要提醒：

使用此脚本会修改factory分区，有变砖的风险，务必备份好eeprom，以免彻底变砖。使用此脚本，路由器要能恢复eeprom，支持间接恢复eeprom也可以，**如果路由器没办法恢复eeprom，请不要使用此脚本**。

## 使用条件：

固件中的factory分区必须是可修改的（factory分区没有写保护），如果不支持修改，需要自行编译一个factory分区没有写保护的固件。

## 适用固件：

`OpenWRT/LEDE`、`Padavan`、`Pandorabox`

## 用途：

`万能中继蹭网，防踢。`

## 脚本参数：

> * **-m（选填）：** 自定义mac参数，要修改成什么mac，忽略大小写，默认值随机mac，例如：-m AA:BB:CC:DD:EE:FF。
> * **-s（选填）：** 自定义seek参数，要跳过几个字节，默认值4，等同偏移量，这个值需要根据路由器的factory分区进行调整。
> * **-t（选填）：** 时间mac，使用此参数会将mac的后十位数变成时间，可以记录什么时候更换的mac，建议选上。
> * **-b（选填）：** 备份恢复，使用后，可以恢复原始的mac。



## 使用方法：

* **编译进固件：**
> 将此仓库克隆到固件源代码/package/目录下，选上Utilities ---> changewmac。
* **直接在固件中使用：**
> 去掉计划任务中（/etc/crontabs/root）的注释#，如下所示。
```diff
- # */30 * * * * /etc/storage/mac/changewmac.sh
+ */30 * * * * /etc/storage/mac/changewmac.sh
```

## 编译固件时去除factory写保护：

1. 确定要编译的路由器的型号，搜索dts，进入文件夹，去掉对应型号的dts中factory分区的read-only，保存退出。
2. 选上Utilities ---> Other modules ---> kmod-mtd-rw（选中插件时会自动勾选上此依赖）。



## 常见问题：

**Q：为什么重启后没有显示WiFi，网线也没办法识别？**

A：恭喜你，路由器变砖了，恢复下eeprom，重启后就正常了。



**Q：为什么执行脚本后，正常使用，但是mac没有任何变化？**

A：
> 1. 手动执行脚本，看看运行过程中有没有报错，有报错就解决报错。
> 2. 去breed中看看mac有没有变化，如果breed中的mac变化了，固件中的mac却没变，证明这种固件没办法使用此脚本。
