global VROOT_MASTER ULIMIT_FILE ULIMIT_PROC
set VROOT_MASTER "imunes/template"
set ULIMIT_FILE "1024:16384"
set ULIMIT_PROC "1024:2048"

#****f* linux.tcl/l2node.nodeCreate
# NAME
#   l2node.nodeCreate -- nodeCreate
# SYNOPSIS
#   l2node.nodeCreate $eid $node
# FUNCTION
#   Procedure l2node.nodeCreate creates a new netgraph node of the appropriate type.
# INPUTS
#   * eid -- experiment id
#   * node -- id of the node (type of the node is either lanswitch or hub)
#****
proc l2node.nodeCreate { eid node } {
    set type [getNodeType $node]

    set ageing_time ""
    if { $type == "hub" } {
	set ageing_time "ageing_time 0"
    }

    set nodeNs [getNodeNetns $eid $node]
    pipesExec "ip netns exec $nodeNs ip link add name $node type bridge $ageing_time" "hold"
    pipesExec "ip netns exec $nodeNs ip link set $node up" "hold"
}

#****f* linux.tcl/l2node.nodeDestroy
# NAME
#   l2node.nodeDestroy -- destroy
# SYNOPSIS
#   l2node.nodeDestroy $eid $node
# FUNCTION
#   Destroys a l2 node.
# INPUTS
#   * eid -- experiment id
#   * node -- id of the node
#****
proc l2node.nodeDestroy { eid node } {
    set type [getNodeType $node]

    set nodeNs [getNodeNetns $eid $node]

    set nsstr ""
    if { $nodeNs != "" } {
	set nsstr "-n $nodeNs"
    }
    pipesExec "ip $nsstr link delete $node" "hold"

    removeNodeNetns $eid $node
}

#****f* linux.tcl/writeDataToNodeFile
# NAME
#   writeDataToNodeFile -- write data to virtual node
# SYNOPSIS
#   writeDataToNodeFile $node $path $data
# FUNCTION
#   Writes data to a file on the specified virtual node.
# INPUTS
#   * node -- virtual node id
#   * path -- path to file in node
#   * data -- data to write
#****
proc writeDataToNodeFile { node path data } {
    set node_id "[getFromRunning "eid"].$node"
    catch { exec docker inspect -f "{{.GraphDriver.Data.MergedDir}}" $node_id } node_dir

    writeDataToFile $node_dir/$path $data
}

#****f* linux.tcl/execCmdNode
# NAME
#   execCmdNode -- execute command on virtual node
# SYNOPSIS
#   execCmdNode $node $cmd
# FUNCTION
#   Executes a command on a virtual node and returns the output.
# INPUTS
#   * node -- virtual node id
#   * cmd -- command to execute
# RESULT
#   * returns the execution output
#****
proc execCmdNode { node cmd } {
    catch { eval [concat "exec docker exec " [getFromRunning "eid"].$node $cmd] } output

    return $output
}

#****f* linux.tcl/checkForExternalApps
# NAME
#   checkForExternalApps -- check whether external applications exist
# SYNOPSIS
#   checkForExternalApps $app_list
# FUNCTION
#   Checks whether a list of applications exist on the machine running IMUNES
#   by using the which command.
# INPUTS
#   * app_list -- list of applications
# RESULT
#   * returns 0 if the applications exist, otherwise it returns 1.
#****
proc checkForExternalApps { app_list } {
    foreach app $app_list {
	set status [ catch { exec which $app } err ]
	if { $status } {
	    return 1
	}
    }

    return 0
}

#****f* linux.tcl/checkForApplications
# NAME
#   checkForApplications -- check whether applications exist
# SYNOPSIS
#   checkForApplications $node $app_list
# FUNCTION
#   Checks whether a list of applications exist on the virtual node by using
#   the which command.
# INPUTS
#   * node -- virtual node id
#   * app_list -- list of applications
# RESULT
#   * returns 0 if the applications exist, otherwise it returns 1.
#****
proc checkForApplications { node app_list } {
    foreach app $app_list {
    set status [ catch { exec docker exec [getFromRunning "eid"].$node which $app } err ]
        if { $status } {
            return 1
        }
    }

    return 0
}

#****f* linux.tcl/startWiresharkOnNodeIfc
# NAME
#   startWiresharkOnNodeIfc -- start wireshark on an interface
# SYNOPSIS
#   startWiresharkOnNodeIfc $node $iface_name
# FUNCTION
#   Start Wireshark on a virtual node on the specified interface.
# INPUTS
#   * node -- virtual node id
#   * iface_name -- virtual node interface
#****
proc startWiresharkOnNodeIfc { node iface_name } {
    set eid [getFromRunning "eid"]

    if { [checkForExternalApps "startxcmd"] == 0 && \
	[checkForApplications $node "wireshark"] == 0 } {

        startXappOnNode $node "wireshark -ki $iface_name"
    } else {
	set wiresharkComm ""
	foreach wireshark "wireshark wireshark-gtk wireshark-qt" {
	    if { [checkForExternalApps $wireshark] == 0 } {
		set wiresharkComm $wireshark
		break
	    }
	}

	if { $wiresharkComm != "" } {
	    exec docker exec $eid.$node tcpdump -s 0 -U -w - -i $iface_name 2>/dev/null |\
		$wiresharkComm -o "gui.window_title:$iface_name@[getNodeName $node] ($eid)" -k -i - &
	} else {
            tk_dialog .dialog1 "IMUNES error" \
	"IMUNES could not find an installation of Wireshark.\
	If you have Wireshark installed, submit a bug report." \
            info 0 Dismiss
	}
    }
}

#****f* linux.tcl/startXappOnNode
# NAME
#   startXappOnNode -- start X application in a virtual node
# SYNOPSIS
#   startXappOnNode $node $app
# FUNCTION
#   Start X application on virtual node
# INPUTS
#   * node -- virtual node id
#   * app -- application to start
#****
proc startXappOnNode { node app } {
    global debug

    set eid [getFromRunning "eid"]
    if { [checkForExternalApps "socat"] != 0 } {
        puts "To run X applications on the node, install socat on your host."
        return
    }

    set logfile "/dev/null"
    if { $debug } {
        set logfile "/tmp/startxcmd_$eid\_$node.log"
    }

    eval exec startxcmd [getNodeName $node]@$eid $app > $logfile 2>> $logfile &
}

#****f* linux.tcl/startTcpdumpOnNodeIfc
# NAME
#   startTcpdumpOnNodeIfc -- start tcpdump on an interface
# SYNOPSIS
#   startTcpdumpOnNodeIfc $node $iface_name
# FUNCTION
#   Start tcpdump in xterm on a virtual node on the specified interface.
# INPUTS
#   * node -- virtual node id
#   * iface_name -- virtual node interface
#****
proc startTcpdumpOnNodeIfc { node iface_name } {
    if { [checkForApplications $node "tcpdump"] == 0 } {
        spawnShell $node "tcpdump -ni $iface_name"
    }
}

#****f* linux.tcl/existingShells
# NAME
#   existingShells -- check which shells exist in a node
# SYNOPSIS
#   existingShells $shells $node
# FUNCTION
#   This procedure checks which of the provided shells are available
#   in a running node.
# INPUTS
#   * shells -- list of shells.
#   * node -- node id of the node for which the check is performed.
#****
proc existingShells { shells node } {
    set existing []
    foreach shell $shells {
        set cmd "docker exec [getFromRunning "eid"].$node which $shell"
        set err [catch { eval exec $cmd } res]
        if  { ! $err } {
            lappend existing $res
        }
    }

    return $existing
}

#****f* linux.tcl/spawnShell
# NAME
#   spawnShell -- spawn shell
# SYNOPSIS
#   spawnShell $node $cmd
# FUNCTION
#   This procedure spawns a new shell for a specified node.
#   The shell is specified in cmd parameter.
# INPUTS
#   * node -- node id of the node for which the shell is spawned.
#   * cmd -- the path to the shell.
#****
proc spawnShell { node cmd } {
    if { [catch { exec xterm -version }] } {
	tk_dialog .dialog1 "IMUNES error" \
	    "Cannot open terminal. Is xterm installed?" \
            info 0 Dismiss

	return
    }

    set node_id [getFromRunning "eid"]\.$node

    # FIXME make this modular
    exec xterm -sb -rightbar \
    -T "IMUNES: [getNodeName $node] (console) [string trim [lindex [split $cmd /] end] ']" \
    -e "docker exec -it $node_id $cmd" 2> /dev/null &
}

