#!/bin/sh




### 常用工具函数 ###
output_log()
{
	echo -e "$1"
	logger -t changewmac -p cron.info `echo -e "$1"`
}
countdown_reboot() {
	# 倒计时（单位：秒）
	countdown=$1
	for i in `seq $countdown -1 1`
	do
		output_log "$i秒后，重启系统"
		sleep 1
	done

	# 输出日志
	output_log "正在重启系统 ..."
	# 重启系统
	reboot
}




### 脚本参数相关函数 ###
check_params() {
	# 判断空字符
	[ -z "$1" ] && {
		# 输出日志
		output_log "参数为空，采用随机mac和默认seek"
		# 参数为空，采用随机mac和默认seek
		return
	}
	
	# 定义一个异常参数标志
	error=1
	
	# 查找参数-b
	param=`echo "$1" | grep "\-b"`
	[ -z "$param" ] || {
		# 参数无异常
		error=0
		# 存在-b参数不检查后面的参数，直接恢复备份数据
		return
	}	
	
	# 查找参数-m
	param=`echo "$1" | grep "\-m"`
	[ -z "$param" ] || {
		# 参数无异常
		error=0

		# 获取参数mac
		m=`echo "$1" | awk -F '-m ' '{printf("%s", $2)}' | awk '{printf("%s\n", $1)}'`
		if [ -z "$m" ] ; then
			# 输出日志，mac参数值异常（有mac参数却无法获取mac参数值）
			output_log "mac参数值异常，请输入mac参数值，e.g. AA:BB:CC:DD:EE:FF"
			# 异常退出
			exit 1
		else
			check_mac "$m"
		fi
	}
	
	# 查找参数-s
	param=`echo "$1" | grep "\-s"`
	[ -z "$param" ] || {
		# 参数无异常
		error=0

		# 获取参数seek
		s=`echo "$1" | awk -F '-s ' '{printf("%s", $2)}' | awk '{printf("%s\n", $1)}'`
		if [ -z "$s" ] ; then
			# 输出日志，seek参数值异常（有seek参数却无法获取seek参数值）
			output_log "seek参数值异常，请输入seek参数值，e.g. 4、32772"
			# 异常退出
			exit 1
		else
			check_seek "$s"
		fi
	}
	
	# 查找参数-t
	param=`echo "$1" | grep "\-t"`
	[ -z "$param" ] || {
		# 参数无异常
		error=0
	}
	
	[ $error -eq 1 ] && {
		# 输出日志，参数异常（有参数却无法获取正确的参数）
		output_log "参数异常，支持参数-m（自定义mac）、-s（偏移量seek）、-t（时间型随机mac）、-b（恢复原始无线数据分区），e.g. \"-m AA:BB:CC:DD:EE:FF\"、\"-s 32772\"、\"-t\"、\"-b\""
		# 异常退出
		exit 1
	}
}
check_mac() {
	# 匹配mac格式
	mac_spec=`echo "$1" | sed -r 's/^(([0-9a-fA-F]{2}:){5}([0-9a-fA-F]{2}))$//g'`
	if [ -z "$mac_spec" ] ; then
		mac_2ndchar=`echo "$1" | sed -r 's/^.[02468aceACE].*$//g'`
		[ -z "$mac_2ndchar" ] || {
			# 输出日志
			output_log "无线mac的第二个字母必须为16进制偶数，e.g. 0、2、4、6、8、a、c、e、A、C、E"
			# 异常退出
			exit 1
		}
	else
		# 输出日志
		output_log "请输入正确的mac参数，e.g. AA:BB:CC:DD:EE:FF"
		# 异常退出
		exit 1
	fi
}
check_seek() {
	# 匹配seek格式
	seek_spec=`echo "$1" | sed -r 's/^([0-9]*)$//g'`
	if [ -z "$seek_spec" ] ; then
		# 指定seek范围
		[ $1 -ge 0 -a $1 -le 65536 ] || {
			# 输出日志
			output_log "seek值只能在区间0-65536，e.g. 4、32772"
			# 异常退出
			exit 1
		}
	else
		# 输出日志
		output_log "seek值只能为正整数，e.g. 4、32772"
		# 异常退出
		exit 1
	fi
}




### 备份相关函数 ###
check_backup() {
	# 获取当前脚本的基础路径
	basepath=$(cd `dirname $0`; pwd)
	# 获取备份文件的文件路径
	backup_path="${basepath}/factory_backup.bin"
	
	# 1表示存在备份，0表示不存在备份
	if [ -e "$backup_path" ] ; then
		echo "1:$backup_path"
	else
		echo "0:$backup_path"
	fi
}
restore_save_backup() {
	# 获取脚本参数
	params_script=$1
	# 获取mtd名
	param_mtd=$2
	# 获取分区名
	param_partition=$3
	# 获取写入命令
	param_command_write=$4
	
	# 检查备份文件是否存在
	backup=`check_backup | awk -F ':' '{print($1)}'`
	# 获取备份文件路径
	backup_path=`check_backup | awk -F ':' '{print($2)}'`
	
	if [ $backup -eq 1 ] ; then
		# 查找参数-b
		param=`echo "$params_script" | grep "\-b"`
		[ -z "$param" ] || {
			# 输出日志
			output_log "正在恢复原始无线数据分区 ..."
			
			# 存在-b参数，恢复原始无线数据分区
			"$param_command_write" write "$backup_path" "$param_partition"
			
			# 10s后重启
			countdown_reboot 10
			
			# 正常退出
			exit 0
		}
	else		
		# 输出日志
		output_log "正在备份无线数据分区 ..."
		# 备份无线数据分区
		dd if=/dev/"$param_mtd" of="$backup_path"
	fi
}




