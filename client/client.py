#!/usr/bin/python
import multiprocessing
import sys
import random
import requests
import subprocess
import json
import time
import os
import socket
import signal
import tempfile
import shlex

HostName=socket.gethostname()
NbProcess = multiprocessing.cpu_count()
UrlApi = os.getenv('URL_API', 'localhost')
minAvailableSpace = 10

def process(id):
    strId = "["+str(id)+"] : "
    print(strId, "begin")
    id_session = -1

    try:
        # On cree un dossier temporaire dans le dossier courant qui devient le dossier d'execution
        working_dir = tempfile.TemporaryDirectory(dir='.')
        print('working dir : ', working_dir.name)

        req=requests.put('http://'+UrlApi+':8080/api/session?host='+HostName)
        id_session = req.json()[0]['id']
        print(strId, "id_session = ", str(id_session))
        while True:
            # on verifie l'espace disponible dans le dossier de travail
            stat=os.statvfs(working_dir.name)
            freeGb = int(stat.f_frsize * stat.f_bavail / (1024 * 1024 * 1024))
            req = None
            if freeGb < minAvailableSpace:
                print('espace disque insuffisant pour prendre des traitements : ', freeGb, '/', minAvailableSpace)
            else:
                req=requests.get('http://'+UrlApi+':8080/api/job/ready?id_session='+str(id_session))
            if (req) and (len(req.json())!=0):
                id_job = req.json()[0]['id']
                command = req.json()[0]['command']
                print(strId, "L'identifiant du job "+str(id_job)+" est disponible")
                print(strId, "Execution de la commande ["+ str(command)+"]")
                returnCode = None
                error_message = ''
                try:
                    process=subprocess.Popen(shlex.split(command), stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=working_dir.name)
                    while (returnCode == None):
                        returnCode=process.poll()
                        line = process.stdout.readline().decode()
                        if line:
                            req=requests.post('http://'+UrlApi+':8080/api/job/'+str(id_job)+'/append_log', json={"log": line})
    
                    status='done'
                    error_message+=process.stderr.read().decode()

                except Exception as ex:
                    print('failed : ', ex)
                    status='failed'
                    error_message+=str(ex)
                
                if (returnCode != 0):
                    status='failed'

                print('Mise a jour : ', returnCode, status, error_message)
                req=requests.post('http://'+UrlApi+':8080/api/job?id='+str(id_job)+'&status='+str(status)+'&returnCode='+str(returnCode), json={"log": error_message})
            time.sleep(random.randrange(10))
    except KeyboardInterrupt:
        print("on demande au process de s'arreter")
        req=requests.post('http://'+UrlApi+':8080/api/session/close?id='+str(id_session))
    print(strId, "end thread ")

if __name__ == "__main__":

    print("Demarrage du client GPAO")
    print("Hostname : ", HostName)

    pool = multiprocessing.Pool(NbProcess)
    original_sigint_handler = signal.signal(signal.SIGINT, signal.SIG_IGN)

    try:
        pool.map(process, range(NbProcess))

    except KeyboardInterrupt:
        print("on demande au pool de s'arreter")
        pool.terminate()
    else:
        print("Normal termination")
        pool.close()
    pool.join()
 
    print("Fin du client GPAO")