#****f* linux.tcl/fetchRunningExperiments
# NAME
#   fetchRunningExperiments -- fetch running experiments
# SYNOPSIS
#   fetchRunningExperiments
# FUNCTION
#   Returns IDs of all running experiments as a list.
# RESULT
#   * exp_list -- experiment id list
#****
proc fetchRunningExperiments {} {
    catch { exec himage -l | cut -d " " -f 1 } exp_list
    set exp_list [split $exp_list "
"]
    return "$exp_list"
}

#****f* linux.tcl/allSnapshotsAvailable
# NAME
#   allSnapshotsAvailable -- all snapshots available
# SYNOPSIS
#   allSnapshotsAvailable
# FUNCTION
#   Procedure that checks whether all node snapshots are available on the
#   current system.
#****
proc allSnapshotsAvailable {} {
    global VROOT_MASTER execMode

    set snapshots $VROOT_MASTER
    foreach node [getFromRunning "node_list"] {
	set img [getNodeCustomImage $node]
	if { $img != "" } {
	    lappend snapshots $img
	}
    }
    set snapshots [lsort -uniq $snapshots]
    set missing 0

    foreach template $snapshots {
	set search_template $template
	if { [string match "*:*" $template] != 1 } {
	    append search_template ":latest"
	}

	catch { exec docker images -q $search_template } images
	if { [llength $images] > 0 } {
	    continue
	} else {
	    # be nice to the user and see whether there is an image id matching
	    if { [string length $template] == 12 } {
                catch { exec docker images -q } all_images
		if { [lsearch $all_images $template] == -1 } {
		    incr missing
		}
	    } else {
		incr missing
	    }
	    if { $missing } {
                if { $execMode == "batch" } {
                    puts "Docker image for some virtual nodes:
    $template
is missing.
Run 'docker pull $template' to pull the template."
	        } else {
                   tk_dialog .dialog1 "IMUNES error" \
	    "Docker image for some virtual nodes:
    $template
is missing.
Run 'docker pull $template' to pull the template." \
                   info 0 Dismiss
	        }
	        return 0
	    }
	}
    }
    return 1
}

proc prepareDevfs { { force 0 } } {}

#****f* linux.tcl/getHostIfcList
# NAME
#   getHostIfcList -- get interfaces list from host
# SYNOPSIS
#   getHostIfcList
# FUNCTION
#   Returns the list of all network interfaces on the host.
# RESULT
#   * extifcs -- list of all external interfaces
#****
proc getHostIfcList {} {
    # fetch interface list from the system
    set extifcs [exec ls /sys/class/net]
    # exclude loopback interface
    set ilo [lsearch $extifcs lo]
    set extifcs [lreplace $extifcs $ilo $ilo]

    return $extifcs
}

#****f* linux.tcl/getHostIfcVlanExists
# NAME
#   getHostIfcVlanExists -- check if host VLAN interface exists
# SYNOPSIS
#   getHostIfcVlanExists $node $ifname
# FUNCTION
#   Returns 1 if VLAN interface with the name $ifname for the given node cannot
#   be created.
# INPUTS
#   * node -- node id
#   * ifname -- interface name
# RESULT
#   * check -- 1 if interface exists, 0 otherwise
#****
proc getHostIfcVlanExists { node ifname } {
    global execMode

    # check if VLAN ID is already taken
    # this can be only done by trying to create it, as it's possible that the same
    # VLAN interface already exists in some other namespace
    set iface_id [ifaceIdFromName $node $ifname]
    set vlan [getIfcVlanTag $node $iface_id]
    try {
	exec ip link add link $ifname name $ifname.$vlan type vlan id $vlan
    } on ok {} {
	exec ip link del $ifname.$vlan
	return 0
    } on error err {
	set msg "Unable to create external interface '$ifname.$vlan':\n$err\n\nPlease\
	    verify that VLAN ID $vlan with parent interface $ifname is not already\
	    assigned to another VLAN interface, potentially in a different namespace."
    }

    if { $execMode == "batch" } {
	puts $msg
    } else {
	after idle {.dialog1.msg configure -wraplength 4i}
	tk_dialog .dialog1 "IMUNES error" $msg \
	    info 0 Dismiss
    }

    return 1
}

proc removeNodeFS { eid node } {
    set VROOT_BASE [getVrootDir]

    pipesExec "rm -fr $VROOT_BASE/$eid/$node" "hold"
}

proc getNodeNetns { eid node } {
    global devfs_number

    # Top-level experiment netns
    if { $node in "" || [getNodeType $node] == "rj45" } {
	return $eid
    }

    # Global netns
    if { [getNodeType $node] in "ext extnat" } {
	return ""
    }

    # Node netns
    return $eid-$node
}

proc destroyNodeVirtIfcs { eid node } {
    set node_id "$eid.$node"

    pipesExec "docker exec -d $node_id sh -c 'for iface in `ls /sys/class/net` ; do ip link del \$iface; done'" "hold"
}

proc loadKernelModules {} {
    global all_modules_list

    foreach module $all_modules_list {
        if { [info procs $module.prepareSystem] == "$module.prepareSystem" } {
            $module.prepareSystem
        }
    }
}

proc prepareVirtualFS {} {
    exec mkdir -p /var/run/netns
}

proc attachToL3NodeNamespace { node } {
    set eid [getFromRunning "eid"]

    if { [getNodeDockerAttach $node] != "true" } {
	pipesExec "docker network disconnect imunes-bridge $eid.$node" "hold"
    }

    # VIRTUALIZED nodes use docker netns
    set cmds "docker_ns=\$(docker inspect -f '{{.State.Pid}}' $eid.$node)"
    set cmds "$cmds; ip netns del \$docker_ns > /dev/null 2>&1"
    set cmds "$cmds; ip netns attach $eid-$node \$docker_ns"
    set cmds "$cmds; docker exec -d $eid.$node umount /etc/resolv.conf /etc/hosts"

    pipesExec "sh -c \'$cmds\'" "hold"
}

proc createNamespace { ns } {
    pipesExec "ip netns add $ns" "hold"
}

proc destroyNamespace { ns } {
    pipesExec "ip netns del $ns" "hold"
}

proc createExperimentContainer {} {
    global devfs_number

    catch { exec ip netns attach imunes_$devfs_number 1 }
    catch { exec docker network create --opt com.docker.network.container_iface_prefix=dext imunes-bridge }

    # Top-level experiment netns
    exec ip netns add [getFromRunning "eid"]
}

#****f* linux.tcl/prepareFilesystemForNode
# NAME
#   prepareFilesystemForNode -- prepare node filesystem
# SYNOPSIS
#   prepareFilesystemForNode $node
# FUNCTION
#   Prepares the node virtual filesystem.
# INPUTS
#   * node -- node id
#****
proc prepareFilesystemForNode { node } {
    set VROOTDIR /var/imunes
    set VROOT_RUNTIME $VROOTDIR/[getFromRunning "eid"]/$node

    pipesExec "mkdir -p $VROOT_RUNTIME" "hold"
}

#****f* linux.tcl/createNodeContainer
# NAME
#   createNodeContainer -- creates a virtual node container
# SYNOPSIS
#   createNodeContainer $node
# FUNCTION
#   Creates a docker instance using the defined template and
#   assigns the hostname. Waits for the node to be up.
# INPUTS
#   * node -- node id
#****
proc createNodeContainer { node } {
    global VROOT_MASTER ULIMIT_FILE ULIMIT_PROC debug

    set node_id "[getFromRunning "eid"].$node"

    set network "imunes-bridge"
    #if { [getNodeDockerAttach $node] == "true" } {
	#set network "bridge"
    #}

    set vroot [getNodeCustomImage $node]
    if { $vroot == "" } {
        set vroot $VROOT_MASTER
    }

    pipesExec "docker run --detach --init --tty \
	--privileged --cap-add=ALL --net=$network \
	--name $node_id --hostname=[getNodeName $node] \
	--volume /tmp/.X11-unix:/tmp/.X11-unix \
	--sysctl net.ipv6.conf.all.disable_ipv6=0 \
	--ulimit nofile=$ULIMIT_FILE --ulimit nproc=$ULIMIT_PROC \
	$vroot &" "hold"
}

proc isNodeStarted { node } {
    set node_id "[getFromRunning "eid"].$node"

    catch { exec docker inspect --format '{{.State.Running}}' $node_id } status

    return [string match 'true' $status]
}

proc isNodeNamespaceCreated { node } {
    set nodeNs [getNodeNetns [getFromRunning "eid"] $node]

    if { $nodeNs == "" } {
	return true
    }

    try {
       exec ip netns exec $nodeNs true
    } on error {} {
       return false
    }

    return true
}

#****f* linux.tcl/nodePhysIfacesCreate
# NAME
#   nodePhysIfacesCreate -- create node physical interfaces
# SYNOPSIS
#   nodePhysIfacesCreate $node
# FUNCTION
#   Creates physical interfaces for the given node.
# INPUTS
#   * node -- node id
#****
proc nodePhysIfacesCreate { node_id ifcs } {
    set eid [getFromRunning "eid"]

    set nodeNs [getNodeNetns $eid $node_id]
    set node_type [getNodeType $node_id]

    # Create "physical" network interfaces
    foreach iface_id $ifcs {
	setToRunning "${node_id}|${iface_id}_running" true
	set iface_name [getIfcName $node_id $iface_id]
	set public_hook $node_id-$iface_name
	set prefix [string trimright $iface_name "0123456789"]
	if { $node_type in "ext extnat" } {
	    set iface_name $node_id
	}

	# direct link, simulate capturing the host interface into the node,
	# without bridges between them
	set peer [getIfcPeer $node_id $iface_id]
	if { $peer != "" } {
	    set link [linkByPeers $node_id $peer]
	    if { $link != "" && [getLinkDirect $link] } {
		continue
	    }
	}

	switch -exact $prefix {
	    e -
	    ext -
	    eth {
		# Create a veth pair - private hook in node netns and public hook
		# in the experiment netns
		createNsVethPair $iface_name $nodeNs $public_hook $eid
	    }
	}

	switch -exact $prefix {
	    e {
		# bridge private hook with L2 node
		setNsIfcMaster $nodeNs $iface_name $node_id "up"
	    }
	    ext {
		# bridge private hook with ext node
		#setNsIfcMaster $nodeNs $iface_id $eid-$node_id "up"
	    }
	    eth {
		#set ether [getIfcMACaddr $node_id $iface_id]
		#if { $ether == "" } {
		#    autoMACaddr $node_id $iface_id
		#    set ether [getIfcMACaddr $node_id $iface_id]
		#}

		#set nsstr ""
		#if { $nodeNs != "" } {
		#    set nsstr "-n $nodeNs"
		#}
		#pipesExec "ip $nsstr link set $iface_id address $ether" "hold"
	    }
	    default {
		# capture physical interface directly into the node, without using a bridge
		# we don't know the name, so make sure all other options cover other IMUNES
		# 'physical' interfaces
		# XXX not yet implemented
		if { [getIfcType $node_id $iface_id] == "stolen" } {
		    captureExtIfcByName $eid $iface_name $node_id
		}
	    }
	}
    }

    pipesExec ""
}

#****f* linux.tcl/killProcess
# NAME
#   killProcess -- kill processes with the given regex
# SYNOPSIS
#   killProcess $regex
# FUNCTION
#   Executes a pkill command to kill all processes with a corresponding regex.
# INPUTS
#   * regex -- regularl expression of the processes
#****
proc killExtProcess { regex } {
    pipesExec "pkill -f \"$regex\"" "hold"
}

proc checkHangingTCPs { eid nodes } {}

#****f* linux.tcl/nodeLogIfacesCreate
# NAME
#   nodeLogIfacesCreate -- create node logical interfaces
# SYNOPSIS
#   nodeLogIfacesCreate $node_id
# FUNCTION
#   Creates logical interfaces for the given node.
# INPUTS
#   * node_id -- node id
#****
proc nodeLogIfacesCreate { node_id ifaces } {
    set docker_node "[getFromRunning "eid"].$node_id"

    foreach iface_id $ifaces {
	setToRunning "${node_id}|${iface_id}_running" true

	set iface_name [getIfcName $node_id $iface_id]
	switch -exact [getIfcType $node_id $iface_id] {
	    vlan {
		set tag [getIfcVlanTag $node_id $iface_id]
		set dev [getIfcVlanDev $node_id $iface_id]
		if { $tag != "" && $dev != "" } {
		    pipesExec "docker exec -d $docker_node [getVlanTagIfcCmd $iface_name $dev $tag]" "hold"
		}
	    }
	    lo {
		if { $iface_name != "lo0" } {
		    pipesExec "docker exec -d $docker_node ip link add $iface_name type dummy" "hold"
		    pipesExec "docker exec -d $docker_node ip link set $iface_name up" "hold"
		} else {
		    pipesExec "docker exec -d $docker_node ip link set dev lo down 2>/dev/null" "hold"
		    pipesExec "docker exec -d $docker_node ip link set dev lo name lo0 2>/dev/null" "hold"
		    pipesExec "docker exec -d $docker_node ip a flush lo0 2>/dev/null" "hold"
		}
	    }
	}
    }

#    # docker interface is created before other ones, so let's rename it to something that's not used by IMUNES
#    if { [getNodeDockerAttach $node_id] == 1 } {
#	set cmds "ip r save > /tmp/routes"
#	set cmds "$cmds ; ip l set eth0 down"
#	set cmds "$cmds ; ip l set eth0 name docker0"
#	set cmds "$cmds ; ip l set docker0 up"
#	set cmds "$cmds ; ip r restore < /tmp/routes"
#	set cmds "$cmds ; rm -f /tmp/routes"
#	pipesExec "docker exec -d $docker_node sh -c '$cmds'" "hold"
#    }
}

#****f* linux.tcl/configureICMPoptions
# NAME
#   configureICMPoptions -- configure ICMP options
# SYNOPSIS
#   configureICMPoptions $node_id
# FUNCTION
#  Configures the necessary ICMP sysctls in the given node.
# INPUTS
#   * node_id -- node id
#****
proc configureICMPoptions { node_id } {
    array set sysctl_icmp {
	net.ipv4.icmp_ratelimit			0
	net.ipv4.icmp_echo_ignore_broadcasts	1
    }

    foreach {name val} [array get sysctl_icmp] {
	lappend cmd "sysctl $name=$val"
    }
    set cmds [join $cmd "; "]

    pipesExec "docker exec -d [getFromRunning "eid"].$node_id sh -c '$cmds ; touch /tmp/init'" "hold"
}

proc isNodeInitNet { node } {
    set node_id "[getFromRunning "eid"].$node"

    try {
	exec docker inspect -f "{{.GraphDriver.Data.MergedDir}}" $node_id
    } on ok mergedir {
	try {
	    exec test -f ${mergedir}/tmp/init
	} on error {} {
	    return false
	}
    } on error {} {
	return false
    }

    return true
}

proc createNsLinkBridge { netNs link } {
    set nsstr ""
    if { $netNs != "" } {
	set nsstr "-n $netNs"
    }

    pipesExec "ip $nsstr link add name $link type bridge ageing_time 0 mcast_snooping 0" "hold"
    pipesExec "ip $nsstr link set $link multicast off" "hold"
    pipesExec "ip netns exec $netNs sysctl net.ipv6.conf.$link.disable_ipv6=1" "hold"
    pipesExec "ip $nsstr link set $link up" "hold"
}

proc createNsVethPair { ifname1 netNs1 ifname2 netNs2 } {
    set eid [getFromRunning "eid"]

    set nsstr1 ""
    set nsstr1x ""
    if { $netNs1 != "" } {
	set nsstr1 "netns $netNs1"
	set nsstr1x "-n $netNs1"
    }

    set nsstr2 ""
    set nsstr2x ""
    if { $netNs2 != "" } {
	set nsstr2 "netns $netNs2"
	set nsstr2x "-n $netNs2"
    }

    pipesExec "ip link add name $eid-$ifname1 $nsstr1 type veth peer name $eid-$ifname2 $nsstr2" "hold"

    if { $nsstr1x != "" } {
	pipesExec "ip $nsstr1x link set $eid-$ifname1 name $ifname1" "hold"
    }

    if { $nsstr2x != "" } {
	pipesExec "ip $nsstr2x link set $eid-$ifname2 name $ifname2" "hold"
    }

    if { $netNs2 == $eid } {
	pipesExec "ip netns exec $eid ip link set $ifname2 multicast off" "hold"
	pipesExec "ip netns exec $eid sysctl net.ipv6.conf.$ifname2.disable_ipv6=1" "hold"
    }
}

proc setNsIfcMaster { netNs ifname master state } {
    set nsstr ""
    if { $netNs != "" } {
	set nsstr "-n $netNs"
    }
    pipesExec "ip $nsstr link set $ifname master $master $state" "hold"
}

#****f* linux.tcl/createDirectLinkBetween
# NAME
#   createDirectLinkBetween -- create direct link between
# SYNOPSIS
#   createDirectLinkBetween $lnode1 $lnode2 $iface1_id $iface2_id
# FUNCTION
#   Creates direct link between two given nodes. Direct link connects the host
#   interface into the node, without ng_node between them.
# INPUTS
#   * lnode1 -- node id of the first node
#   * lnode2 -- node id of the second node
#   * iname1 -- interface name on the first node
#   * iname2 -- interface name on the second node
#****
proc createDirectLinkBetween { lnode1 lnode2 iface1_id iface2_id } {
    set eid [getFromRunning "eid"]

    if { "rj45" in "[getNodeType $lnode1] [getNodeType $lnode2]" } {
	if { [getNodeType $lnode1] == "rj45" } {
	    set physical_ifc [getIfcName $lnode1 $iface1_id]
	    set vlan [getIfcVlanTag $lnode1 $iface1_id]
	    set physical_ifc $physical_ifc.$vlan
	    set nodeNs [getNodeNetns $eid $lnode2]
	    set full_virtual_ifc $eid-$lnode2-$iface2_id
	    set virtual_ifc $iface2_id
	    set ether [getIfcMACaddr $lnode2 $virtual_ifc]

	    if { [[getNodeType $lnode2].virtlayer] == "NATIVE" } {
		pipesExec "ip link set $physical_ifc netns $nodeNs" "hold"
		setNsIfcMaster $nodeNs $physical_ifc $lnode2 "up"
		return
	    }
	} else {
	    set physical_ifc [getIfcName $lnode2 $iface2_id]
	    set vlan [getIfcVlanTag $lnode2 $iface2_id]
	    set physical_ifc $physical_ifc.$vlan
	    set nodeNs [getNodeNetns $eid $lnode1]
	    set full_virtual_ifc $eid-$lnode1-$iface1_id
	    set virtual_ifc $iface1_id
	    set ether [getIfcMACaddr $lnode1 $virtual_ifc]

	    if { [[getNodeType $lnode1].virtlayer] == "NATIVE" } {
		pipesExec "ip link set $physical_ifc netns $nodeNs" "hold"
		setNsIfcMaster $nodeNs $physical_ifc $lnode1 "up"
		return
	    }
	}

	try {
	    exec test -d /sys/class/net/$physical_ifc/wireless
	} on error {} {
	    # not wireless
	    set cmds "ip link add link $physical_ifc name $full_virtual_ifc netns $nodeNs type macvlan mode private"
	    set cmds "$cmds ; ip -n $nodeNs link set $full_virtual_ifc address $ether"
	} on ok {} {
	    # we cannot use macvlan on wireless interfaces, so MAC address cannot be changed
	    set cmds "ip link add link $physical_ifc name $full_virtual_ifc netns $nodeNs type ipvlan mode l2"
	}

	set cmds "$cmds ; ip link set $physical_ifc up"
	set cmds "$cmds ; ip -n $nodeNs link set $full_virtual_ifc name $virtual_ifc"
	set cmds "$cmds ; ip -n $nodeNs link set $virtual_ifc up"
	pipesExec "$cmds" "hold"

	return
    }

    if { [getNodeType $lnode1] in "ext extnat" } {
	set iface1_name $eid-$lnode1
    } else {
	set iface1_name [getIfcName $lnode1 $iface1_id]
    }

    if { [getNodeType $lnode2] in "ext extnat" } {
	set iface2_name $eid-$lnode2
    } else {
	set iface2_name [getIfcName $lnode2 $iface2_id]
    }

    set node1Ns [getNodeNetns $eid $lnode1]
    set node2Ns [getNodeNetns $eid $lnode2]
    createNsVethPair $iface1_name $node1Ns $iface2_name $node2Ns

    # add nodes iface hooks to link bridge and bring them up
    foreach node_id [list $lnode1 $lnode2] iface_id [list $iface1_id $iface2_id] ns [list $node1Ns $node2Ns] {
	if { [[getNodeType $node_id].virtlayer] != "NATIVE" || [getNodeType $node_id] in "ext extnat" } {
	    continue
	}

	setNsIfcMaster $ns $iface_id $node_id "up"
    }
}

proc createLinkBetween { lnode1 lnode2 iface1_id iface2_id link } {
    set eid [getFromRunning "eid"]

    # create link bridge in experiment netns
    createNsLinkBridge $eid $link

    # add nodes iface hooks to link bridge and bring them up
    foreach node_id "$lnode1 $lnode2" iface_id "$iface1_id $iface2_id" {
	if { [getNodeType $node_id] == "rj45" } {
	    set iface_name [getIfcName $node_id $iface_id]
	    if { [getIfcVlanDev $node_id $iface_id] != "" } {
		set vlan [getIfcVlanTag $node_id $iface_id]
		set iface_name $iface_name.$vlan
	    }
	} else {
	    set iface_name $node_id-[getIfcName $node_id $iface_id]
	}

	setNsIfcMaster $eid $iface_name $link "up"
    }
}

proc configureLinkBetween { lnode1 lnode2 iface1_id iface2_id link } {
    set eid [getFromRunning "eid"]

    set bandwidth [expr [getLinkBandwidth $link] + 0]
    set delay [expr [getLinkDelay $link] + 0]
    set ber [expr [getLinkBER $link] + 0]
    set loss [expr [getLinkLoss $link] + 0]
    set dup [expr [getLinkDup $link] + 0]

    configureIfcLinkParams $eid $lnode1 $iface1_id $bandwidth $delay $ber $loss $dup
    configureIfcLinkParams $eid $lnode2 $iface2_id $bandwidth $delay $ber $loss $dup

    # FIXME: remove this to interface configuration?
    foreach node_id "$lnode1 $lnode2" iface_id "$iface1_id $iface2_id" {
	if { [getNodeType $node_id] == "rj45" } {
	    continue
	}

	set qdisc [getIfcQDisc $node_id $iface_id]
	if { $qdisc != "FIFO" } {
	    execSetIfcQDisc $eid $node_id $iface_id $qdisc
	}
	set qlen [getIfcQLen $node_id $iface_id]
	if { $qlen != 1000 } {
	    execSetIfcQLen $eid $node_id $iface_id $qlen
	}
    }
}

proc startNodeIfaces { node_id ifaces } {
    set eid [getFromRunning "eid"]

    set docker_node "$eid.$node_id"

    if { [getCustomEnabled $node_id] == true } {
	return
    }

    set bootcfg [[getNodeType $node_id].generateConfigIfaces $node_id $ifaces]
    set bootcmd [[getNodeType $node_id].bootcmd $node_id]
    set confFile "boot_ifaces.conf"

    #set cfg [join "{ip a flush dev lo0} $bootcfg" "\n"]
    set cfg [join "{set -x} $bootcfg" "\n"]
    writeDataToNodeFile $node_id /$confFile $cfg
    set cmds "$bootcmd /$confFile >> /tout_ifaces.log 2>> /terr_ifaces.log ;"
    # renaming the file signals that we're done
    set cmds "$cmds mv /tout_ifaces.log /out_ifaces.log ;"
    set cmds "$cmds mv /terr_ifaces.log /err_ifaces.log"
    pipesExec "docker exec -d $docker_node sh -c '$cmds'" "hold"
}

proc unconfigNode { eid node_id } {
    set docker_node "$eid.$node_id"

    if { [getCustomEnabled $node_id] == true } {
	return
    }

    set bootcfg [[getNodeType $node_id].generateUnconfig $node_id]
    set bootcmd [[getNodeType $node_id].bootcmd $node_id]
    set confFile "boot.conf"

    #set cfg [join "{ip a flush dev lo0} $bootcfg" "\n"]
    set cfg [join "{set -x} $bootcfg" "\n"]
    writeDataToNodeFile $node_id /$confFile $cfg
    set cmds "$bootcmd /$confFile >> /tout.log 2>> /terr.log ;"
    # renaming the file signals that we're done
    set cmds "$cmds mv /tout.log /out.log ;"
    set cmds "$cmds mv /terr.log /err.log"
    pipesExec "docker exec -d $docker_node sh -c '$cmds'" "hold"
}

proc unconfigNodeIfaces { eid node_id ifaces } {
    set docker_node "$eid.$node_id"

    if { [getCustomEnabled $node_id] == true } {
	return
    }

    set bootcfg [[getNodeType $node_id].generateUnconfigIfaces $node_id $ifaces]
    set bootcmd [[getNodeType $node_id].bootcmd $node_id]
    set confFile "boot_ifaces.conf"

    #set cfg [join "{ip a flush dev lo0} $bootcfg" "\n"]
    set cfg [join "{set -x} $bootcfg" "\n"]
    writeDataToNodeFile $node_id /$confFile $cfg
    set cmds "$bootcmd /$confFile >> /tout_ifaces.log 2>> /terr_ifaces.log ;"
    # renaming the file signals that we're done
    set cmds "$cmds mv /tout_ifaces.log /out_ifaces.log ;"
    set cmds "$cmds mv /terr_ifaces.log /err_ifaces.log"
    pipesExec "docker exec -d $docker_node sh -c '$cmds'" "hold"
}

#proc isNodeIfacesConfigured { node } {
#    # TODO
#    return true
#}

proc isNodeConfigured { node } {
    set node_id "[getFromRunning "eid"].$node"

    if { [[getNodeType $node].virtlayer] == "NATIVE" } {
	return true
    }

    try {
	# docker exec sometimes hangs, so don't use it while we have other pipes opened
	exec docker inspect -f "{{.GraphDriver.Data.MergedDir}}" $node_id
    } on ok mergedir {
	try {
	    exec test -f ${mergedir}/out.log
	} on error {} {
	    return false
	} on ok {} {
	    return true
	}
    } on error err {
	puts "Error on docker inspect: '$err'"
    }

    return false
}

proc isNodeError { node } {
    set node_id "[getFromRunning "eid"].$node"

    if { [[getNodeType $node].virtlayer] == "NATIVE" } {
	return false
    }

    try {
	# docker exec sometimes hangs, so don't use it while we have other pipes opened
	exec docker inspect -f "{{.GraphDriver.Data.MergedDir}}" $node_id
    } on ok mergedir {
	if { ! [file exists ${mergedir}/err.log] } {
	    return ""
	}

	catch { exec sed "/^+ /d" ${mergedir}/err.log } errlog
	if { $errlog == "" } {
	    return false
	}

	return true
    } on error err {
	puts "Error on docker inspect: '$err'"
    }

    return true
}

proc isNodeErrorIfaces { node } {
    set node_id "[getFromRunning "eid"].$node"

    if { [getCustomEnabled $node] || [[getNodeType $node].virtlayer] == "NATIVE" } {
	return false
    }

    try {
	# docker exec sometimes hangs, so don't use it while we have other pipes opened
	exec docker inspect -f "{{.GraphDriver.Data.MergedDir}}" $node_id
    } on ok mergedir {
	if { ! [file exists ${mergedir}/err_ifaces.log] } {
	    return ""
	}

	catch { exec sed "/^+ /d" ${mergedir}/err_ifaces.log } errlog
	if { $errlog == "" } {
	    return false
	}

	return true
    } on error err {
	puts "Error on docker inspect: '$err'"
    }

    return true
}

proc removeNetns { netns } {
    if { $netns != "" } {
	exec ip netns del $netns
    }
}

proc removeNodeNetns { eid node } {
    set netns [getNodeNetns $eid $node]

    if { $netns != "" } {
	pipesExec "ip netns del $netns" "hold"
    }
}

proc terminate_removeExperimentContainer { eid } {
    removeNetns $eid
}

proc terminate_removeExperimentFiles { eid } {
    set VROOT_BASE [getVrootDir]
    catch "exec rm -fr $VROOT_BASE/$eid &"
}

proc removeNodeContainer { eid node } {
    set node_id $eid.$node

    pipesExec "docker kill $node_id" "hold"
    pipesExec "docker rm $node_id" "hold"
}

proc killAllNodeProcesses { eid node } {
    set node_id "$eid.$node"

    # kill all processes except pid 1 and its child(ren)
    pipesExec "docker exec -d $node_id sh -c 'killall5 -9 -o 1 -o \$(pgrep -P 1)'" "hold"
}

proc runConfOnNode { node } {
    set eid [getFromRunning "eid"]

    set node_id "$eid.$node"

    if { [getCustomEnabled $node] == true } {
        set selected [getCustomConfigSelected $node]

        set bootcmd [getCustomConfigCommand $node $selected]
        set bootcfg [getCustomConfig $node $selected]
	if { [getAutoDefaultRoutesStatus $node] == "enabled" } {
	    foreach statrte [getDefaultIPv4routes $node] {
		lappend bootcfg [getIPv4RouteCmd $statrte]
	    }
	    foreach statrte [getDefaultIPv6routes $node] {
		lappend bootcfg [getIPv6RouteCmd $statrte]
	    }
	}
        set confFile "custom.conf"
    } else {
        set bootcfg [[getNodeType $node].generateConfig $node]
        set bootcmd [[getNodeType $node].bootcmd $node]
        set confFile "boot.conf"
    }

    generateHostsFile $node

    set nodeNs [getNodeNetns $eid $node]
    foreach ifc [allIfcList $node] {
	if { [getIfcOperState $node $ifc] == "down" } {
	    pipesExec "ip -n $nodeNs link set dev $ifc down"
	}
    }

    #set cfg [join "{ip a flush dev lo0} $bootcfg" "\n"]
    set cfg [join "{set -x} $bootcfg" "\n"]
    writeDataToNodeFile $node /$confFile $cfg
    set cmds "$bootcmd /$confFile >> /tout.log 2>> /terr.log ;"
    # renaming the file signals that we're done
    set cmds "$cmds mv /tout.log /out.log ;"
    set cmds "$cmds mv /terr.log /err.log"
    pipesExec "docker exec -d $node_id sh -c '$cmds'" "hold"
}

proc destroyDirectLinkBetween { eid lnode1 lnode2 } {
    if { [getNodeType $lnode1] in "ext extnat" } {
	pipesExec "ip link del $eid-$lnode1" "hold"
    } elseif { [getNodeType $lnode2] in "ext extnat" } {
	pipesExec "ip link del $eid-$lnode2" "hold"
    }
}

proc destroyLinkBetween { eid lnode1 lnode2 link } {
    pipesExec "ip -n $eid link del $link" "hold"
}

#****f* linux.tcl/destroyNodeIfaces
# NAME
#   destroyNodeIfaces -- destroy virtual node interfaces
# SYNOPSIS
#   destroyNodeIfaces $eid $vimages
# FUNCTION
#   Destroys all virtual node interfaces.
# INPUTS
#   * eid -- experiment id
#   * vimages -- list of virtual nodes
#****
proc destroyNodeIfaces { eid node_id ifaces } {
    puts "destroyNodeIfaces $eid $node_id $ifaces"
    set node_type [getNodeType $node_id]
    if { $node_type in "ext extnat" } {
	pipesExec "ip link del $eid-$node_id" "hold"
    } elseif { $node_type == "rj45" } {
	foreach iface_id $ifaces {
	    releaseExtIfcByName $eid [getIfcName $node_id $iface_id] $node_id
	}
    } else {
	foreach iface_id $ifaces {
	    set iface_name [getIfcName $node_id $iface_id]
	    if { [getIfcType $node_id $iface_id] == "stolen" } {
		releaseExtIfcByName $eid $iface_name $node_id
	    } else {
		pipesExec "ip -n $eid link del $node_id-$iface_name" "hold"
	    }
	}
    }

    foreach iface_id $ifaces {
	setToRunning "${node_id}|${iface_id}_running" false
    }
}

#****f* linux.tcl/removeNodeIfcIPaddrs
# NAME
#   removeNodeIfcIPaddrs -- remove node iterfaces' IP addresses
# SYNOPSIS
#   removeNodeIfcIPaddrs $eid $node
# FUNCTION
#   Remove all IPv4 and IPv6 addresses from interfaces on the given node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc removeNodeIfcIPaddrs { eid node } {
    set node_id "$eid.$node"
    foreach ifc [allIfcList $node] {
	pipesExec "docker exec -d $node_id sh -c 'ip addr flush dev $ifc'" "hold"
    }
}