### mac与seek相关函数 ###
rand() {
	# 起始值
	min=$1
	# 终止值
	max=$(( $2 - $min + 1 ))
	# 秒+纳秒的输出，让数字变化呈现随机性
	num=`date +%s`
	# 余数（余数是不可能大于除数的，所以除数n可以被用来限制数字范围）：%n
	echo "$(( $num % $max + $min ))"
}
get_random_mac()
{
	# 生成第一个随机字符
	mac_1stchar=`echo "$(rand 0 15)" | awk '{printf("%x\n", $0)}'`
	# 生成第二个随机字符
	# 偶数（任意自然数乘以2就是偶数）：2n
	# 余数（余数是不可能大于除数的，所以除数n可以被用来限制数字范围）：%n
	mac_2ndchar=`echo "$(( $(rand 0 15) * 2 % 16 ))" | awk '{printf("%x\n", $0)}'`

	# 拼接两个随机字符
	mac_2char="$mac_1stchar$mac_2ndchar"
	
	if [ -z "$1" ] ; then
		# 生成10个随机uuid字符
		mac_10char=`cat /proc/sys/kernel/random/uuid | cut -c 27-`
	else
		# 生成10个时间字符
		mac_10char=`date +%m%d%H%M%S`
	fi
	
	# 拼接整个随机mac字符并转换成大写
	random_mac=`echo "$mac_2char$mac_10char" | tr 'a-z' 'A-Z' | sed -r 's/^(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})$/\1:\2:\3:\4:\5:\6/g'`
	
	echo "$random_mac"
}
get_mac()
{
	# 判断是否使用自定义mac
	m=`echo "$1" | awk -F '-m ' '{printf("%s", $2)}' | awk '{printf("%s\n", $1)}'`
	if [ -z "$m" ] ; then
		# 定义mac类型1为随机mac
		mac_type=1
		
		# 查找参数-t，存在-t参数则采用时间型随机mac
		param=`echo "$1" | grep "\-t"`
		if [ -z "$param" ] ; then
			mac=`get_random_mac`
		else
			mac=`get_random_mac "-t"`
		fi
	else
		# 定义mac类型2为自定义mac
		mac_type=2
		
		# 将mac转换成大写
		mac=`echo "$m" | tr 'a-z' 'A-Z'`
	fi
	
	# 不能用:做变量分隔符，因为mac中包含:
	echo "$mac_type-$mac"
}
get_seek()
{
	# 判断是否使用自定义seek
	s=`echo "$1" | awk -F "-s " '{printf("%s", $2)}' | awk '{printf("%s\n", $1)}'`
	if [ -z "$s" ] ; then
		# 定义seek类型1为默认seek
		seek_type=1
		
		# 使用默认seek
		seek=4
	else
		# 定义seek类型2为自定义seek
		seek_type=2
		
		# 使用自定义seek
		seek=`echo "$s"`
	fi
	
	echo "$seek_type:$seek"
}




### mtd名和分区名相关函数 ###
find_name()
{
	# mtd_string='mtd2: 00010000 00001000 factory'
	mtd_string=`cat /proc/mtd 2> /dev/null`
	
	# openwrt
	searchString1="factory"
	# pandorabox
	searchString2="Factory"
	# AR机器
	searchString3="ART"

	# 确定分区名
	case $mtd_string in 
	*$searchString1*)
		partition_name=$searchString1
		;;
	*$searchString2*)
		partition_name=$searchString2
		;;
	*$searchString3*)
		partition_name=$searchString3
		;;
	*)
		echo "Can't find correct partition name"
		return
	esac

	# 确定mtd名
	mtd_name=`echo "$mtd_string" | grep "$partition_name" | awk -F ':' '{print($1)}'`
	echo "${mtd_name}:${partition_name}"
}




### dd命令和factory分区相关函数 ###
check_dd_factory()
{
	# 查找dd命令帮助中是否包含notrunc字符串
	dd_param=`dd --help 2>&1 | grep "notrunc"`
	[ -z "$dd_param" ] && {
		# 输出日志
		output_log "dd命令不完整，缺少参数conv=notrunc"
		# 异常退出
		exit 1
	}
	
	factory=`"$param_command_write" write /tmp/factory_backup.bin "$param_partition" 2>&1 | grep "Could not open"`
	[ -z "$factory" ] || {
		# 输出日志
		output_log "factory分区不可写"
		# 异常退出
		exit 1
	}
	
}




