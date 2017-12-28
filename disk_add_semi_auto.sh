#!/bin/bash -x

#################### Ver.1.2.1 (2017.12.28) #####################
usage() {
        echo "Usage: $0 [-s config_file] " 1>&2
        exit
}

flg=0

while getopts cs: opt
do
    case $opt in
        s)  flg=1
            cnf_file=$OPTARG
            ;;
        \?) usage
            ;;
    esac
done

shift $((OPTIND - 1))

work_color_on="\e[32m"
comment_color_on="\e[34m"
question_color_on="\e[35m"
error_color_on="\e[31m"
color_off="\e[m"
log_file="disk_add_`date +%Y%m%d`.log"

service_list=()
service_list_tmp=("cyde" "cyss" "ofss" "httpd" "cbrs")
pv_list=()
dev_list=()
dev_list_tmp=()
vg_list=()
lv_list=()
l=0
m=0
n=0
i=0
j=0
k=0
a=0
b=0
c=0
x=0
z=0



if [ $flg -eq 1 ];then
  source ./$cnf_file
  log_file="disk_add_`date +%Y%m%d`.log"

  function output_msg() {
      local MSG="$*"
      local log_msg="$(date +'%Y/%m/%d %H:%M:%S') $MSG"

      echo $log_msg >> $log_file
  }
    
  DEFAULT_VG="VolGroup_varwww"
  DEFAULT_LV="LogVol01_varwww"
  
  server_name=${SERVER_NAME:-localhost}
  device_name=${DEVICE:-/dev/sdb}
  vg=${VG:-$DEFAULT_VG}
  lv=${LV:-$DEFAULT_LV}
  mount_point=${MOUNT_POINT:-/var/www}
  
  for dev_str in `ls /dev/ | grep sd |sed -e 's/[1-9]//g'| grep -vw sda | sort | uniq`; do
    dev_count=`ls /dev/ | grep $dev_str | wc -l`
    if [ $dev_count -eq 1 ];then
      dev_list_tmp[m]=$dev_str
      m=`expr $m + 1`
    else
      for dev_partition in `ls /dev/ | grep sd | grep $dev_str | grep -vw $dev_str`; do
        dev_list_tmp[m]=$dev_partition
        m=`expr $m + 1`
      done
    fi
  done
  
  for pv_name in `pvscan | grep PV |awk '{print $2}' | sed -e 's/\/dev\///g' ` ; do
    pv_list[n]=$pv_name
    n=`expr $n + 1`
  done
  
  for dev_name in ${dev_list_tmp[@]}; do
    check=`echo ${pv_list[@]} | grep $dev_name`
    if [ "$check" == "" ]; then
      dev_list[i]=$dev_name
      i=`expr $i + 1`
    fi
  done
  
  for vg_name in `vgdisplay | grep "VG Name"|awk '{print $3}'`; do
    vg_list[j]=$vg_name
    j=`expr $j + 1`
  done
  
  for lv_name in `lvdisplay | grep "LV Path"| grep $vg |awk '{print $3}'`; do
    lv_list[k]=$lv_name
    k=`expr $k + 1`
  done
  
  echo "<<< Setting contents"
  if [ "${server_name}" != `uname -n` ];then
    echo -e ${error_color_on}"HostName Error!!!!!!!!!!"${color_off}
    echo -e ${error_color_on}"Setting File:"${server_name}${color_off}
    echo -e ${error_color_on}"This Server:"`uname -n`${color_off}
    echo -e ${error_color_on}"Check once more to make sure the setting file are correct."${color_off}
    echo -e ${error_color_on}"Bye."${color_off}
    output_msg "Error:HostName Error!!!!!!!!!!"
    exit
  else
    echo -e ${work_color_on}"HostName : "${server_name}${color_off}
  fi
  
  check=`echo ${dev_list[@]} | grep $device_name`
  if [ "$check" == "" ]; then
    echo -e ${error_color_on}"Device Select Miss!!!!!!!!!!"${color_off}
    echo -e ${error_color_on}"Setting File:"${device}${color_off}
    echo -e ${error_color_on}"Selectable devices on this server:"${color_off}${dev_list[@]}
    echo -e ${error_color_on}"Check once more to make sure the setting file are correct."${color_off}
    echo -e ${error_color_on}"Bye."${color_off}
    output_msg "Error:Device Select Miss!!!!!!!!!!"
    exit
  else
    device="/dev/"${device_name}
    if [ `echo ${device} | grep "1"` ]; then
      echo -e ${work_color_on}"Add HDD : "${device}"(skip partition creation)"${color_off}
      l=1
    else
      echo -e ${work_color_on}"Add HDD : "${device}${color_off}
    fi
  fi
  
  check=`echo  ${vg_list[@]} | grep $vg`
  if [ "$check" == "" ]; then
    echo -e ${error_color_on}"Volume Group Select Miss!!!!!!!!!!"${color_off}
    echo -e ${error_color_on}"Setting File:"${vg}${color_off}
    echo -e ${error_color_on}"Selectable Volume Group on this server:"${color_off}${vg_list[@]}
    echo -e ${error_color_on}"Check once more to make sure the setting file are correct."${color_off}
    echo -e ${error_color_on}"Bye."${color_off}
    output_msg "Error:Volume Group Select Miss!!!!!!!!!!"
    exit
  else
    echo -e ${work_color_on}"VG Name : "${vg}${color_off}
  fi
  
  check=`echo  ${lv_list[@]} | grep $lv`
  if [ "$check" == "" ]; then
    echo -e ${error_color_on}"Logical Volume Select Miss!!!!!!!!!!"${color_off}
    echo -e ${error_color_on}"Setting File:"${lv}${color_off}
    echo -e ${error_color_on}"Selectable Logical Volume on this server:"${color_off}${lv_list[@]}
    echo -e ${error_color_on}"Check once more to make sure the setting file are correct."${color_off}
    echo -e ${error_color_on}"Bye."${color_off}
    output_msg "Error:Logical Volume Select Miss!!!!!!!!!!"
    exit
  else
    for lv_name_tmp in ${lv_list[@]}; do
      check=`echo $lv_name_tmp | grep $lv`
      if [ "$check" != "" ];then
        lv_name=$lv_name_tmp
        size=`lvdisplay $lv_name |grep "LV Size" | awk '{print $3 $4}'`
        echo -e ${work_color_on}"LV Name : "${lv_name}"("$size")"${color_off}
      fi
    done
  fi
  
  set_lv=( `echo ${lv_name} | tr -s '/' ' '`)
  count_arr=`expr ${#set_lv[*]} - 1`
  mount_point_org=`cat /etc/mtab | grep ${set_lv[count_arr]} | awk '{print $2}'`
  if [ "$mount_point_org" != "$mount_point" ]; then
    echo -e ${error_color_on}"Mount Point Select Miss!!!!!!!!!!"${color_off}
    echo -e ${error_color_on}"Setting File :"${mount_point}${color_off}
    echo -e ${error_color_on}"Current Mount Point :"$mount_point_org${color_off}
    echo -e ${error_color_on}"Check once more to make sure the setting file are correct."${color_off}
    echo -e ${error_color_on}"Bye."${color_off}
    output_msg "Error:Mount Point Select Miss!!!!!!!!!!"
    exit
  else
    echo -e ${work_color_on}"Mount Point : "${mount_point}${color_off}
  fi
  echo -e ${question_color_on}"Can I work with this setting?(y/n)"${color_off}
  echo ">>>"
  read a
  if [ "$a" != "y" ];then
    echo -e ${work_color_on}"OK.To stop this work."${color_off}
    output_msg "Info:To stop this work."
    exit
  fi
  
  
  if [ $l -eq 1 ];then
    echo -e ${comment_color_on}"fdisk will not run"${color_off}
    output_msg "Info:fdisk will not run"
  else
    fdisk ${device} << end
