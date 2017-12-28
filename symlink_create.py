import sys
import os.path
 
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
    link_path_list = path_text.split(" ")
    file_exists = os.path.isfile(link_path_list[3])
    if (file_exists == True):
        print "describe file('" + link_path_list[3] + "') do"
        print "  it { should be_linked_to '" + link_path_list[2] + "' }"
        print "end"

    else:
        files_not_exist.append(link_path_list[3])
f.close

for file_not_exist in files_not_exist:
    print file_not_exist + " does not exist"