#****f* linux.tcl/getCpuCount
# NAME
#   getCpuCount -- get CPU count
# SYNOPSIS
#   getCpuCount
# FUNCTION
#   Gets a CPU count of the host machine.
# RESULT
#   * cpucount - CPU count
#****
proc getCpuCount {} {
    return [lindex [exec grep -c processor /proc/cpuinfo] 0]
}

#****f* linux.tcl/enableIPforwarding
# NAME
#   enableIPforwarding -- enable IP forwarding
# SYNOPSIS
#   enableIPforwarding $node_id
# FUNCTION
#   Enables IPv4 and IPv6 forwarding on the given node.
# INPUTS
#   * node_id -- node id
#****
proc enableIPforwarding { node_id } {
    array set sysctl_ipfwd {
	net.ipv6.conf.all.forwarding	1
	net.ipv4.conf.all.forwarding	1
	net.ipv4.conf.default.rp_filter	0
	net.ipv4.conf.all.rp_filter	0
    }

    foreach {name val} [array get sysctl_ipfwd] {
	lappend cmd "sysctl $name=$val"
    }
    set cmds [join $cmd "; "]

    pipesExec "docker exec -d [getFromRunning "eid"].$node_id sh -c \'$cmds\'" "hold"
}

#****f* linux.tcl/getExtIfcs
# NAME
#   getExtIfcs -- get external interfaces
# SYNOPSIS
#   getExtIfcs
# FUNCTION
#   Returns the list of all available external interfaces except those defined
#   in the ignore loop.
# RESULT
#   * ifsc - list of interfaces
#****
proc getExtIfcs { } {
    catch { exec ls /sys/class/net } ifcs
    foreach ignore "lo* ipfw* tun*" {
        set ifcs [ lsearch -all -inline -not $ifcs $ignore ]
    }
    return "$ifcs"
}