n
p
1


t
8e
w
end
  
    ret=$?
    if [ $ret -eq 0 ]; then
      echo -e ${work_color_on}"fdisk successful"${color_off}
      output_msg "Info:fdisk successful"
    else
      echo -e ${error_color_on}"fdisk failed"${color_off}
      echo -e ${error_color_on}"Check the status of the server and contact someone."${color_off}
      output_msg "Error:fdisk failed"
      exit $ret
    fi
  fi
  
  if [ $l -eq 1 ];then
    pvcreate ${device}
    ret=$?
    if [ $ret -eq 0 ]; then
       echo -e ${work_color_on}"pvcreate successful"${color_off}
       output_msg "Info:pvcreate successful"
    else
       echo -e ${error_color_on}"pvcreate failed"${color_off}
       echo -e ${error_color_on}"Check the status of the server and contact someone."${color_off}
       output_msg "Error:pvcreate failed"
       exit $ret
    fi
  else
    pvcreate ${device}1
    ret=$?
    if [ $ret -eq 0 ]; then
       echo -e ${work_color_on}"pvcreate successful"${color_off}
       output_msg "Info:pvcreate successful"
    else
       echo -e ${error_color_on}"pvcreate failed"${color_off}
       echo -e ${error_color_on}"Check the status of the server and contact someone."${color_off}
       output_msg "Error:pvcreate failed"
       exit $ret
    fi
  fi
  
  if [ $l -eq 1 ];then
    vgextend $vg ${device}
    ret=$?
    if [ $ret -eq 0 ]; then
       echo -e ${work_color_on}"vgextend successful"${color_off}
       output_msg "Info:vgextend successful"
    else
       echo -e ${error_color_on}"vgextend failed"${color_off}
       echo -e ${error_color_on}"Check the status of the server and contact someone."${color_off}
       output_msg "Error:vgextend failed"
       exit $ret
    fi
  else
    vgextend $vg ${device}1
    ret=$?
    if [ $ret -eq 0 ]; then
       echo -e ${work_color_on}"vgextend successful"${color_off}
       output_msg "Info:vgextend successful"
    else
       echo -e ${error_color_on}"vgextend failed"${color_off}
       echo -e ${error_color_on}"Check the status of the server and contact someone."${color_off}
       output_msg "Error:vgextend failed"
       exit $ret
    fi
  fi
  
  vgdisplay -v $vg
  
  e=`vgdisplay $vg | grep "Free  PE / Size" | awk '{print $5}'`
  
  lvextend -l +${e} ${lv_name}
  ret=$?
  if [ $ret -eq 0 ]; then
     echo -e ${work_color_on}"lvextend successful"${color_off}
     output_msg "Info:lvextend successful"
  else
     echo -e ${error_color_on}"lvextend failed"${color_off}
     echo -e ${error_color_on}"Check the status of the server and contact someone."${color_off}
     output_msg "Error:lvextend failed"
     exit $ret
  fi
  
  resize2fs ${lv_name}
  ret=$?
  if [ $ret -eq 0 ]; then
     echo -e ${work_color_on}"resize2fs successful"${color_off}
     output_msg "Info:resize2fs successful"
  else
     echo -e ${error_color_on}"resize2fs failed"${color_off}
     echo -e ${error_color_on}"Check the status of the server and contact someone."${color_off}
     output_msg "Error:resize2fs failed"
     exit $ret
  fi
  
  df -h
  lvscan
  pvscan
  
  echo -e ${work_color_on}"Disk expansion is completed."${color_off}
  output_msg "Info:Disk expansion is completed."
  
  n=0
  echo -e ${work_color_on}"Service list to be started"${color_off}
  for service_name in ${service_list_tmp[@]}; do
    service_exist=`ls /etc/init.d/ | grep ${service_name}`
    if [ $? -eq 0 ]; then
      echo "  "$service_exist
      service_list[n]=$service_exist
      n=`expr $n + 1`
    fi
  done
  if [ $n -eq 0 ];then
    echo "  Nothing!"
  else
    echo -e ${question_color_on}"Do you also start the service?(y/n)"${color_off}
    echo ">>>"
    read g
  fi
  
  if [ "$g" == "y" ]; then
    echo -e ${work_color_on}"Start service startup"${color_off}
  
    for start_service in ${service_list[@]}; do
         /etc/init.d/${start_service} status
         if [ $? -ne 0 ]; then
           echo -e ${work_color_on}"turn of "${start_service}${color_off}
           /etc/init.d/${start_service} start
           if [ $? -ne 0 ]; then
             echo -e ${error_color_on}"Failed to start "${start_service}${color_off}
             output_msg "Error:Failed to start "${start_service}
             exit
           fi
           chkconfig ${start_service} on
           if [ $? -ne 0 ]; then
             echo -e ${error_color_on}"Failed to set the automatic startup of "${start_service}${color_off}
             output_msg "Error:Failed to set the automatic startup of "${start_service}
             exit
           fi
  
           m=0
           while [ $n -le 10 ]; do
             /etc/init.d/${start_service} status
             if [ $? -ne 0 ]; then
               echo -e ${comment_color_on}"Just a minute..."${color_off}
               sleep 5s
               n=`expr $n + 1`
             else
               m=1
               break
             fi
           done
           if [ $m -ne 1 ]; then
             echo -e ${error_color_on}"On balance, failed to start "${start_service}${color_off}
             output_msg "Error:On balance, failed to start "${start_service}
             exit
           fi
  
           check_auto=`chkconfig --list ${start_service} | awk '{print $5}'`
           if [ $check_auto == "3:off" ]; then
             echo -e ${error_color_on}"On balance, failed to set the automatic startup of "${start_service}${color_off}
             output_msg "Error:On balance, failed to set the automatic startup of "${start_service}
             exit
           else
             chkconfig --list ${start_service}
           fi
        else
          echo -e ${comment_color_on}${start_service}" is already running."${color_off}
        fi
      done
      echo -e ${work_color_on}"Service startup is completed."${color_off}
      output_msg "Info:Service startup is completed."
  else
      echo -e ${work_color_on}"Service startup is skipped."${color_off}
      output_msg "Info:Service startup is skipped."
  fi
  
  echo -e ${comment_color_on}"Please do the your remaining work."${color_off}
  echo -e ${comment_color_on}"See you next time!"${color_off}
  rm -f $cnf_file
