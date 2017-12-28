import subprocess
 
class Ping(object):
    def __init__(self, hosts):
        loss_pat='0 received'
        msg_pat='icmp_seq=1 '
        for host in hosts:
            ping = subprocess.Popen(
                ["ping", "-c", "1", host],
                stdout = subprocess.PIPE,
                stderr = subprocess.PIPE
            )
            out, error = ping.communicate()
            msg = ''
            for line in out.splitlines():
                if line.find(msg_pat)>-1:
                    msg = line.split(msg_pat)[1]
                if line.find(loss_pat)>-1:
                    flag=False
                    break
            else:
                flag=True
            if flag:
                print('[OK]: ' + 'ServerName->' + host)
            else:
                print('[NG]: ' + 'ServerName->' + host + ', Msg->\'' + msg + '\'')
 
 
if __name__ == '__main__':
    hosts=map(lambda x:'172.16.0.'+str(x),range(1,255))
    Ping(hosts)