#****f* linux.tcl/captureExtIfc
# NAME
#   captureExtIfc -- capture external interface
# SYNOPSIS
#   captureExtIfc $eid $node $iface_id
# FUNCTION
#   Captures the external interface given by the given rj45 node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#   * iface_id -- interface id
#****
proc captureExtIfc { eid node iface_id } {
    global execMode

    set ifname [getIfcName $node $iface_id]
    if { [getIfcVlanDev $node $iface_id] != "" } {
	set vlan [getIfcVlanTag $node $iface_id]
	try {
	    exec ip link set $ifname up
	    exec ip link add link $ifname name $ifname.$vlan type vlan id $vlan
	} on error err {
	    set msg "Error: VLAN $vlan on external interface $ifname can't be\
		created.\n($err)"

	    if { $execMode == "batch" } {
		puts $msg
	    } else {
		after idle {.dialog1.msg configure -wraplength 4i}
		tk_dialog .dialog1 "IMUNES error" $msg \
		    info 0 Dismiss
	    }

	    return -code error
	} on ok {} {
	    set ifname $ifname.$vlan
	}
    }

    if { [getLinkDirect [getIfcLink $node $iface_id]] } {
	return
    }

    captureExtIfcByName $eid $ifname $node
}

#****f* linux.tcl/captureExtIfcByName
# NAME
#   captureExtIfcByName -- capture external interface
# SYNOPSIS
#   captureExtIfcByName $eid $ifname
# FUNCTION
#   Captures the external interface given by the ifname.
# INPUTS
#   * eid -- experiment id
#   * ifname -- physical interface name
#****
proc captureExtIfcByName { eid ifname node } {
    set nodeNs [getNodeNetns $eid $node]

    # won't work if the node is a wireless interface
    pipesExec "ip link set $ifname netns $nodeNs" "hold"
}

