#  Splunk 6.5 Cluster Administration

My goal is to provide you with enough resources to learn about how
Splunk cluster instead of specific configuration about any one environment.
I feel that if I understand the tool, how you manage your configs is a 
matter of preference. I will be giving you links to the relevant documentation,
and will give you step by step instructions on what to do.

Before we go any further make sure you understand configuration file priority.

http://docs.splunk.com/Documentation/Splunk/latest/Admin/Wheretofindtheconfigurationfiles

Read the section about "How Splunk determines precedence order"! I believe,
this is the piece that is most confusing about Splunk. If you cannot remember
the full order, just remember this. system/local/* has the final word.

This branch has created for you the servers in the README.md. If you have
not checked it out go do that now and come back when done.

 Here is how we'll break
the exercise down.

license manager.
index cluster (multi-site).
search cluster (multi-site).
monitoring.


## Training Lab Environment

### Description:

Use this environment to quickly spin up a Splunk Lab.

### Configuration:

In order to conserve laptop resources we will run multiple instances of Splunk from a
single server. Here is the server breakdown.

1. `splunk` - stand-alone server running a single instance of Splunk.
2. `splunk_idxc` - server running all indexer instances with exception of the cluster-master.
3. `splunk_shc` - server running all the search instances with exception of the deployer.
4. `splunk_misc` - server running all management pieces (master node, license master, deployment server, deployer)
5. `splunk_lb` - server running an nginx proxy with a sticky LB configuration, used as a front-end to the shcluster.

**NOTE:** splunk-lb will also be configured as a splunk forwarder and can be used to test ingesting data.

#### Host Details:

##### splunk

This server is a standalone instance of Splunk. There is nothing special about this. It runs with all
the default ports:

ip address: `192.168.3.61`

| name | path | guest ports | local port |
| --- | --- | --- | --- |
| splunk | /opt/splunk | splunkd:8089, web:8000, listen:9997 | [localhost:8101](http://localhost:8101) |


##### splunk_idxc

This node contains all the splunk indexers. Each instance runs from a separate folder, each having its own
set of used ports. See  table below for details.

ip address: `192.168.3.62`

| name | path | guest ports | local port |
| --- | --- | --- | --- |
| idx1 | /opt/idx1 | splunkd:8189, web:8100, listen:9197, replication:9100 | [localhost:8201](http://localhost:8201) |
| idx2 | /opt/idx2 | splunkd:8289, web:8200, listen:9297, replication:9200 | [localhost:8202](http://localhost:8202) |
| idx3 | /opt/idx3 | splunkd:8389, web:8300, listen:9397, replication:9300 | [localhost:8203](http://localhost:8203) |
| idx4 | /opt/idx4 | splunkd:8489, web:8400, listen:9497, replication:9400 | [localhost:8204](http://localhost:8204) |


##### splunk_shc

This vm is home for splunk web (search heads). Each instance runs from a separate folder, eaching having its
own set of ports. Note that search heads do not listen to incoming data. See table below:

ip address: `192.168.3.63`

| name | path | guest ports | local ports |
| --- | --- | --- | --- |
| sh1 | /opt/sh1 | splunkd:8189, web:8100, replication:9100 | [localhost:8301](http://localhost:8301) |
| sh2 | /opt/sh2 | splunkd:8289, web:8200, replication:9200 | [localhost:8302](http://localhost:8302) |
| sh3 | /opt/sh3 | splunkd:8389, web:8300, replication:9300 | [localhost:8303](http://localhost:8303) |


##### splunk_misc

This vm is home for the management pieces.

ip address: `192.168.3.64`

| name | path | guest ports | local ports |
| --- | --- | --- | --- |
| cluster master | /opt/cm | splunkd:8189, web:8100 | [localhost:8401](http://localhost:8401) |
| license master | /opt/lm | splunkd:8289, web:8200 | [localhost:8402](http://localhost:8402) |
| deployer | /opt/dep | splunkd:8389, web:8300 | [localhost:8403](http://localhost:8403) |
| deployment server | /opt/ds | splunkd:8489, web:8400 | [localhost:8404](http://localhost:8404) |
| monitoring console | /opt/mc | splunkd:8589, web:8500 | [localhost:8405](http://localhost:8405) |


##### splunk_lb

This node serves two functions, it is the way to access the web UI for the cluster, etc. It also
provides us with logs we can ingest into splunk.

ip address: `192.168.3.65`

| name | path | guest ports | local ports |
| --- | --- | --- | --- |
| nginx | /etc/nginx | httpd:8080 | [localhost:8080](http://localhost:8080) |
| splunk forwarder | /opt/splunk | splunkd:8089, 9997 | |


### Usage:

**NOTE:** only the standalone version has been configured right now.

To sping up everything in one go:

    vagrant up
    vagrant ssh <vm_name>

To sping up a single host:

    vagrant up splunk
    vagrant ssh splunk

Before proceeding with the exercises, make sure you have obtained a license.
You will need a real enterprise license, so yeah. good luck with that.
Best bet is to ask sales to provide you with a tiny dev enterprise license.
In training they gave us each a 200MB daily license which is even less
than the free license limit, but it allowed us to cluster.

For more details on licensing go to:

https://www.splunk.com/en_us/products/splunk-enterprise/free-vs-enterprise.html

## Part 1 - Setup the license master.

1. Login to splunk_misc and elevate your privs then set user to `splunk`

    ```
    [vagrant@splunk_misc:~] $ vagrant ssh splunk_misc
    sudo -s su - splunk
    ```
2. Note that the default location for the splunk application is /opt/splunk.
Since this host is multi-tenant you must set your environment with the right
instance of Splunk. 

    ```
    splunk@splunk_misc ~]$     export SPLUNK_HOME=/opt/lm
    ```
3. Start Splunk if it isn't running.

    ```
    [splunk@splunk_misc ~]$     $SPLUNK_HOME/bin/splunk show servername
    Splunk username: admin
    Password: 
    Server name: splunk_misc.localdomain
    [splunk@splunk_misc ~]$     $SPLUNK_HOME/bin/splunk show splunkd-port
    Splunkd port: 8289
    [splunk@splunk_misc ~]$     $SPLUNK_HOME/bin/splunk show web-port
    Web port: 8200
    ```
4. Install your license. Use the CLI, or via the WebUI. I find the UI easier,
but here is the command if you have a file.

    ```
    [splunk@splunk_misc ~]$     $SPLUNK_HOME/bin/splunk add licenses /path/to/splunk.license
    ```
5.  NOTE: if you used the CLI you HAVE to restart splunkd.

    ```
    [splunk@splunk_misc ~]$     $SPLUNK_HOME/bin/splunk restart
    Stopping splunkd...
    Shutting down.  Please wait, as this may take a few minutes.
    ..                                                         [  OK  ]
    Stopping splunk helpers...
                                                               [  OK  ]
    Done.
    
    Splunk> See your world.  Maybe wish you hadn't.
    
    Checking prerequisites...
            Checking http port [8200]: open
            Checking mgmt port [8289]: open
            Checking appserver port [127.0.0.1:8265]: open
            Checking kvstore port [8291]: open
            Checking configuration...  Done.
            Checking critical directories...        Done
            Checking indexes...
                    Validated: _audit _internal _introspection _thefishbucket history main summary
            Done
            Checking filesystem compatibility...  Done
            Checking conf files for problems...
            Done
            Checking default conf files for edits...
            Validating installed files against hashes from '/opt/lm/splunk-6.4.3-b03109c2bad4-linux-2.6-x86_64-manifest'
            All installed files intact.
                Done
    All preliminary checks passed.
    
    Starting splunk server daemon (splunkd)...  
    Done
                                                               [  OK  ]
    
    Waiting for web server at http://127.0.0.1:8200 to be available..... Done
    
    
    If you get stuck, we're here to help.  
    Look for answers here: http://docs.splunk.com
    
    The Splunk web interface is at http://splunk_misc.localdomain:8200
    
    [splunk@splunk_misc ~]$ 
    ```
6. Here is the link to the lm server

    http://localhost:8402


## Part 2 - Indexer Clustering

Before going forward take a look at some of the clustering docs here:

http://docs.splunk.com/Documentation/Splunk/6.5.1/Indexer/Basicclusterarchitecture

Ok Great, now you are an expert in clustering right? ;)

configure indexers as multi-site as [site1: idx1 idx2 | site2: idx3, idx4]

Let's start with the master node.

1. Login to the misc server again but this time set your environment for
the `/opt/cm`

    ```
    [13:56:37 vagrant@splunk_misc:~] $ sudo -s su - splunk
    [splunk@splunk_misc ~]$ export SPLUNK_HOME=/opt/cm
    ```

2. Set up the servers as a license slave with the following command:

    ```
    [splunk@splunk_misc ~]$ /opt/cm/bin/splunk edit licenser-localslave -master_uri https://192.168.3.64:8289
    Splunk username: admin
    Password: 
    The licenser-localslave object has been edited.
    You need to restart the Splunk Server (splunkd) for your changes to take effect.
    ```
    This will add the following stanza to the server.conf file:

    ```
    [license]
    master_uri = https://192.168.3.64:8289
    ```
3. Configure the replication factor fot he index cluster. For some reason when you try
to set multisite setup from the command line Splunk complains. So you'll need to set it
up single site first then convert it to multisite. This isn't a problem when doing it
via config scripts tho.

    ```
    [splunk@splunk_misc bin]$ pwd
    /opt/cm/bin
    [splunk@splunk_misc bin]$ ./splunk edit cluster-config -mode master -replication_factor 2 -search_factor 2 -secret idxSymmKey
    [splunk@splunk_misc bin]$ ./splunk restart
    [splunk@splunk_misc bin]$ ./splunk edit cluster-config -mode master -multisite true -site site1 -available_sites site1,site2 -site_replication_factor origin:1,total:2 -site_search_factor origin:1,total:2 -search_factor 1 -secret idxSymmKey
    Your session is invalid.  Please login.
    Splunk username: admin
    Password: 
    The cluster-config property has been edited.
    You need to restart the Splunk Server (splunkd) for your changes to take effect.
    ```
    Note that now you have the following stanza added to the server.conf.

    ```
    [general]
    site = site1
    
    [clustering]
    mode = master
    pass4SymmKey = $1$ev2oF7Bz9nNl3dY=
    replication_factor = 2
    available_sites = site1,site2
    multisite = true
    search_factor = 1
    site_replication_factor = origin:1,total:2
    site_search_factor = origin:1,total:2
    ```
    
    For reference this is what a non multisite setup looks like:

    ```
    [clustering]
    mode = master
    pass4SymmKey = $1$ev2oF7Bz9nNl3dY=
    replication_factor = 2
    ```
    Special note about the pass4SymmKey. This option is relative to scope, in
    this case the key is only exchanged within the index cluster. You may choose
    to use the same passphrase for all pieces in your config to avoid confusion.
    Of course, that comes with its own set of security implications.

    Further reading on clustering and replication factors here:

    http://docs.splunk.com/Documentation/Splunk/6.5.1/Indexer/Multisitearchitecture

4. Restart the master node.

    ```
    [splunk@splunk_misc bin]$ pwd
    /opt/cm/bin
    [splunk@splunk_misc bin]$ ./splunk restart
    ```
    How that the master node is up we can bring up the cluster peers.

5. Login to the splunk indexer host and change user to the splunk user.

    ```
    vagrant ssh splunk_idxc
    Last login: Tue Feb 24 20:35:19 2015
    [vagrant@splunk_idxc:~] $ sudo -s su - splunk
    [splunk@splunk_idxc ~]$ 
    ```

6. Configure each of the 4 instances as follows:

    idx1, idx2 - site 1
    idx3, idx4 - site 2

    ```
    [splunk@splunk_idxc ~]$  export SPLUNK_HOME=/opt/idx1
    [splunk@splunk_idxc ~]$ $SPLUNK_HOME/bin/splunk edit cluster-config -master_uri https://192.168.3.64:8189 -mode slave -site site1 -replication_port 9100 -secret idxSymmKey
    Splunk username: admin
    Password: 
    The cluster-config property has been edited.
    You need to restart the Splunk Server (splunkd) for your changes to take effect.
    ```
    Here is what the above command added to system/local/server.conf:

    ```
    [general]
    site = site1
    
    [replication_port://9100]
    
    [clustering]
    master_uri = https://192.168.3.64:8189
    mode = slave
    pass4SymmKey = $1$1qAdnHJLbVx41eI=
    ```
7. Before we restart, we need to make sure that the node is pointed to our
license server. Here is the command for that.

    ```
    splunk@splunk_idxc ~]$ $SPLUNK_HOME/bin/splunk edit licenser-localslave -master_uri https://192.168.3.64:8289
    The licenser-localslave object has been edited.
    You need to restart the Splunk Server (splunkd) for your changes to take effect.
    ```
8. Configure the listen port for the forwarders to send to.

    ```
    [splunk@splunk_idxc ~]$ $SPLUNK_HOME/bin/splunk enable listen 9197
    Listening for Splunk data on TCP port 9197.
    ```
    The above command will generate the following file:
 
    $SPLUNK_HOME/etc/apps/search/local/inputs.conf

    ```
    [splunktcp://9197]
    connection_host = ip
    ```
    Note that this file could also live in etc/system/local/inputs.conf and
    it would do the same thing, and would be the definitive place to put this.

9. Restart splunk.

    ```
    splunk@splunk_idxc ~]$ $SPLUNK_HOME/bin/splunk restart
    ```
10. Repeat step 6 to 9 for each of the other 3 servers. Remember that idx3,
and idx4 belong to site2.

    ```
    export SPLUNK_HOME=/opt/idx2
    $SPLUNK_HOME/bin/splunk edit cluster-config -master_uri https://192.168.3.64:8189 \
    -mode slave -site site1 -replication_port 9200 -secret idxSymmKey
    $SPLUNK_HOME/bin/splunk edit licenser-localslave -master_uri https://192.168.3.64:8289
    $SPLUNK_HOME/bin/splunk enable listen 9297
    $SPLUNK_HOME/bin/splunk restart
    ```
    
    ```
    export SPLUNK_HOME=/opt/idx3
    $SPLUNK_HOME/bin/splunk edit cluster-config -master_uri https://192.168.3.64:8189 \
    -mode slave -site site2 -replication_port 9300 -secret idxSymmKey
    $SPLUNK_HOME/bin/splunk edit licenser-localslave -master_uri https://192.168.3.64:8289
    $SPLUNK_HOME/bin/splunk enable listen 9397
    $SPLUNK_HOME/bin/splunk restart
    ```
    
    ```
    export SPLUNK_HOME=/opt/idx4
    $SPLUNK_HOME/bin/splunk edit cluster-config -master_uri https://192.168.3.64:8189 \
    -mode slave -site site2 -replication_port 9400 -secret idxSymmKey
    $SPLUNK_HOME/bin/splunk edit licenser-localslave -master_uri https://192.168.3.64:8289
    $SPLUNK_HOME/bin/splunk enable listen 9497
    $SPLUNK_HOME/bin/splunk restart
    ```
10. Check your work from the cluster nodes UI at:

    http://localhost:8401


## Part 3 - Search Head Cluster

Search head cluster is a bit different than with an indexer cluster in that
while the master node manages indexers, in shcluster the captains job is simply
to schedule jobs and push configs from other nodes or from the deployer to the 
rest of the cluster. Where you run commands is important as they need to be
captain aware. More info on the shcluster here:

http://docs.splunk.com/Documentation/Splunk/6.5.1/DistSearch/SHCdeploymentoverview

And here:

http://docs.splunk.com/Documentation/Splunk/6.5.1/DistSearch/SHCconfigurationoverview

We'll go ahead and setup the cluster, here is the breakdown:

* configure search heads as multi-site as [site1: sh1 | site2: sh2, sh3]
* bootstrap the search captain.
* setup the deployer.

1. Login to the search cluster

    ```
    [12:02:52 vagrant@splunk_shc:~] $ sudo -s su - splunk
    [splunk@splunk_shc ~]$ export SPLUNK_HOME=/opt/sh1
    ```

2. Configure the license on the server by pointint it to the license master.

    ```
    [splunk@splunk_shc ~]$ $SPLUNK_HOME/bin/splunk edit licenser-localslave -master_uri https://192.168.3.64:8289
    ```

3. Configure the node so it can search the index cluster by pointing it to the master node.

    ```
    [splunk@splunk_shc local]$ $SPLUNK_HOME/bin/splunk edit cluster-config -mode searchhead -master_uri https://192.168.3.64:8189 -site site1 -secret idxSymmKey
    [splunk@splunk_shc local]$ $SPLUNK_HOME/bin/splunk restart
    ```

4. Repeat steps 1 to 3 on the other 2 search heads but make sure that they are set to site2.

    ```
    [splunk@splunk_shc local]$ export SPLUNK_HOME=/opt/sh2
    [splunk@splunk_shc local]$ $SPLUNK_HOME/bin/splunk edit licenser-localslave -master_uri https://192.168.3.64:8289
    [splunk@splunk_shc local]$ $SPLUNK_HOME/bin/splunk edit cluster-config -mode searchhead -master_uri https://192.168.3.64:8189 -site site2 -secret idxSymmKey
    [splunk@splunk_shc local]$ $SPLUNK_HOME/bin/splunk restart
    
    [splunk@splunk_shc local]$ export SPLUNK_HOME=/opt/sh3
    [splunk@splunk_shc local]$ $SPLUNK_HOME/bin/splunk edit licenser-localslave -master_uri https://192.168.3.64:8289
    [splunk@splunk_shc local]$ $SPLUNK_HOME/bin/splunk edit cluster-config -mode searchhead -master_uri https://192.168.3.64:8189 -site site2 -secret idxSymmKey
    [splunk@splunk_shc local]$ $SPLUNK_HOME/bin/splunk restart
    ```
    
    For reference here is what that added on the server.conf file.
    
    ```
    [general]
    site = site1
    
    [clustering]
    master_uri = https://192.168.3.64:8189
    mode = searchhead
    multisite = true
    pass4SymmKey = $1$3JWt9uAYNSta4L8=
    ```

5. At this point you should see the search heads here: 

    http://localhost:8401/en-US/manager/system/clustering?tab=searchheads

    When you have verified that the servers see the cluster master move on to the next step.

6.  Configure searchhead clustering. On all search heads. Note that you will need to restart the nodes to make the change
take effect. Note that the symmkey (password) used for shcluster is independent from the one used for the index cluster.
Thus they can be different passwords.

    ```
    [splunk@splunk_shc local]$ export SPLUNK_HOME=/opt/sh1
    [splunk@splunk_shc local]$ $SPLUNK_HOME/bin/splunk init shcluster-config -mgmt_uri https://192.168.3.63:8189 -replication_port 9100 -secret shSymmKey
    [splunk@splunk_shc local]$ $SPLUNK_HOME/bin/splunk restart

    [splunk@splunk_shc local]$ export SPLUNK_HOME=/opt/sh2
    [splunk@splunk_shc local]$ $SPLUNK_HOME/bin/splunk init shcluster-config -mgmt_uri https://192.168.3.63:8289 -replication_port 9200 -secret shSymmKey
    [splunk@splunk_shc local]$ $SPLUNK_HOME/bin/splunk restart

    [splunk@splunk_shc local]$ export SPLUNK_HOME=/opt/sh3
    [splunk@splunk_shc local]$ $SPLUNK_HOME/bin/splunk init shcluster-config -mgmt_uri https://192.168.3.63:8389 -replication_port 9300 -secret shSymmKey
    [splunk@splunk_shc local]$ $SPLUNK_HOME/bin/splunk restart
    ```

7. At this point clustering isn't fully active yet. You need to bootstrap the cluster by electing a captain. This is only
needed this time. This is is done automatically by the captain and cluster members once the cluster is active.

    ```
    [splunk@splunk_shc local]$ export SPLUNK_HOME=/opt/sh1
    [splunk@splunk_shc local]$ $SPLUNK_HOME/bin/splunk bootstrap shcluster-captain -servers_list https://192.168.3.63:8189,https://192.168.3.63:8289,https://192.168.3.63:8389
    ```
    
    Note that this will take a few minutes to complete. When it finishes you can check the status of the cluster this way
    
    ```
    [splunk@splunk_shc local]$ $SPLUNK_HOME/bin/splunk show shcluster-status
    
     Captain:
                              dynamic_captain : 1
                              elected_captain : Mon Jan 30 13:46:57 2017
                                           id : C3BFD3B4-B065-43F0-989F-DC875C097908
                             initialized_flag : 0
                                        label : sh1
                                     mgmt_uri : https://192.168.3.63:8189
                        min_peers_joined_flag : 1
                         rolling_restart_flag : 0
                           service_ready_flag : 1
    
     Members: 
            sh1
                                        label : sh1
                                     mgmt_uri : https://192.168.3.63:8189
                               mgmt_uri_alias : https://192.168.3.63:8189
                                       status : Up
            sh3
                                        label : sh3
                                     mgmt_uri : https://192.168.3.63:8389
                               mgmt_uri_alias : https://192.168.3.63:8389
                                       status : Up
            sh2
                                        label : sh2
                                     mgmt_uri : https://192.168.3.63:8289
                               mgmt_uri_alias : https://192.168.3.63:8289
                                       status : Up
    [splunk@splunk_shc local]$ 
    ```

8. Now that the cluster is configured and active, issue a rolling restart.

    ```
    [splunk@splunk_shc local]$ $SPLUNK_HOME/bin/splunk rolling-restart shcluster-members
      Rolling restart Success : 1 
      Message : Rolling Restart of all the search head cluster members has been kicked off. It might take some time for completion. After restart the information will be logged at audit log, Meanwhile you can check the progress of this transaction using  
             "splunk  rolling-restart shcluster-members -status 1"
    ```
    
    Here is what we just added to the server.conf:
    
    ```
    [replication_port://9100]
    
    [shclustering]
    disabled = 0
    mgmt_uri = https://192.168.3.63:8189
    pass4SymmKey = $1$xpmG3PQYEwVG3Q==
    id = C3BFD3B4-B065-43F0-989F-DC875C097908
    ```

9. Next step we need to tell the shcluster where the deployer is.

    ```
    export SPLUNK_HOME=/opt/sh1
    $SPLUNK_HOME/bin/splunk edit shcluster-config -conf_deploy_fetch_url https://192.168.3.64:8389 
    export SPLUNK_HOME=/opt/sh2
    $SPLUNK_HOME/bin/splunk edit shcluster-config -conf_deploy_fetch_url https://192.168.3.64:8389 
    export SPLUNK_HOME=/opt/sh3
    $SPLUNK_HOME/bin/splunk edit shcluster-config -conf_deploy_fetch_url https://192.168.3.64:8389 
    ```
    
    You will need to restart Splunk however since this is a cluster you need to do it in a rolling fashion. To do this
    you will need to first find out who the captain is and issue a rolling-restart command from the captain.
    
    ```
    [splunk@splunk_shc local]$ $SPLUNK_HOME/bin/splunk show shcluster-status
    
     Captain:
                              dynamic_captain : 1
                              elected_captain : Mon Jan 30 14:19:40 2017
                                           id : C3BFD3B4-B065-43F0-989F-DC875C097908
                             initialized_flag : 1
                                        label : sh1
                                     mgmt_uri : https://192.168.3.63:8189
                        min_peers_joined_flag : 1
                         rolling_restart_flag : 0
                           service_ready_flag : 1
    ...
    splunk@splunk_shc local]$ export SPLUNK_HOME=/opt/sh1
    [splunk@splunk_shc local]$ $SPLUNK_HOME/bin/splunk rolling-restart shcluster-members
      Rolling restart Success : 1 
      Message : Rolling Restart of all the search head cluster members has been kicked off. It might take some time for completion. After restart the information will be logged at audit log, Meanwhile you can check the progress of this transaction using  
             "splunk  rolling-restart shcluster-members -status 1"
     
    [splunk@splunk_shc local]$ 
    
    ```

10. Now lets setup the deployer, login to splunk_misc and set your env to dep.

    ```
    16:03:58 vagrant@splunk_misc:~] $ sudo -s su - splunk
    [splunk@splunk_misc ~]$ export SPLUNK_HOME=/opt/dep
    ```
    
    There is no Splunk command for this so you will need to edit the server.conf and restart splunk. Here are the steps.
    
    ```
    cd /opt/dep/etc/system/local
    cp ./server.conf ./server.conf.orig
    vi ./server.conf
    ```
    
    you will add this stanza:
    
    ``` 
    [shclustering]
    pass4SymmKey = shSymmKey
    ```
    
    Restart Splunk
    
    ``` 
    $SPLUNK_HOME/bin/splunk restart
    ```
    
    Note that splunk will hash the pass phrase when you restart it.

11. Now that we have this configured we can deploy apps to the sh-cluster through the deployer.