else
  setting_file="./setting.cfg"

  for dev_str in `ls /dev/ | grep sd |sed -e 's/[1-9]//g'| grep -vw sda | sort | uniq`; do
    dev_count=`ls /dev/ | grep $dev_str | wc -l`
    if [ $dev_count -eq 1 ];then
      dev_list_tmp[m]=$dev_str
      m=`expr $m + 1`
    else
      for dev_partition in `ls /dev/ | grep sd | grep $dev_str | grep -vw $dev_str`; do
        dev_list_tmp[m]=$dev_partition
        m=`expr $m + 1`
      done
    fi
  done

  for pv_name in `pvscan | grep PV |awk '{print $2}' | sed -e 's/\/dev\///g' ` ; do
    pv_list[n]=$pv_name
    n=`expr $n + 1`
  done

  echo -e ${work_color_on}"Starting setting file create"${color_off}
  while [ "$d" != "y" ]; do
    while [ $a -ge $i -o $a -lt 0 ]; do
      i=0
      echo "<<< HDD list"
      for dev_name in ${dev_list_tmp[@]}; do
        check=`echo ${pv_list[@]} | grep $dev_name`
        if [ "$check" == "" ]; then
          echo $i:/dev/$dev_name
          dev_list[i]=/dev/$dev_name
          i=`expr $i + 1`
        fi
      done
      for pv_name in `pvscan | grep PV |awk '{print $2}'` ; do
        check=`pvdisplay $pv_name | grep "Free PE" | awk '{print $3}'`
        if [ $check -ne 0 ]; then
          dev_name=`echo $pv_name | sed -e 's/\/dev\///g'`
          echo $i:/dev/$dev_name"(Free PE Size:"$check")"
          dev_list[i]=/dev/$dev_name
          i=`expr $i + 1`
        fi
      done
      if [ $i -eq 0 ];then
        echo -e ${error_color_on}"There is no HDD that can be added."${color_off}
        x=1
        break
      else
        echo -e ${question_color_on}"Please select HDD number(0-`expr $i - 1`)"${color_off}
        echo ">>>"
        read a
        expr $a + 1 > /dev/null 2>&1
        ret=$?
        if [ $ret -gt 1 ]; then
          echo -e ${error_color_on}"Can't understand the entered value."${color_off}
          exit
        fi
      fi
    done

    if [ $x -eq 1 ];then
      check=""
    else
      check=`pvscan | grep ${dev_list[a]} | awk '{print $4}'`
    fi

    if [ "$check" != "" ]; then
      vg=$check
    else
      while [ $b -ge $j -o $b -lt 0 ]; do
        j=0
        echo "<<< VG list"
        vda_vg=`pvscan | grep VolGroup_root | awk '{print $4}'`
        for vg_name in `vgdisplay | grep -v $vda_vg |grep "VG Name"|awk '{print $3}'`; do
          echo $j:$vg_name
          vg_list[j]=$vg_name
          j=`expr $j + 1`
        done
        echo -e ${question_color_on}"Please select VG number(0-`expr $j - 1`)"${color_off}
        echo ">>>"
        read b
        expr $b + 1 > /dev/null 2>&1
        ret=$?
        if [ $ret -gt 1 ]; then
          echo -e ${error_color_on}"Can't understand the entered value."${color_off}
          exit
        fi
      done
    fi
      vg=${vg_list[b]}

    while [ $c -ge $k -o $c -lt 0 ]; do
      k=0
      echo "<<< LV list"
      for lv_name in `lvdisplay | grep "LV Path"| grep $vg |awk '{print $3}'`; do
        size=`lvdisplay $lv_name |grep "LV Size" | awk '{print $3 $4}'`
        echo $k:$lv_name"($size)"
        lv_list[k]=$lv_name
        k=`expr $k + 1`
      done
      echo -e ${question_color_on}"Please select LV number(0-`expr $k - 1`)"${color_off}
      echo ">>>"
      read c
      expr $c + 1 > /dev/null 2>&1
      ret=$?
      if [ $ret -gt 1 ]; then
        echo -e ${error_color_on}"Can't understand the entered value."${color_off}
        exit
      fi
    done

    echo "<<< Setting contents"
    echo -e ${work_color_on}"HostName : "`uname -n`${color_off}
    if [ $x -eq 1 ];then
      echo -e ${error_color_on}"Add HDD : Nothing!!"${color_off}
    else
      if [ `echo ${dev_list[a]} | grep "1"` ]; then
        check=`pvscan | grep ${dev_list[a]} | awk '{print $4}'`
        if [ "$check" == "" ]; then
          echo -e ${work_color_on}"Add HDD : "${dev_list[a]}"(skip partition creation)"${color_off}
          l=1
        else
          size=`pvdisplay ${dev_list[a]} | grep "Free PE" | awk '{print $3}'`
          echo -e ${work_color_on}"Add HDD : "${dev_list[a]}"(VG:"$check" Free PE:"$size")"${color_off}
          l=1
          z=1
        fi
      else
        echo -e ${work_color_on}"Add HDD : "${dev_list[a]}${color_off}
      fi
    fi
    echo -e ${work_color_on}"VG Name : "$vg${color_off}
    size=`lvdisplay ${lv_list[c]} |grep "LV Size" | awk '{print $3 $4}'`
    echo -e ${work_color_on}"LV Name : "${lv_list[c]}"($size)"${color_off}

    set_lv=( `echo ${lv_list[c]} | tr -s '/' ' '`)
    count_arr=`expr ${#set_lv[*]} - 1`
    mount_point=`cat /etc/mtab | grep ${set_lv[count_arr]} | awk '{print $2}'`
    if [ "$mount_point" == "" ]; then
      echo -e ${error_color_on}"Mount Point : Nothing!!"${color_off}
    else
      echo -e ${work_color_on}"Mount Point : "${mount_point}${color_off}
    fi
    echo -e ${question_color_on}"Can I work with this setting?(y/n)"${color_off}
    echo ">>>"
    read d
    if [ "$d" != "y" ]; then
      i=0
      j=0
      k=0
    fi
  done

  echo "SERVER_NAME="`uname -n` > $setting_file
  if [ $x -eq 1 ];then
    echo "DEVICE=Nothing!!" >> $setting_file
  else
    echo "DEVICE="`echo ${dev_list[a]} | sed -e 's/\/dev\///g' ` >> $setting_file
  fi
  echo "VG="$vg >> $setting_file
  set_lv=( `echo ${lv_list[c]} | tr -s '/' ' '`)
  count_arr=`expr ${#set_lv[*]} - 1`
  echo "LV="${set_lv[count_arr]} >> $setting_file
  echo "MOUNT_POINT="${mount_point} >> $setting_file
  echo -e ${comment_color_on}"Setting file create completed."${color_off}
fi