#****f* linux.tcl/releaseExtIfc
# NAME
#   releaseExtIfc -- release external interface
# SYNOPSIS
#   releaseExtIfc $eid $node $iface_id
# FUNCTION
#   Releases the external interface captured by the given rj45 node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#   * iface_id -- interface id
#****
proc releaseExtIfc { eid node iface_id } {
    set ifname [getIfcName $node $iface_id]
    set nodeNs [getNodeNetns $eid $node]
    if { [getIfcVlanDev $node $iface_id] != "" } {
	set vlan [getIfcVlanTag $node $iface_id]
	set ifname $ifname.$vlan
	catch {exec ip -n $nodeNs link del $ifname}

	return
    }

    if { [getLinkDirect [getIfcLink $node $iface_id]] } {
	return
    }

    releaseExtIfcByName $eid $ifname $node
}

#****f* linux.tcl/releaseExtIfc
# NAME
#   releaseExtIfc -- release external interface
# SYNOPSIS
#   releaseExtIfc $eid $node
# FUNCTION
#   Releases the external interface with the name ifname.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc releaseExtIfcByName { eid ifname node } {
    global devfs_number

    set nodeNs [getNodeNetns $eid $node]
    pipesExec "ip -n $nodeNs link set $ifname netns imunes_$devfs_number" "hold"
}

