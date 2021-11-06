https://github.com/ansible-community/molecule-podman/issues/78
https://github.com/containers/podman/issues/11387
https://github.com/ansible-community/molecule-podman/issues/84

```
$ ansible --version
ansible [core 2.11.5]
  config file = None
  configured module search path = ['/home/tristan/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /tmp/test/venv/lib/python3.9/site-packages/ansible
  ansible collection location = /home/tristan/.ansible/collections:/usr/share/ansible/collections
  executable location = /tmp/test/venv/bin/ansible
  python version = 3.9.7 (default, Aug 31 2021, 13:28:12) [GCC 11.1.0]
  jinja version = 3.0.1
  libyaml = True
```

on voit à partir de ça les endroits qu'on va devoir modifier

pour la connection molecule-podman le fichier à changer était dans `./venv/lib/python3.9/site-packages/molecule_podman/`

pour la connection ansible-podman le fichier à changer en local /home/tristan/.ansible/collections/ansible_collections/containers/podman/plugins/connection/podman.py


le problème c'est que python essaie d'accéder (en python, os.lsdir) à des dossier
qui ont été créé par podman donc en root. Ca c'esdt chiant parceque du coup c'est
pas aussi simple que de mettre sudo devant la commande podman

## step 1 : trouver comment ansible gère le sudo en interne

