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
files_exist_dictionary = {}
not_uses = []

for file in f:
    file_d = file.strip()
    cmd = "cat /opt/grn_bkup/sbin/backup_end.sh | grep " + file_d + " | wc -l"
    result = subprocess.Popen(cmd, shell= True, stdout=subprocess.PIPE)
    res = result.communicate()
    res_s = res[0].strip()
    if (res_s == "1"):
        not_uses.append(file)
f.close

for not_use in not_uses:
    print not_use.strip()