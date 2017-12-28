import sys
import os.path
import subprocess
 
argvs = sys.argv
argc = len(argvs)
if (argc != 2):
    print 'Usage: # python %s filename' % argvs[0]
    quit()
 
f = open(argvs[1]) 
file = ""
file_info = []
variable_str = []
files_exist_dictionary = {}
files_not_exist = []

for file in f:
    path_text = file.strip()
    file_exists = os.path.isfile(path_text)
    if (file_exists == True):
        cmd = "ls -la /etc/rsyslog.conf | awk '{print $1}'"
        permission_cmd = subprocess.Popen(cmd, shell= True, stdout=subprocess.PIPE)
        permission_info = permission_cmd.communicate()
        permission_info_list = list(permission_info[0].strip())
        
        permission_user = 0
        permission_group = 0
        permission_other = 0
        if (permission_info_list[1] == "r"):
            permission_user += 4
        if (permission_info_list[2] == "w"):
            permission_user += 2
        if (permission_info_list[3] == "x"):
            permission_user += 1
        if (permission_info_list[4] == "r"):
            permission_group += 4
        if (permission_info_list[5] == "w"):
            permission_group += 2
        if (permission_info_list[6] == "x"):
            permission_group += 1
        if (permission_info_list[7] == "r"):
            permission_other += 4
        if (permission_info_list[8] == "w"):
            permission_other += 2
        if (permission_info_list[9] == "x"):
            permission_other += 1
        
        permission = str(permission_user) + str(permission_group) + str(permission_other)

        cmd = "ls -la /etc/rsyslog.conf | awk '{print $3}'"
        owner_cmd = subprocess.Popen(cmd, shell= True, stdout=subprocess.PIPE)
        owner_info = owner_cmd.communicate()
        owner = owner_info[0].strip()

        cmd = "ls -la /etc/rsyslog.conf | awk '{print $4}'"
        group_cmd = subprocess.Popen(cmd, shell= True, stdout=subprocess.PIPE)
        group_info = group_cmd.communicate()
        group = group_info[0].strip()

        cmd = "md5sum " + path_text + " | awk '{print $1}'"
        hash = subprocess.Popen(cmd, shell= True, stdout=subprocess.PIPE)
        res = hash.communicate()
        variable_str = path_text.split('/')
        if (len(variable_str) <= 3):
            variable = variable_str[1].replace('.','_').replace('-','_') + "_" + variable_str[-1].replace('.','_').replace('-','_')
        else:
            variable = variable_str[1].replace('.','_').replace('-','_') + "_" + variable_str[2].replace('.','_').replace('-','_') + "_" + variable_str[-1].replace('.','_').replace('-','_')
        print variable + " = " + '"' + res[0].strip() + '"'

        files_exist_dictionary.setdefault(path_text, []).append(variable)
        files_exist_dictionary.setdefault(path_text, []).append(permission)
        files_exist_dictionary.setdefault(path_text, []).append(owner)
        files_exist_dictionary.setdefault(path_text, []).append(group)
    else:
        files_not_exist.append(path_text)

f.close

for path, var in files_exist_dictionary.items():
    print
    print 'describe command("md5sum ' + '%s' % path + " | awk '{print $1}'| tr -d '" + "\\n'" + '") do'
    print "   its(:stdout) { should eq %s }" % var[0]
    print "end"

    print
    print "describe file('%s') do" %  path
    print "   it { should be_owned_by('%s') }" % var[1].strip()
    print "   it { should be_grouped_into('%s') }" % var[2].strip()
    print "   it { should be_mode '%s' }" % var[3].strip()
    print "end"

for file_not_exist in files_not_exist:
    print file_not_exist + " does not exist"