[ici](https://github.com/ansible/ansible/blob/097bc07b6663932705dc2a4baaa5765112fc270e/lib/ansible/executor/task_executor.py#L1129)

ok donc la on voit un appel au process mais il appel juste le module de connection

la réponse se trouve dans la connection SSH (ansible/lib/plugins/connection/ssh.py)
ligne 1062 on voit qu'il passe au process lel mot de passe become

c'est dans la fonction `_bare_run` qui joue directement une commande, c'est
exactement ce qu'on veux

on fait les même modif, ça fonctionne

### on met ça dans un repos

pour l'instant je dev directement en modifiant le fichier /home/tristan/.ansible/collections/ansible_collections/containers/podman/plugins/connection/podman.py

c'est pas génial parceque c'est pas un dépôt git donc je sauvegarde jamais et ça sera écrasé par la mise à jour de mes collections

quand on fait `ansible --version` on voit qu'on peut ajouter des paths
```
> ansible --version | grep collection
  ansible collection location = /home/tristan/.ansible/collections:/usr/share/ansible/collections
```

ca nous dis également ou est le fichier de configuration
```
> ansible --version | grep config
  config file = /etc/ansible/ansible.cfg
  configured module search path = ['/home/tristan/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
```

on à donc probablement un endroit dans ce fichier de conf pour changer l'endroit ou il va chercher les collections
```
> cat /etc/ansible/ansible.cfg | grep collection
# Paths to search for collections, colon separated
# collections_paths = ~/.ansible/collections:/usr/share/ansible/collections
# Role or collection skeleton directory to use as a template for
# Patterns of files to ignore inside a Galaxy role or collection
# A list of Galaxy servers to use when installing a collection.
```

indeed, on va donc modifier ce fichier pour que ça prenne en premier nos collections
```
> cat /etc/ansible/ansible.cfg | grep collections_paths
collections_paths = ~/repos/public/ansible-collections/:~/.ansible/collections:/usr/share/ansible/collections
```

il faut créer le dossier et y clone le dépôt que j'ai fork
```
mkdir ~/repos/public/ansible-collections/
cd ~/repos/public/ansible-collections/
git clone git@github.com:0b11stan/ansible-podman-collections.git
```

TODO : fix les emplacmenet du module, il faut suivre un chemin particulier

## step 2 : 

en fait je me suis unspirer du module ssh pour faire passer un password dans le prompt ssh

maintenant il y à un bug
```
> ansible-playbook -vvvvv -k -i inventory.yml main.yml
ansible-playbook [core 2.11.5]
  config file = /etc/ansible/ansible.cfg
  configured module search path = ['/home/tristan/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3.9/site-packages/ansible
  ansible collection location = /home/tristan/repos/public/ansible-collections:/home/tristan/.ansible/collections:/usr/share/ansible/collections
  executable location = /usr/bin/ansible-playbook
  python version = 3.9.7 (default, Aug 31 2021, 13:28:12) [GCC 11.1.0]
  jinja version = 3.0.1
  libyaml = True
Using /etc/ansible/ansible.cfg as config file
SSH password:
setting up inventory plugins
host_list declined parsing /tmp/podman-connection/inventory.yml as it did not pass its verify_file() method
script declined parsing /tmp/podman-connection/inventory.yml as it did not pass its verify_file() method
Parsed /tmp/podman-connection/inventory.yml inventory source with yaml plugin
Loading callback plugin default of type stdout, v2.0 from /usr/lib/python3.9/site-packages/ansible/plugins/callback/default.py
Attempting to use 'default' callback.
Skipping callback 'default', as we already have a stdout callback.
Attempting to use 'junit' callback.
Attempting to use 'minimal' callback.
Skipping callback 'minimal', as we already have a stdout callback.
Attempting to use 'oneline' callback.
Skipping callback 'oneline', as we already have a stdout callback.
Attempting to use 'tree' callback.

PLAYBOOK: main.yml *****************************************************************************************************************************************************************************
Positional arguments: main.yml
verbosity: 5
ask_pass: True
connection: smart
timeout: 10
become_method: sudo
tags: ('all',)
inventory: ('/tmp/podman-connection/inventory.yml',)
forks: 5
1 plays in main.yml

PLAY [Converge] ********************************************************************************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************************************************************************************
task path: /tmp/podman-connection/main.yml:2
redirecting (type: connection) ansible.builtin.podman to containers.podman.podman
Loading collection containers.podman from /home/tristan/repos/public/ansible-collections/ansible_collections/containers/podman
Using podman connection from collection
<rootfull> RUN [b'sudo', b'-Sk', b'/usr/bin/podman', b'mount', b'rootfull']
STDOUT b'/var/lib/containers/storage/overlay/e0d8ba1679cdd4864d813ad2dc335c8912a91f91b7c4de21a8d88c42ae3cec15/merged\n'
STDERR b''
RC CODE 0
The full traceback is:
Traceback (most recent call last):
  File "/usr/lib/python3.9/site-packages/ansible/executor/task_executor.py", line 158, in run
    res = self._execute()
  File "/usr/lib/python3.9/site-packages/ansible/executor/task_executor.py", line 582, in _execute
    result = self._handler.run(task_vars=variables)
  File "/usr/lib/python3.9/site-packages/ansible/plugins/action/gather_facts.py", line 94, in run
    res = self._execute_module(module_name=fact_module, module_args=mod_args, task_vars=task_vars, wrap_async=False)
  File "/usr/lib/python3.9/site-packages/ansible/plugins/action/__init__.py", line 970, in _execute_module
    self._make_tmp_path()
  File "/usr/lib/python3.9/site-packages/ansible/plugins/action/__init__.py", line 390, in _make_tmp_path
    tmpdir = self._remote_expand_user(self.get_shell_option('remote_tmp', default='~/.ansible/tmp'), sudoable=False)
  File "/usr/lib/python3.9/site-packages/ansible/plugins/action/__init__.py", line 853, in _remote_expand_user
    data = self._low_level_execute_command(cmd, sudoable=False)
  File "/usr/lib/python3.9/site-packages/ansible/plugins/action/__init__.py", line 1265, in _low_level_execute_command
    rc, stdout, stderr = self._connection.exec_command(cmd, in_data=in_data, sudoable=sudoable)
  File "/usr/lib/python3.9/site-packages/ansible/plugins/connection/__init__.py", line 34, in wrapped
    self._connect()
  File "/home/tristan/repos/public/ansible-collections/ansible_collections/containers/podman/plugins/connection/podman.py", line 200, in _connect
    elif not os.listdir(self._mount_point.strip()):
PermissionError: [Errno 13] Permission denied: b'/var/lib/containers/storage/overlay/e0d8ba1679cdd4864d813ad2dc335c8912a91f91b7c4de21a8d88c42ae3cec15/merged'
fatal: [rootfull]: FAILED! => {
    "msg": "Unexpected failure during module execution.",
    "stdout": ""
}

PLAY RECAP *************************************************************************************************************************************************************************************
rootfull                   : ok=0    changed=0    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0
```

quand on le fait en local on voit iqu'il ytilise un fichier stat.py
```
> ansible-playbook -vvv main.yml
ansible-playbook [core 2.11.5]
  config file = /etc/ansible/ansible.cfg
  configured module search path = ['/home/tristan/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3.9/site-packages/ansible
  ansible collection location = /home/tristan/repos/public/ansible-collections:/home/tristan/.ansible/collections:/usr/share/ansible/collections
  executable location = /usr/bin/ansible-playbook
  python version = 3.9.7 (default, Aug 31 2021, 13:28:12) [GCC 11.1.0]
  jinja version = 3.0.1
  libyaml = True
Using /etc/ansible/ansible.cfg as config file
host_list declined parsing /etc/ansible/hosts as it did not pass its verify_file() method
Skipping due to inventory source not existing or not being readable by the current user
script declined parsing /etc/ansible/hosts as it did not pass its verify_file() method
auto declined parsing /etc/ansible/hosts as it did not pass its verify_file() method
Skipping due to inventory source not existing or not being readable by the current user
yaml declined parsing /etc/ansible/hosts as it did not pass its verify_file() method
Skipping due to inventory source not existing or not being readable by the current user
ini declined parsing /etc/ansible/hosts as it did not pass its verify_file() method
Skipping due to inventory source not existing or not being readable by the current user
toml declined parsing /etc/ansible/hosts as it did not pass its verify_file() method
[WARNING]: No inventory was parsed, only implicit localhost is available
[WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'
Skipping callback 'default', as we already have a stdout callback.
Skipping callback 'minimal', as we already have a stdout callback.
Skipping callback 'oneline', as we already have a stdout callback.

PLAYBOOK: main.yml *****************************************************************************************************************************************************************************
1 plays in main.yml

PLAY [localhost] *******************************************************************************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************************************************************************************
task path: /tmp/local-connection/main.yml:2
<127.0.0.1> ESTABLISH LOCAL CONNECTION FOR USER: tristan
<127.0.0.1> EXEC /bin/sh -c 'echo ~tristan && sleep 0'
<127.0.0.1> EXEC /bin/sh -c '( umask 77 && mkdir -p "` echo /home/tristan/.ansible/tmp `"&& mkdir "` echo /home/tristan/.ansible/tmp/ansible-tmp-1632146291.5655546-32161-53993955585628 `" && echo ansible-tmp-1632146291.5655546-32161-53993955585628="` echo /home/tristan/.ansible/tmp/ansible-tmp-1632146291.5655546-32161-53993955585628 `" ) && sleep 0'
Using module file /usr/lib/python3.9/site-packages/ansible/modules/setup.py
<127.0.0.1> PUT /home/tristan/.ansible/tmp/ansible-local-32066a2nuxnmz/tmprr5nz1wh TO /home/tristan/.ansible/tmp/ansible-tmp-1632146291.5655546-32161-53993955585628/AnsiballZ_setup.py
<127.0.0.1> EXEC /bin/sh -c 'chmod u+x /home/tristan/.ansible/tmp/ansible-tmp-1632146291.5655546-32161-53993955585628/ /home/tristan/.ansible/tmp/ansible-tmp-1632146291.5655546-32161-53993955585628/AnsiballZ_setup.py && sleep 0'
<127.0.0.1> EXEC /bin/sh -c '/usr/bin/python /home/tristan/.ansible/tmp/ansible-tmp-1632146291.5655546-32161-53993955585628/AnsiballZ_setup.py && sleep 0'
<127.0.0.1> EXEC /bin/sh -c 'rm -f -r /home/tristan/.ansible/tmp/ansible-tmp-1632146291.5655546-32161-53993955585628/ > /dev/null 2>&1 && sleep 0'
ok: [localhost]
META: ran handlers

TASK [copy] ************************************************************************************************************************************************************************************
task path: /tmp/local-connection/main.yml:4
<127.0.0.1> ESTABLISH LOCAL CONNECTION FOR USER: tristan
<127.0.0.1> EXEC /bin/sh -c 'echo ~tristan && sleep 0'
<127.0.0.1> EXEC /bin/sh -c '( umask 77 && mkdir -p "` echo /home/tristan/.ansible/tmp `"&& mkdir "` echo /home/tristan/.ansible/tmp/ansible-tmp-1632146294.7734723-32215-135104899749270 `" && echo ansible-tmp-1632146294.7734723-32215-135104899749270="` echo /home/tristan/.ansible/tmp/ansible-tmp-1632146294.7734723-32215-135104899749270 `" ) && sleep 0'
Using module file /usr/lib/python3.9/site-packages/ansible/modules/stat.py
<127.0.0.1> PUT /home/tristan/.ansible/tmp/ansible-local-32066a2nuxnmz/tmpwjt_etta TO /home/tristan/.ansible/tmp/ansible-tmp-1632146294.7734723-32215-135104899749270/AnsiballZ_stat.py
<127.0.0.1> EXEC /bin/sh -c 'chmod u+x /home/tristan/.ansible/tmp/ansible-tmp-1632146294.7734723-32215-135104899749270/ /home/tristan/.ansible/tmp/ansible-tmp-1632146294.7734723-32215-135104899749270/AnsiballZ_stat.py && sleep 0'
<127.0.0.1> EXEC /bin/sh -c 'sudo -H -S -n  -u root /bin/sh -c '"'"'echo BECOME-SUCCESS-vhvztpjudpcfmdrtaoketlxqmlhoveyc ; /usr/bin/python /home/tristan/.ansible/tmp/ansible-tmp-1632146294.7734723-32215-135104899749270/AnsiballZ_stat.py'"'"' && sleep 0'
<127.0.0.1> EXEC /bin/sh -c 'rm -f -r /home/tristan/.ansible/tmp/ansible-tmp-1632146294.7734723-32215-135104899749270/ > /dev/null 2>&1 && sleep 0'
fatal: [localhost]: FAILED! => {
    "msg": "Failed to get information on remote file (/root): sudo: a password is required\n"
}

PLAY RECAP *************************************************************************************************************************************************************************************
localhost                  : ok=1    changed=0    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0

```

et du coup on retrouve ce fichieri et on voit qu'a moment donné il essaie de faire une levé de privilege en théorie
https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/stat.py#L485