proc getStateIfcCmd { iface_name state } {
    return "ip link set dev $iface_name $state"
}

proc getNameIfcCmd { iface_name name } {
    return "ip link set dev $iface_name name $name"
}

proc getMacIfcCmd { iface_name mac_addr } {
    return "ip link set dev $iface_name address $mac_addr"
}

proc getVlanTagIfcCmd { iface_name dev_name tag } {
    return "ip link add link $dev_name name $iface_name type vlan id $tag"
}

proc getMtuIfcCmd { iface_name mtu } {
    return "ip link set dev $iface_name mtu $mtu"
}

proc getNatIfcCmd { iface_name } {
    return "iptables -t nat -A POSTROUTING -o $iface_name -j MASQUERADE"
}

proc getIPv4RouteCmd { statrte } {
    set route [lindex $statrte 0]
    set addr [lindex $statrte 1]
    set cmd "ip route append $route via $addr"

    return $cmd
}

proc getRemoveIPv4RouteCmd { statrte } {
    set route [lindex $statrte 0]
    set addr [lindex $statrte 1]
    set cmd "ip route delete $route via $addr"

    return $cmd
}

proc getIPv6RouteCmd { statrte } {
    set route [lindex $statrte 0]
    set addr [lindex $statrte 1]
    set cmd "ip -6 route append $route via $addr"

    return $cmd
}

proc getRemoveIPv6RouteCmd { statrte } {
    set route [lindex $statrte 0]
    set addr [lindex $statrte 1]
    set cmd "ip -6 route delete $route via $addr"

    return $cmd
}

proc getIPv4IfcRouteCmd { subnet iface } {
    return "ip route add $subnet dev $iface"
}

proc getRemoveIPv4IfcRouteCmd { subnet iface } {
    return "ip route del $subnet dev $iface"
}

proc getIPv6IfcRouteCmd { subnet iface } {
    return "ip -6 route add $subnet dev $iface"
}

proc getRemoveIPv6IfcRouteCmd { subnet iface } {
    return "ip -6 route del $subnet dev $iface"
}

proc getFlushIPv4IfcCmd { iface_name } {
    return "ip -4 a flush dev $iface_name"
}

proc getFlushIPv6IfcCmd { iface_name } {
    return "ip -6 a flush dev $iface_name"
}

proc getIPv4IfcCmd { ifc addr primary } {
    return "ip addr add $addr dev $ifc"
}

proc getIPv6IfcCmd { ifc addr primary } {
    return "ip -6 addr add $addr dev $ifc"
}

proc getDelIPv4IfcCmd { ifc addr } {
    return "ip addr del $addr dev $ifc"
}

proc getDelIPv6IfcCmd { ifc addr } {
    return "ip -6 addr del $addr dev $ifc"
}

