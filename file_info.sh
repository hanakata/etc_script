#!/bin/sh
IFS_BACKUP=$IFS
IFS=$'\n'

for list in `ls`; do
  if [ ${list} == "file_info.sh" ]; then
    flg=0
  else
    dir_list=`ls -ld ${list}/*`
    for dir in ${dir_list}; do
      dir_name=`echo $dir | awk '{print $9}'`
      log=`echo $dir | awk '{print $9}' | sed -e 's/.tgz//g'`
      tar tvfz $dir_name | awk '{print $1","$2","$6}' >> ${log}
    done
  fi
done

IFS=$IFS_BACKUP