### 主函数 ###
main()
{
	# 定义外部参数
	param_mtd="$1"
	param_partition="$2"
	param_command_write="$3"
	param_mac="$4"
	param_seek="$5"
	
	# 输出日志
	output_log "正在检查网络状况，请稍等一会儿 ..."
	# ping检测网络状况
	ping_text=`ping -4 223.5.5.5 -c 1 -w 4 -q 2> /dev/null`
	# 截取ping结果
	ping_time=`echo $ping_text | awk -F '/' '{print($4)}'| awk -F '.' '{print($1)}'`
	# 判断Internet互联网是否正常
	if [ -z "$ping_time" ] ; then
		# 输出日志
		output_log "网络断开，准备切换无线mac"
		
		# 获取mac类型和mac值
		echo "$param_mac" | awk -F '-' '{print($1, $2)}' | while read mac_type mac
		do
			# 判断mac类型是否为自定义，mac类型1为随机mac，2为自定义mac
			mac_type=`echo $mac_type | grep "1"`
			if [ -z "$mac_type" ] ; then
				# 输出日志
				output_log "自定义mac参数------>$mac"
			else
				# 输出日志
				output_log "未检测到自定义mac参数，生成随机mac------>$mac"
			fi
			
			# 将mac转换成16进制格式
			mac_hex=`echo "$mac" | sed 's/:/\\\x/g'`
			mac_hex=`echo "\\x""$mac_hex"`
			
			# 将mac写入临时文件
			echo -e -n "$mac_hex" > /tmp/mac.bin
			
			# 获取seek类型和seek值
			echo "$param_seek" | awk -F ':' '{print($1, $2)}' | while read seek_type seek
			do
				# 判断seek类型是否为自定义，seek类型1为默认seek，2为自定义seek
				seek_type=`echo $seek_type | grep "1"`
				if [ -z "$seek_type" ] ; then
					# 输出日志
					output_log "自定义seek参数------>$seek"
				else
					# 输出日志
					output_log "默认seek参数------>$seek"
				fi		
				
				# 输出日志
				output_log "跳过$seek字节，正在将$mac写入复制的无线数据分区块$(( $seek + 1 ))-$(( $seek + 1 + 6 ))中"
				# 替换临时无线数据分区中的无线mac，seek值表示跳过n字节（n一般为4，从第5个字节开始是大部分路由器factory的无线mac位置，有时候5G的mac是从32773个字节开始，具况具析），count值表示写入6个字节，conv=notrunc表示不截断输出
				dd if=/tmp/mac.bin of=/tmp/factory_backup.bin bs=1 count=6 skip=0 seek="$seek" conv=notrunc
				
				# 输出日志
				output_log "正在将临时无线数据分区写入系统分区中 ..."
				# 将临时无线数据分区写入系统分区（openwrt的为factory，潘多拉固件为Factory，AR系列叫ART）
				"$param_command_write" write /tmp/factory_backup.bin "$param_partition"
				
				# 10s后重启
				countdown_reboot 10
			done
		done
	else
		# 输出日志
		output_log "网络正常，不切换无线mac"
	fi
}




### 入口函数 ###
run() {
	partition_name=`find_name | grep ":"`
	# 确保取到正确的分区名
	if [ -z "$partition_name" ] ; then
		# 输出日志
		output_log "无法找到正确的分区名"
		# 异常退出
		exit 1
	else
		# 分割mtd名和分区名
		mtd=`find_name | awk -F ':' '{print($1)}'`
		partition=`find_name | awk -F ':' '{print($2)}'`
		
		# 输出日志
		output_log "mtd：\t\t\t$mtd"
		output_log "partition：\t\t$partition"
		
		# 检测写入命令
		command_write=`(which mtd || which mtd_write || which mtd-write) | awk -F '/' '{print($NF)}'`
		if [ -z "$command_write" ] ; then
			# 输出日志
			output_log "无法找到可用的写入命令，e.g. mtd、mtd_write、mtd-write"
			# 异常退出
			exit 1
		else
			# 输出日志
			output_log "command_write：\t\t$command_write"
		fi
		
		# 恢复或保存无线数据分区
		restore_save_backup "$1" "$mtd" "$partition" "$command_write"
		
		# 输出日志
		output_log "正在创建临时无线数据分区 ..."
		# 创建临时无线数据分区
		dd if=/dev/"$param_mtd" of=/tmp/factory_backup.bin
		
		# 检测dd命令和factory分区
		check_dd_factory
		
		# 检测参数
		check_params "$1"
		
		# 获取mac类型及mac值
		mac=`get_mac "$1"`
		# 获取seek类型及seek值
		seek=`get_seek "$1"`
		
		# 运行主要代码
		main "$mtd" "$partition" "$command_write" "$mac" "$seek"
	fi
}




# 入口
run "$*"