#****f* linux.tcl/fetchNodeRunningConfig
# NAME
#   fetchNodeRunningConfig -- get interfaces list from the node
# SYNOPSIS
#   fetchNodeRunningConfig $node_id
# FUNCTION
#   Returns the list of all network interfaces for the given node.
# INPUTS
#   * node_id -- node id
# RESULT
#   * list -- list in the form of {netgraph_node_name hook}
#****
proc fetchNodeRunningConfig { node_id } {
    global node_existing_mac node_existing_ipv4 node_existing_ipv6
    set node_existing_mac [getFromRunning "mac_used_list"]
    set node_existing_ipv4 [getFromRunning "ipv4_used_list"]
    set node_existing_ipv6 [getFromRunning "ipv6_used_list"]

    # overwrite any unsaved changes to this node
    set node_cfg [cfgGet "nodes" $node_id]

    set ifaces_names "[logIfaceNames $node_id] [ifaceNames $node_id]"
    puts "IFACES_NAMES: '$ifaces_names'"

    catch { exec docker exec [getFromRunning "eid"].$node_id sh -c "ip --json a" } json
    foreach elem [json::json2dict $json] {
	puts "================================================"
	puts "ELEM: '$elem'"
	set iface_name [dictGet $elem "ifname"]
	puts "NAME? '$iface_name'"
	if { $iface_name ni $ifaces_names } {
	    puts "not our iface"
	    puts "================================================"
	    continue
	}

	set iface_id [ifaceIdFromName $node_id $iface_name]
	puts "IFACE: '$iface_id'"

	if { "UP" in [dictGet $elem "flags"] } {
	    set oper_state ""
	} else {
	    set oper_state "down"
	}
	set node_cfg [_setIfcOperState $node_cfg $iface_id $oper_state]

	set link_type [dictGet $elem "link_type"]
	if { $link_type != "loopback" } {
	    set old_mac [_getIfcMACaddr $node_cfg $iface_id]
	    set new_mac [dictGet $elem "address"]

	    if { $old_mac != $new_mac } {
		set node_existing_mac [removeFromList $node_existing_mac $old_mac 1]
		lappend node_existing_mac $new_mac

		set node_cfg [_setIfcMACaddr $node_cfg $iface_id $new_mac]
	    }
	}

	set mtu [dictGet $elem "mtu"]
	if { $mtu != "" && [_getIfcMTU $node_cfg $iface_id] != $mtu} {
	    set node_cfg [_setIfcMTU $node_cfg $iface_id $mtu]
	}

	set ipv4_addrs {}
	set ipv6_addrs {}
	foreach addr_cfg [dictGet $elem "addr_info"] {
	    set family [dictGet $addr_cfg "family"]
	    set addr [dictGet $addr_cfg "local"]
	    set mask [dictGet $addr_cfg "prefixlen"]
	    if { $family == "inet" } {
		lappend ipv4_addrs "$addr/$mask"
	    } elseif { $family == "inet6" && [dictGet $addr_cfg "scope"] in "global host" } {
		lappend ipv6_addrs "$addr/$mask"
	    }
	}

	set old_ipv4_addrs [lsort [_getIfcIPv4addrs $node_cfg $iface_id]]
	set new_ipv4_addrs [lsort $ipv4_addrs]
	if { $old_ipv4_addrs != $new_ipv4_addrs } {
	    set node_existing_ipv4 [removeFromList $node_existing_ipv4 $old_ipv4_addrs 1]
	    lappend node_existing_ipv4 {*}$new_ipv4_addrs

	    setToRunning "${node_id}|${iface_id}_old_ipv4_addrs" $ipv4_addrs
	    set node_cfg [_setIfcIPv4addrs $node_cfg $iface_id $ipv4_addrs]
	}

	set old_ipv6_addrs [lsort [_getIfcIPv6addrs $node_cfg $iface_id]]
	set new_ipv6_addrs [lsort $ipv6_addrs]
	if { $old_ipv6_addrs != $new_ipv6_addrs } {
	    set node_existing_ipv6 [removeFromList $node_existing_ipv6 $old_ipv6_addrs 1]
	    lappend node_existing_ipv6 {*}$new_ipv6_addrs

	    setToRunning "${node_id}|${iface_id}_old_ipv6_addrs" $ipv6_addrs
	    set node_cfg [_setIfcIPv6addrs $node_cfg $iface_id $ipv6_addrs]
	}
    }

    puts "#####################################################################################"
    lassign [getDefaultGateways $node_id {} {}] my_gws {} {}
    lassign [getDefaultRoutesConfig $node_id $my_gws] default_routes4 default_routes6
    puts "default_routes4 '$default_routes4'"
    puts "default_routes6 '$default_routes6'"

    set croutes4 {}
    set croutes6 {}

    catch { exec docker exec [getFromRunning "eid"].$node_id sh -c "ip -4 --json r" } json
    foreach elem [json::json2dict $json] {
	puts "================================================"
	puts "ELEM: '$elem'"
	if { [dictGet $elem "scope"] in "link" } {
	    puts "link route"
	    puts "================================================"
	    continue
	}

	set dst [dictGet $elem "dst"]
	if { $dst == "default" } {
	    set dst "0.0.0.0/0"
	} elseif { [string first "/" $dst] == -1 } {
	    set dst "$dst/32"
	}
	set gateway [dictGet $elem "gateway"]

	set new_route "$dst $gateway"
	if { $new_route in $default_routes4 } {
	    puts "auto route, skipping"
	    puts "================================================"
	    continue
	}

	lappend croutes4 $new_route
    }

    puts "croutes4: '$croutes4'"
    set old_croutes4 [lsort [_getStatIPv4routes $node_cfg]]
    set new_croutes4 [lsort $croutes4]
    if { $old_croutes4 != $new_croutes4 } {
	setToRunning "${node_id}_old_croutes4" $new_croutes4
	set node_cfg [_setStatIPv4routes $node_cfg $new_croutes4]
    }

    catch { exec docker exec [getFromRunning "eid"].$node_id sh -c "ip -6 --json r" } json
    foreach elem [json::json2dict $json] {
	puts "================================================"
	puts "ELEM: '$elem'"
	if { [dictGet $elem "nexthops"] == "" && [dictGet $elem "gateway"] == "" } {
	    puts "link route"
	    puts "================================================"
	    continue
	}

	set dst [dictGet $elem "dst"]
	if { $dst == "default" } {
	    set dst "::/0"
	} elseif { [string first "/" $dst] == -1 } {
	    set dst "$dst/128"
	}
	set gateway [dictGet $elem "gateway"]

	if { $gateway != "" } {
	    set new_route "$dst $gateway"
	    if { $new_route in $default_routes6 } {
		puts "auto route, skipping"
		puts "================================================"
		continue
	    }

	    lappend croutes6 $new_route
	} else {
	    foreach nexthop_elem [dictGet $elem "nexthops"] {
		set gateway [dictGet $nexthop_elem "gateway"]
		set new_route "$dst $gateway"
		if { $new_route in $default_routes6 } {
		    puts "auto route, skipping"
		    puts "================================================"
		    continue
		}
	    }
	}
    }

    puts "croutes6: '$croutes6'"
    set old_croutes6 [lsort [_getStatIPv6routes $node_cfg]]
    set new_croutes6 [lsort $croutes6]
    if { $old_croutes6 != $new_croutes6 } {
	setToRunning "${node_id}_old_croutes6" $new_croutes6
	set node_cfg [_setStatIPv6routes $node_cfg $new_croutes6]
    }

    # don't trigger anything new - save variables state
    prepareInstantiateVars
    prepareTerminateVars

    updateNode $node_id "*" $node_cfg

    # don't trigger anything new - restore variables state
    updateInstantiateVars
    updateTerminateVars

    if { $node_existing_mac != [getFromRunning "mac_used_list"] } {
	setToRunning "mac_used_list" $node_existing_mac
    }

    if { $node_existing_ipv4 != [getFromRunning "ipv4_used_list"] } {
	setToRunning "ipv4_used_list" $node_existing_ipv4
    }

    if { $node_existing_ipv6 != [getFromRunning "ipv6_used_list"] } {
	setToRunning "ipv6_used_list" $node_existing_ipv6
    }

    return $node_cfg
}

proc checkSysPrerequisites {} {
    set msg ""
    if { [catch { exec docker ps }] } {
        set msg "Cannot start experiment. Is docker installed and running (check the output of 'docker ps')?"
    }

    return $msg
}

#****f* linux.tcl/execSetIfcQDisc
# NAME
#   execSetIfcQDisc -- in exec mode set interface queuing discipline
# SYNOPSIS
#   execSetIfcQDisc $eid $node_id $iface $qdisc
# FUNCTION
#   Sets the queuing discipline during the simulation.
#   New queuing discipline is defined in qdisc parameter.
#   Queueing discipline can be set to fifo, wfq or drr.
# INPUTS
#   eid -- experiment id
#   node_id -- node id
#   iface -- interface name
#   qdisc -- queuing discipline
#****
proc execSetIfcQDisc { eid node_id iface qdisc } {
    switch -exact $qdisc {
        FIFO { set qdisc fifo_fast }
        WFQ { set qdisc sfq }
        DRR { set qdisc drr }
    }

    pipesExec "ip netns exec $eid-$node_id tc qdisc add dev $iface root $qdisc" "hold"
}

#****f* linux.tcl/execSetIfcQLen
# NAME
#   execSetIfcQLen -- in exec mode set interface TX queue length
# SYNOPSIS
#   execSetIfcQLen $eid $node $ifc $qlen
# FUNCTION
#   Sets the queue length during the simulation.
#   New queue length is defined in qlen parameter.
# INPUTS
#   eid -- experiment id
#   node -- node id
#   ifc -- interface name
#   qlen -- new queue's length
#****
proc execSetIfcQLen { eid node ifc qlen } {
    pipesExec "ip -n $eid-$node l set $ifc txqueuelen $qlen" "hold"
}

proc getNetemConfigLine { bandwidth delay loss dup } {
    array set netem {
	bandwidth	"rate Xbit"
	loss		"loss random X%"
	delay		"delay Xus"
	dup		"duplicate X%"
    }
    set cmd ""

    foreach { val ctemplate } [array get netem] {
	if { [set $val] != 0 } {
	    set confline "[lindex [split $ctemplate "X"] 0][set $val][lindex [split $ctemplate "X"] 1]"
	    append cmd " $confline"
	}
    }

    return $cmd
}

proc configureIfcLinkParams { eid node iface_id bandwidth delay ber loss dup } {
    set devname [getIfcName $node $iface_id]

    if { [getNodeType $node] != "rj45" } {
	set devname $node-$devname
    }

    set netem_cfg [getNetemConfigLine $bandwidth $delay $loss $dup]

    pipesExec "ip netns exec $eid tc qdisc del dev $devname root" "hold"
    pipesExec "ip netns exec $eid tc qdisc add dev $devname root netem $netem_cfg" "hold"

    # XXX: Now on Linux we don't care about queue lengths and we don't limit
    # maximum data and burst size.
    # in the future we can use something like this: (based on the qlen
    # parameter)
    # set confstring "tbf rate ${bandwidth}bit limit 10mb burst 1540"
}

#****f* linux.tcl/execSetLinkParams
# NAME
#   execSetLinkParams -- in exec mode set link parameters
# SYNOPSIS
#   execSetLinkParams $eid $link
# FUNCTION
#   Sets the link parameters during the simulation.
#   All the parameters are set at the same time.
# INPUTS
#   eid -- experiment id
#   link -- link id
#****
proc execSetLinkParams { eid link } {
    lassign [getLinkPeers $link] lnode1 lnode2
    lassign [getLinkPeersIfaces $link] iface1_id iface2_id

    set mirror_link [getLinkMirror $link]
    if { $mirror_link != "" } {
	if { [getNodeType $lnode1] == "pseudo" } {
	    set lnode1 [lindex [getLinkPeers $mirror_link] 1]
	    set iface1_id [lindex [getLinkPeersIfaces $mirror_link] 1]
	} else {
	    set lnode2 [lindex [getLinkPeers $mirror_link] 1]
	    set iface2_id [lindex [getLinkPeersIfaces $mirror_link] 1]
	}
    }

    set bandwidth [expr [getLinkBandwidth $link] + 0]
    set delay [expr [getLinkDelay $link] + 0]
    set ber [expr [getLinkBER $link] + 0]
    set loss [expr [getLinkLoss $link] + 0]
    set dup [expr [getLinkDup $link] + 0]

    pipesCreate
    configureIfcLinkParams $eid $lnode1 $iface1_id $bandwidth $delay $ber $loss $dup
    configureIfcLinkParams $eid $lnode2 $iface2_id $bandwidth $delay $ber $loss $dup
    pipesClose
}

proc ipsecFilesToNode { node local_cert ipsecret_file } {
    global ipsecConf ipsecSecrets

    if { $local_cert != "" } {
	set trimmed_local_cert [lindex [split $local_cert /] end]

	set fileId [open $trimmed_local_cert "r"]
	set trimmed_local_cert_data [read $fileId]
	close $fileId

	writeDataToNodeFile $node /etc/ipsec.d/certs/$trimmed_local_cert $trimmed_local_cert_data
    }

    if { $ipsecret_file != "" } {
	set trimmed_local_key [lindex [split $ipsecret_file /] end]

	set fileId [open $trimmed_local_key "r"]
	set trimmed_local_key_data "# /etc/ipsec.secrets - strongSwan IPsec secrets file\n"
	set trimmed_local_key_data "$trimmed_local_key_data[read $fileId]\n"
	set trimmed_local_key_data "$trimmed_local_key_data: RSA $trimmed_local_key"
	close $fileId

	writeDataToNodeFile $node /etc/ipsec.d/private/$trimmed_local_key $trimmed_local_key_data
    }

    writeDataToNodeFile $node /etc/ipsec.conf $ipsecConf
    writeDataToNodeFile $node /etc/ipsec.secrets $ipsecSecrets
}

proc sshServiceStartCmds {} {
    lappend cmds "dpkg-reconfigure openssh-server"
    lappend cmds "service ssh start"

    return $cmds
}

proc sshServiceStopCmds {} {
    return {"service ssh stop"}
}

proc inetdServiceRestartCmds {} {
    return "service openbsd-inetd restart"
}

proc moveFileFromNode { node path ext_path } {
    set eid [getFromRunning "eid"]

    catch { exec hcp [getNodeName $node]@$eid:$path $ext_path }
    catch { exec docker exec $eid.$node rm -fr $path }
}

# XXX nat64 procedures
proc configureTunIface { tayga4pool tayga6prefix } {
    set tun_dev "tun64"

    set cfg {}
    lappend cfg "[getStateIfcCmd "$tun_dev" "up"]"

    return $cfg
}

proc configureExternalConnection { eid node } {
    set cmds ""
    set ifc [lindex [ifcList $node] 0]
    set outifc "$eid-$node"

    set ether [getIfcMACaddr $node $ifc]
    if { $ether == "" } {
	autoMACaddr $node $ifc
	set ether [getIfcMACaddr $node $ifc]
    }
    set cmds "ip l set $outifc address $ether"

    set cmds "$cmds\n ip a flush dev $outifc"

    foreach ipv4 [getIfcIPv4addrs $node $ifc] {
	set cmds "$cmds\n ip a add $ipv4 dev $outifc"
    }

    foreach ipv6 [getIfcIPv6addrs $node $ifc] {
	set cmds "$cmds\n ip a add $ipv6 dev $outifc"
    }

    set cmds "$cmds\n ip l set $outifc up"

    pipesExec "$cmds" "hold"
}

proc unconfigureExternalConnection { eid node } {
    set cmds ""
    set ifc [lindex [ifcList $node] 0]
    set outifc "$eid-$node"

    set cmds "ip a flush dev $outifc"
    set cmds "$cmds\n ip -6 a flush dev $outifc"

    pipesExec "$cmds" "hold"
}

proc stopExternalConnection { eid node } {
    pipesExec "ip link set $eid-$node down" "hold"
}

proc setupExtNat { eid node ifc } {
    set extIfc [getNodeName $node]
    if { $extIfc == "UNASSIGNED" } {
	return
    }

    set extIp [getIfcIPv4addrs $node $ifc]
    set prefixLen [lindex [split $extIp "/"] 1]
    set subnet "[ip::prefix $extIp]/$prefixLen"

    set cmds "iptables -t nat -A POSTROUTING -o $extIfc -j MASQUERADE -s $subnet"
    set cmds "$cmds\n iptables -A FORWARD -i $eid-$node -o $extIfc -j ACCEPT"
    set cmds "$cmds\n iptables -A FORWARD -o $eid-$node -j ACCEPT"

    pipesExec "$cmds" "hold"
}

proc unsetupExtNat { eid node ifc } {
    set extIfc [getNodeName $node]
    if { $extIfc == "UNASSIGNED" } {
	return
    }

    set extIp [getIfcIPv4addrs $node $ifc]
    set prefixLen [lindex [split $extIp "/"] 1]
    set subnet "[ip::prefix $extIp]/$prefixLen"

    set cmds "iptables -t nat -D POSTROUTING -o $extIfc -j MASQUERADE -s $subnet"
    set cmds "$cmds\n iptables -D FORWARD -i $eid-$node -o $extIfc -j ACCEPT"
    set cmds "$cmds\n iptables -D FORWARD -o $eid-$node -j ACCEPT"

    pipesExec "$cmds" "hold"
}

proc startRoutingDaemons { node_id } {
    set run_dir "/run/frr"
    set cmds "mkdir -p $run_dir ; chown frr:frr $run_dir"

    set conf_dir "/etc/frr"

    foreach protocol { rip ripng ospf ospf6 } {
	if { [getNodeProtocol $node_id $protocol] != 1 } {
	    continue
	}

	set cmds "$cmds; sed -i'' \"s/${protocol}d=no/${protocol}d=yes/\" $conf_dir/daemons"
    }

    foreach protocol { ldp bfd } {
	if { [getNodeProtocol $node_id $protocol] != 1 } {
	    continue
	}

	set cmds "$cmds; sed -i'' \"s/${protocol}d=no/${protocol}d=yes/\" $conf_dir/daemons"
    }

    foreach protocol { bgp isis } {
	if { [getNodeProtocol $node_id $protocol] != 1 } {
	    continue
	}

	set cmds "$cmds; sed -i'' \"s/${protocol}d=no/${protocol}d=yes/\" $conf_dir/daemons"
    }

    set init_file "/etc/init.d/frr"
    set cmds "$cmds; if \[ -f $init_file \]; then $init_file restart ; fi"

    pipesExec "docker exec -d [getFromRunning "eid"].$node_id sh -c '$cmds'" "hold"
}
