#
# Copyright 2004-2013 University of Zagreb.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# This work was supported in part by the Croatian Ministry of Science
# and Technology through the research contract #IP-2003-143.
#

#****f* exec.tcl/genExperimentId
# NAME
#   genExperimentId -- generate experiment ID
# SYNOPSIS
#   set eid [genExperimentId]
# FUNCTION
#   Generates a new random experiment ID that will be used when the experiment
#   is started.
# RESULT
#   * eid -- a new generated experiment ID
#****
proc genExperimentId { } {
    global isOSlinux

    if { $isOSlinux } {
        return i[string range [format %04x [expr {[pid] + [expr { round( rand()*10000 ) }]}]] 0 2]
    } else {
        return i[format %04x [expr {[pid] + [expr { round( rand()*10000 ) }]}]]
    }
}

#****f* exec.tcl/checkExternalInterfaces
# NAME
#   checkExternalInterfaces -- check external interfaces in the topology
# SYNOPSIS
#   checkExternalInterfaces
# FUNCTION
#   Check whether external interfaces are available in the running system.
# RESULT
#   * returns 0 if everything is ok, otherwise it returns 1.
#****
proc checkExternalInterfaces {} {
    global execMode isOSlinux

    set extifcs [getHostIfcList]

    set nodes_ifcpairs {}
    foreach node [getFromRunning "node_list"] {
	if { [getNodeType $node] == "rj45" } {
	    lappend nodes_ifcpairs [list $node [list 0 [getNodeName $node]]]
	} elseif { [getNodeType $node] == "extelem" } {
	    foreach ifcs [getNodeStolenIfaces $node] {
		lappend nodes_ifcpairs [list $node $ifcs]
	    }
	}
    }

    foreach node_ifcpair $nodes_ifcpairs {
	lassign $node_ifcpair node ifcpair
	lassign $ifcpair iface physical_ifc

	# check if the interface exists
	set i [lsearch $extifcs $physical_ifc]
	if { $i < 0 } {
	    set msg "Error: external interface $physical_ifc non-existant."
	    if { $execMode == "batch" } {
		puts $msg
	    } else {
		after idle {.dialog1.msg configure -wraplength 4i}
		tk_dialog .dialog1 "IMUNES error" $msg \
		    info 0 Dismiss
	    }

	    return 1
	}

	if { [getEtherVlanEnabled $node] && [getEtherVlanTag $node] != "" } {
	    if { [getHostIfcVlanExists $node $physical_ifc] } {
		return 1
	    }
	} elseif { $isOSlinux } {
	    try {
		exec test -d /sys/class/net/$physical_ifc/wireless
	    } on error {} {
	    } on ok {} {
		if { [getLinkDirect [getIfcLink $node $iface]] } {
		    set severity "warning"
		    set msg "Interface '$physical_ifc' is a wireless interface,\
			so its peer cannot change its MAC address!"
		} else {
		    set severity "error"
		    set msg "Cannot bridge wireless interface '$physical_ifc',\
			use 'Direct link' to connect to this interface!"
		}

		if { $execMode == "batch" } {
		    puts $msg
		} else {
		    after idle {.dialog1.msg configure -wraplength 4i}
		    tk_dialog .dialog1 "IMUNES $severity" "$msg" \
			info 0 Dismiss
		}

		if { $severity == "error" } {
		    return 1
		}
	    }
	}
    }

    return 0
}

#****f* exec.tcl/execCmdsNode
# NAME
#   execCmdsNode -- execute a set of commands on virtual node
# SYNOPSIS
#   execCmdsNode $node $cmds
# FUNCTION
#   Executes commands on a virtual node and returns the output.
# INPUTS
#   * node -- virtual node id
#   * cmds -- list of commands to execute
# RESULT
#   * returns the execution output
#****
proc execCmdsNode { node cmds } {
    set output ""
    foreach cmd $cmds {
        set result [execCmdNode $node $cmd]
	append output "\n" $result
    }
    return $output
}

#****f* exec.tcl/createExperimentFiles
# NAME
#   createExperimentFiles -- create experiment files
# SYNOPSIS
#   createExperimentFiles $eid
# FUNCTION
#   Creates all needed files to run the specified experiment.
# INPUTS
#   * eid -- experiment id
#****
proc createExperimentFiles { eid } {
    global currentFileBatch execMode runtimeDir

    set current_file [getFromRunning "current_file"]
    set basedir "$runtimeDir/$eid"
    file mkdir $basedir

    writeDataToFile $basedir/timestamp [clock format [clock seconds]]

    dumpLinksToFile $basedir/links

    if { $execMode == "interactive" } {
	if { $current_file != "" } {
	    writeDataToFile $basedir/name [file tail $current_file]
	}
    } else {
	if { $currentFileBatch != "" } {
	    writeDataToFile $basedir/name [file tail $currentFileBatch]
	}
    }

    if { $execMode == "interactive" } {
	saveRunningConfigurationInteractive $eid
	createExperimentScreenshot $eid
    } else {
	saveRunningConfigurationBatch $eid
    }
}

#****f* exec.tcl/saveRunningConfigurationInteractive
# NAME
#   saveRunningConfigurationInteractive -- save running configuration in
#       interactive
# SYNOPSIS
#   saveRunningConfigurationInteractive $eid
# FUNCTION
#   Saves running configuration of the specified experiment if running in
#   interactive mode.
# INPUTS
#   * eid -- experiment id
#****
proc saveRunningConfigurationInteractive { eid } {
    global runtimeDir

    set fileName "$runtimeDir/$eid/config.imn"
    saveCfgJson $fileName
}

#****f* exec.tcl/saveRunningConfigurationBatch
# NAME
#   saveRunningConfigurationBatch -- save running configuration in batch
# SYNOPSIS
#   saveRunningConfigurationBatch $eid
# FUNCTION
#   Saves running configuration of the specified experiment if running in
#   batch mode.
# INPUTS
#   * eid -- experiment id
#****
proc saveRunningConfigurationBatch { eid } {
    global currentFileBatch runtimeDir

    set fileName "$runtimeDir/$eid/config.imn"
    exec cp $currentFileBatch $fileName
}

#****f* exec.tcl/createExperimentScreenshot
# NAME
#   createExperimentScreenshot -- create experiment screenshot
# SYNOPSIS
#   createExperimentScreenshot $eid
# FUNCTION
#   Creates a screenshot for the specified experiment and saves it as an image #   in png format.
# INPUTS
#   * eid -- experiment id
#****
proc createExperimentScreenshot { eid } {
    global runtimeDir

    set fileName "$runtimeDir/$eid/screenshot.png"
    set error [catch { eval image create photo screenshot -format window \
	-data .panwin.f1.c } err]
    if { $error == 0 } {
	screenshot write $fileName -format png

	catch { exec magick $fileName -resize 300x210\! $fileName\2 }
	catch {  exec mv $fileName\2 $fileName }
    }
}

#****f* exec.tcl/createExperimentFilesFromBatch
# NAME
#   createExperimentFilesFromBatch -- create experiment files from batch
# SYNOPSIS
#   createExperimentFilesFromBatch
# FUNCTION
#   Creates all needed files to run the experiments in batch mode.
#****
proc createExperimentFilesFromBatch {} {
    createExperimentFiles [getFromRunning "eid"]
}

#****f* freebsd.tcl/l3node.nghook
# NAME
#   l3node.nghook -- layer 3 node netgraph hook
# SYNOPSIS
#   l3node.nghook $eid $node $ifc
# FUNCTION
#   Returns the netgraph node name and the hook name for a given experiment
#   id, node id, and interface name.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#   * ifc -- interface name
# RESULT
#   * list -- list in the form of {netgraph_node_name hook}
#****
proc l3node.nghook { eid node ifc } {
    switch -exact [string trim $ifc 0123456789] {
	wlan -
	ext -
	eth {
	    return [list $node-$ifc ether]
	}
    }
}

#****f* exec.tcl/nodeIpsecInit
# NAME
#   nodeIpsecInit -- IPsec initialization
# SYNOPSIS
#   nodeIpsecInit $node
# FUNCTION
#   Creates ipsec.conf and ipsec.secrets files from IPsec configuration of given node
#   and copies certificates to desired folders (if there are any certificates)
# INPUTS
#   * node -- node id
#****
global ipsecConf ipsecSecrets
set ipsecConf ""
set ipsecSecrets ""
proc nodeIpsecInit { node } {
    global ipsecConf ipsecSecrets isOSfreebsd

    if { [getNodeIPsec $node] == "" } {
	return
    }

    setNodeIPsecSetting $node "%default" "keyexchange" "ikev2"
    set ipsecConf "# /etc/ipsec.conf - strongSwan IPsec configuration file\n"
    set ipsecConf "${ipsecConf}config setup\n"

    foreach {config_name config} [getNodeIPsecItem $node "ipsec_configs"] {
	set ipsecConf "${ipsecConf}conn $config_name\n"
	set hasKey 0
	set hasRight 0
	foreach {setting value} $config {
	    if { $setting == "peersname" } {
		continue
	    }

	    if { $setting == "sharedkey" } {
		set hasKey 1
		set psk_key $value
		continue
	    }

	    if { $setting == "right" } {
		set hasRight 1
		set right $value
	    }

	    set ipsecConf "$ipsecConf        $setting=$value\n"
	}

	if { $hasKey && $hasRight } {
	    set ipsecSecrets "$right : PSK $psk_key"
	}
    }

    delNodeIPsecConnection $node "%default"

    set local_cert [getNodeIPsecItem $node "local_cert"]
    set ipsecret_file [getNodeIPsecItem $node "local_key_file"]
    ipsecFilesToNode $node $local_cert $ipsecret_file

    set ipsec_log_level [getNodeIPsecItem $node "ipsec_logging"]
    if { $ipsec_log_level != "" } {
	execCmdNode $node "touch /tmp/charon.log"

	set charon "charon {\n\
	\tfilelog {\n\
	\t\tcharon {\n\
	\t\t\tpath = /tmp/charon.log\n\
	\t\t\tappend = yes\n\
	\t\t\tflush_line = yes\n\
	\t\t\tdefault = $ipsec_log_level\n\
	\t\t}\n\
	\t}\n\
	}"

	set prefix ""
	if { $isOSfreebsd } {
	    set prefix "/usr/local"
	}

	writeDataToNodeFile $node "$prefix/etc/strongswan.d/charon-logging.conf" $charon
    }
}

#****f* exec.tcl/deployCfg
# NAME
#   deployCfg -- deploy working configuration
# SYNOPSIS
#   deployCfg
# FUNCTION
#   Deploys a current working configuration. It creates all the nodes and link
#   as defined in configuration file of in GUI of imunes. Before deploying new
#   configuration the old one is removed (vimageCleanup procedure).
#****
proc deployCfg {} {
    global progressbarCount execMode

    prepareInstantiateVars "force"

    if { "$instantiate_nodes$create_nodes_ifaces$instantiate_links$configure_links$configure_nodes_ifaces$configure_nodes" == "" } {
	return
    }

    set progressbarCount 0
    set nodeCount [llength $instantiate_nodes]
    set linkCount [llength $instantiate_links]

    set t_start [clock milliseconds]

    try {
	execute_prepareSystem
    } on error err {
	statline "ERROR in 'execute_prepareSystem': '$err'"
	if { $execMode != "batch" } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES error" \
		"$err \nTerminate the experiment and report the bug!" info 0 Dismiss
	}

	return
    }

    statline "Preparing for initialization..."
    set l2nodes {}
    set l3nodes {}
    set allNodes {}
    set pseudoNodesCount 0
    foreach node_id $instantiate_nodes {
	set node_type [getNodeType $node_id]
	if { $node_type != "pseudo" } {
	    if { [$node_type.virtlayer] != "VIRTUALIZED" } {
		lappend l2nodes $node_id
	    } else {
		lappend l3nodes $node_id
	    }
	} else {
	    incr pseudoNodesCount
	}
    }

    set l2nodeCount [llength $l2nodes]
    set l3nodeCount [llength $l3nodes]
    set allNodes [concat $l2nodes $l3nodes]
    set allNodeCount [llength $allNodes]

    if { $create_nodes_ifaces == "*" } {
	set create_nodes_ifaces ""
	foreach node_id $allNodes {
	    dict set create_nodes_ifaces $node_id "*"
	}
	set create_nodes_ifaces_count $allNodeCount
    } else {
	set create_nodes_ifaces_count [llength [dict keys $create_nodes_ifaces]]
    }

    if { $configure_nodes_ifaces == "*" } {
	set configure_nodes_ifaces ""
	foreach node_id $allNodes {
	    dict set configure_nodes_ifaces $node_id "*"
	}
	set configure_nodes_ifaces_count $allNodeCount
    } else {
	set configure_nodes_ifaces_count [llength [dict keys $configure_nodes_ifaces]]
    }

    if { $configure_nodes == "*" } {
	set configure_nodes $allNodes
    }
    set configure_nodes_count [llength $configure_nodes]

    incr linkCount [expr -$pseudoNodesCount/2]
    set maxProgressbasCount [expr {5*$allNodeCount + 1*$l2nodeCount + 5*$l3nodeCount + 2*$linkCount + $configure_nodes_count + $create_nodes_ifaces_count + $configure_nodes_ifaces_count}]

    set w ""
    set eid [getFromRunning "eid"]
    if { $execMode != "batch" } {
	set w .startup
	catch { destroy $w }
	toplevel $w -takefocus 1
	wm transient $w .
	wm title $w "Starting experiment $eid..."

	message $w.msg -justify left -aspect 1200 \
	    -text "Starting up virtual nodes and links."

	pack $w.msg
	update

	ttk::progressbar $w.p -orient horizontal -length 250 \
	    -mode determinate -maximum $maxProgressbasCount -value $progressbarCount
	pack $w.p
	update

	grab $w
	wm protocol $w WM_DELETE_WINDOW {
	}
    }

    try {
	statline "Instantiating L3 nodes..."
	pipesCreate
	execute_nodesCreate $l3nodes $l3nodeCount $w
	statline "Waiting for $l3nodeCount L3 node(s) to start..."
	waitForInstantiateNodes $l3nodes $l3nodeCount $w
	pipesClose

	statline "Setting up namespaces for all nodes..."
	pipesCreate
	execute_nodesSetupNamespaces $allNodes $allNodeCount $w
	statline "Waiting on namespaces for $allNodeCount node(s)..."
	waitForNamespaces $allNodes $allNodeCount $w
	pipesClose

	statline "Starting initial configuration on L3 nodes..."
	pipesCreate
	execute_nodesInitConfigure $l3nodes $l3nodeCount $w
	statline "Waiting for initial configuration on $l3nodeCount L3 node(s)..."
	waitForInitConf $l3nodes $l3nodeCount $w
	pipesClose

	statline "Instantiating L2 nodes..."
	pipesCreate
	execute_nodesCreate $l2nodes $l2nodeCount $w
	statline "Waiting for $l2nodeCount L2 node(s) to start..."
	pipesClose

	#statline "Copying host files to $l3nodeCount L3 node(s)..."
	#execute_nodesCopyFiles $l3nodes $l3nodeCount $w

	statline "Starting services for NODEINST hook..."
	services start "NODEINST"

	statline "Creating physical interfaces on nodes..."
	pipesCreate
	execute_nodesPhysIfacesCreate $create_nodes_ifaces $create_nodes_ifaces_count $w
	statline "Waiting for physical interfaces on $create_nodes_ifaces_count node(s) to be created..."
	pipesClose

	statline "Creating logical interfaces on nodes..."
	pipesCreate
	execute_nodesLogIfacesCreate $create_nodes_ifaces $create_nodes_ifaces_count $w
	statline "Waiting for logical on $create_nodes_ifaces_count node(s) to be created..."
	pipesClose

	statline "Creating links..."
	pipesCreate
	execute_linksCreate $instantiate_links $linkCount $w
	statline "Waiting for $linkCount link(s) to be created..."
	pipesClose

	pipesCreate
	statline "Configuring links..."
	execute_linksConfigure $instantiate_links $linkCount $w
	statline "Waiting for $linkCount link(s) to be configured..."
	pipesClose

	statline "Starting services for LINKINST hook..."
	services start "LINKINST"

	pipesCreate
	statline "Configuring interfaces on node(s)..."
	execute_nodesIfacesConfigure $configure_nodes_ifaces $configure_nodes_ifaces_count $w
	statline "Waiting for interface configuration on $configure_nodes_ifaces_count node(s)..."
	#configureIfacesWait $configure_nodes_ifaces $configure_nodes_ifaces_count $w
	pipesClose

	pipesCreate
	statline "Configuring node(s)..."
	execute_nodesConfigure $configure_nodes $configure_nodes_count $w
	statline "Waiting for configuration on $configure_nodes_count node(s)..."
	waitForConfStart $configure_nodes $configure_nodes_count $w
	pipesClose

	statline "Starting services for NODECONF hook..."
	services start "NODECONF"
    } on error err {
	finishExecuting 0 "$err" $w

	return
    }

    if { $configure_nodes_ifaces != "" } {
	set error_check_nodes [lsort -unique [dict keys $configure_nodes_ifaces]]
	set error_check_nodes_count [llength $error_check_nodes]
	statline "Checking for errors on $error_check_nodes_count node(s) interfaces..."
	checkForErrorsIfaces $error_check_nodes $error_check_nodes_count $w
    }

    set error_check_nodes [lsort -unique $configure_nodes]
    set error_check_nodes_count [llength $error_check_nodes]
    statline "Checking for errors on $error_check_nodes_count node(s)..."
    checkForErrors $error_check_nodes $error_check_nodes_count $w

    finishExecuting 1 "" $w

    statline "Network topology instantiated in [expr ([clock milliseconds] - $t_start)/1000.0] seconds ($allNodeCount nodes and $linkCount links)."

    if { $execMode == "batch" } {
	puts "Experiment ID = $eid"
    }
}

proc execute_prepareSystem {} {
    global eid_base
    global execMode

    if { [getFromRunning "cfg_deployed"] } {
	return
    }

    set running_eids [getResumableExperiments]
    if { $execMode != "batch" } {
	set eid ${eid_base}[string range $::curcfg 1 end]
	while { $eid in $running_eids } {
	    set eid_base [genExperimentId]
	    set eid ${eid_base}[string range $::curcfg 1 end]
	}
    } else {
	set eid $eid_base
	while { $eid in $running_eids } {
	    puts -nonewline "Experiment ID $eid_base already in use, trying "
	    set eid [genExperimentId]
	    puts "$eid."
	}
    }

    setToRunning "eid" $eid

    loadKernelModules
    prepareVirtualFS
    prepareDevfs
    createExperimentContainer
    createExperimentFiles $eid
}

proc execute_nodesCreate { nodes nodeCount w } {
    global progressbarCount execMode

    set eid [getFromRunning "eid"]

    set batchStep 0
    foreach node_id $nodes {
	displayBatchProgress $batchStep $nodeCount

	if { [info procs [getNodeType $node_id].nodeCreate] != "" } {
	    try {
		[getNodeType $node_id].nodeCreate $eid $node_id
		setToRunning "${node_id}_running" true
	    } on error err {
		return -code error "Error in '[getNodeType $node_id].nodeCreate $eid $node_id': $err"
	    }
	    pipesExec ""
	}

	incr batchStep
	incr progressbarCount

	if { $execMode != "batch" } {
	    statline "Instantiating node [getNodeName $node_id]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc waitForInstantiateNodes { nodes nodeCount w } {
    global progressbarCount execMode

    set batchStep 0
    set nodes_left $nodes
    while { [llength $nodes_left] > 0 } {
	displayBatchProgress $batchStep $nodeCount
	foreach node $nodes_left {
	    if { ! [isNodeStarted $node] } {
		continue
	    }

	    incr batchStep
	    incr progressbarCount

	    set name [getNodeName $node]
	    if { $execMode != "batch" } {
		statline "Node $name started"
		$w.p configure -value $progressbarCount
		update
	    }
	    displayBatchProgress $batchStep $nodeCount

	    set nodes_left [removeFromList $nodes_left $node]
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc execute_nodesSetupNamespaces { nodes nodeCount w } {
    global progressbarCount execMode

    set eid [getFromRunning "eid"]

    set batchStep 0
    foreach node $nodes {
	displayBatchProgress $batchStep $nodeCount

	if { [info procs [getNodeType $node].nodeSetupNamespace] != "" } {
	    try {
		[getNodeType $node].nodeSetupNamespace $eid $node
	    } on error err {
		return -code error "Error in '[getNodeType $node].nodeSetupNamespace $eid $node': $err"
	    }
	    pipesExec ""
	}

	incr batchStep
	incr progressbarCount

	if { $execMode != "batch" } {
	    statline "Creating namespace for [getNodeName $node]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc waitForNamespaces { nodes nodeCount w } {
    global progressbarCount execMode

    set batchStep 0
    set nodes_left $nodes
    while { [llength $nodes_left] > 0 } {
	displayBatchProgress $batchStep $nodeCount
	foreach node $nodes_left {
	    if { ! [isNodeNamespaceCreated $node] } {
		continue
	    }

	    incr batchStep
	    incr progressbarCount

	    set name [getNodeName $node]
	    if { $execMode != "batch" } {
		statline "Namespace for $name created"
		$w.p configure -value $progressbarCount
		update
	    }
	    displayBatchProgress $batchStep $nodeCount

	    set nodes_left [removeFromList $nodes_left $node]
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc execute_nodesInitConfigure { nodes nodeCount w } {
    global progressbarCount execMode

    set eid [getFromRunning "eid"]

    set batchStep 0
    foreach node $nodes {
	displayBatchProgress $batchStep $nodeCount

	try {
	    [getNodeType $node].nodeInitConfigure $eid $node
	} on error err {
	    return -code error "Error in '[getNodeType $node].nodeInitConfigure $eid $node': $err"
	}
	pipesExec ""

	incr batchStep
	incr progressbarCount

	if { $execMode != "batch" } {
	    statline "Starting initial configuration on [getNodeName $node]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc waitForInitConf { nodes nodeCount w } {
    global progressbarCount execMode

    set batchStep 0
    set nodes_left $nodes
    while { [llength $nodes_left] > 0 } {
	displayBatchProgress $batchStep $nodeCount
	foreach node $nodes_left {
	    if { ! [isNodeInitNet $node] } {
		continue
	    }

	    incr batchStep
	    incr progressbarCount

	    set name [getNodeName $node]
	    if { $execMode != "batch" } {
		statline "Initial networking on $name configured"
		$w.p configure -value $progressbarCount
		update
	    }
	    displayBatchProgress $batchStep $nodeCount

	    set nodes_left [removeFromList $nodes_left $node]
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc execute_nodesCopyFiles { nodes nodeCount w } {}

proc execute_nodesPhysIfacesCreate { nodes_ifaces nodeCount w } {
    global progressbarCount execMode

    set eid [getFromRunning "eid"]

    set batchStep 0
    dict for {node ifaces} $nodes_ifaces {
	displayBatchProgress $batchStep $nodeCount

	if { [info procs [getNodeType $node].nodePhysIfacesCreate] != "" } {
	    if { $ifaces == "*" } {
		set ifaces [ifcList $node]
	    }

	    try {
		[getNodeType $node].nodePhysIfacesCreate $eid $node $ifaces
	    } on error err {
		return -code error "Error in '[getNodeType $node].nodePhysIfacesCreate $eid $node $ifaces': $err"
	    }
	    pipesExec ""
	}

	incr batchStep
	incr progressbarCount

	if { $execMode != "batch" } {
	    statline "Creating physical ifaces on node [getNodeName $node]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc execute_nodesLogIfacesCreate { nodes_ifaces nodeCount w } {
    global progressbarCount execMode

    set eid [getFromRunning "eid"]

    set batchStep 0
    dict for {node ifaces} $nodes_ifaces {
	displayBatchProgress $batchStep $nodeCount

	if { [info procs [getNodeType $node].nodeLogIfacesCreate] != "" } {
	    if { $ifaces == "*" } {
		set ifaces [logIfcList $node]
	    }

	    try {
		[getNodeType $node].nodeLogIfacesCreate $eid $node $ifaces
	    } on error err {
		return -code error "Error in '[getNodeType $node].nodeLogIfacesCreate $eid $node $ifaces': $err"
	    }
	    pipesExec ""
	}

	incr batchStep
	incr progressbarCount

	if { $execMode != "batch" } {
	    statline "Creating logical ifaces on node [getNodeName $node]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc execute_linksCreate { links linkCount w } {
    global progressbarCount execMode

    set batchStep 0
    for {set pending_links $links} {$pending_links != ""} {} {
	set link_id [lindex $pending_links 0]
	set msg "Creating link $link_id"
	set pending_links [removeFromList $pending_links $link_id]

	lassign [getLinkPeers $link_id] lnode1 lnode2
	lassign [getLinkPeersIfaces $link_id] ifname1 ifname2

	set mirror_link [getLinkMirror $link_id]
	if { $mirror_link != "" } {
	    set msg "Creating link $link_id/$mirror_link"
	    set pending_links [removeFromList $pending_links $mirror_link]

	    # switch direction for mirror links
	    lassign "$lnode2 [lindex [getLinkPeers $mirror_link] 1]" lnode1 lnode2
	    lassign "$ifname2 [lindex [getLinkPeersIfaces $mirror_link] 1]" ifname1 ifname2
	}

	displayBatchProgress $batchStep $linkCount

	try {
	    if { [getLinkDirect $link_id] || [getNodeType $lnode1] == "wlan" || [getNodeType $lnode2] == "wlan" } {
		createDirectLinkBetween $lnode1 $lnode2 $ifname1 $ifname2
	    } else {
		createLinkBetween $lnode1 $lnode2 $ifname1 $ifname2 $link_id
	    }
	    setToRunning "${link_id}_running" true
	} on error err {
	    return -code error "Error in 'createLinkBetween $lnode1 $lnode2 $ifname1 $ifname2 $link_id': $err"
	}

	incr batchStep
	incr progressbarCount

	if { $execMode != "batch" } {
	    statline $msg
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    pipesExec ""

    if { $linkCount > 0 } {
	displayBatchProgress $batchStep $linkCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc execute_linksConfigure { links linkCount w } {
    global progressbarCount execMode

    set batchStep 0
    for {set pending_links $links} {$pending_links != ""} {} {
	set link [lindex $pending_links 0]
	set msg "Configuring link $link"
	set pending_links [removeFromList $pending_links $link]

	lassign [getLinkPeers $link] lnode1 lnode2
	lassign [getLinkPeersIfaces $link] ifname1 ifname2

	set mirror_link [getLinkMirror $link]
	if { $mirror_link != "" } {
	    set msg "Configuring link $link/$mirror_link"
	    set pending_links [removeFromList $pending_links $mirror_link]

	    # switch direction for mirror links
	    lassign "$lnode2 [lindex [getLinkPeers $mirror_link] 1]" lnode1 lnode2
	    lassign "$ifname2 [lindex [getLinkPeersIfaces $mirror_link] 1]" ifname1 ifname2
	}

	displayBatchProgress $batchStep $linkCount

	try {
	    configureLinkBetween $lnode1 $lnode2 $ifname1 $ifname2 $link
	} on error err {
	    return -code error "Error in 'configureLinkBetween $lnode1 $lnode2 $ifname1 $ifname2 $link': $err"
	}

	incr batchStep
	incr progressbarCount

	if { $execMode != "batch" } {
	    statline $msg
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    pipesExec ""

    if { $linkCount > 0 } {
	displayBatchProgress $batchStep $linkCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc execute_nodesIfacesConfigure { nodes_ifaces nodeCount w } {
    global progressbarCount execMode

    set eid [getFromRunning "eid"]

    set batchStep 0
    set subnet_gws {}
    set nodes_l2data [dict create]
    dict for {node ifaces} $nodes_ifaces {
	if { $ifaces == "*" } {
	    set ifaces [allIfcList $node]
	}
	displayBatchProgress $batchStep $nodeCount

	if { [info procs [getNodeType $node].nodeIfacesConfigure] != "" } {
	    try {
		[getNodeType $node].nodeIfacesConfigure $eid $node $ifaces
	    } on error err {
		return -code error "Error in '[getNodeType $node].nodeIfacesConfigure $eid $node $ifaces': $err"
	    }
	}
	pipesExec ""

	incr batchStep
	incr progressbarCount

	if { $execMode != "batch" } {
	    $w.p configure -value $progressbarCount
	    statline "Configuring interfaces on node [getNodeName $node]"
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

#proc configureIfacesWait { nodes_ifaces nodeCount w } {
#    global progressbarCount execMode
#
#    set nodes [lmap node_id $nodes_ifaces {set node_id [lindex $node_id 0]}]
#
#    set batchStep 0
#    set nodes_left $nodes
#    while { [llength $nodes_left] > 0 } {
#	displayBatchProgress $batchStep $nodeCount
#	foreach node $nodes_left {
#	    if { ! [isNodeIfacesConfigured $node] } {
#		continue
#	    }
#
#	    incr batchStep
#	    incr progressbarCount
#
#	    set name [getNodeName $node]
#	    if { $execMode != "batch" } {
#		statline "Node $name configured"
#		$w.p configure -value $progressbarCount
#		update
#	    }
#	    displayBatchProgress $batchStep $nodeCount
#
#	    set nodes_left [removeFromList $nodes_left $node]
#	}
#    }
#
#    if { $nodeCount > 0 } {
#	displayBatchProgress $batchStep $nodeCount
#	if { $execMode == "batch" } {
#	    statline ""
#	}
#    }
#}

proc execute_nodesConfigure { nodes nodeCount w } {
    global progressbarCount execMode

    set eid [getFromRunning "eid"]

    set batchStep 0
    set subnet_gws {}
    set nodes_l2data [dict create]
    foreach node_id $nodes {
	displayBatchProgress $batchStep $nodeCount

	if { [info procs [getNodeType $node_id].nodeConfigure] != "" } {
	    try {
		[getNodeType $node_id].nodeConfigure $eid $node_id
	    } on error err {
		return -code error "Error in '[getNodeType $node_id].nodeConfigure $eid $node_id': $err"
	    }
	}
	pipesExec ""

	incr batchStep
	incr progressbarCount

	if { $execMode != "batch" } {
	    $w.p configure -value $progressbarCount
	    statline "Starting configuration on node [getNodeName $node_id]"
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

#****f* exec.tcl/generateHostsFile
# NAME
#   generateHostsFile -- generate hosts file
# SYNOPSIS
#   generateHostsFile $node_id
# FUNCTION
#   Generates /etc/hosts file on the given node containing all the nodes in the
#   topology.
# INPUTS
#   * node_id -- node id
#****
proc generateHostsFile { node_id } {
    global auto_etc_hosts

    if { $auto_etc_hosts != 1 || [[getNodeType $node_id].virtlayer] != "VIRTUALIZED" } {
	return
    }

    set etc_hosts [getFromRunning "etc_hosts"]
    if { $etc_hosts == "" } {
	foreach iter [getFromRunning "node_list"] {
	    if { [[getNodeType $iter].virtlayer] != "VIRTUALIZED" } {
		continue
	    }

	    set ctr 0
	    set ctr6 0
	    foreach ifc [ifcList $iter] {
		if { $ifc == "" } {
		    continue
		}

		set node_name [getNodeName $iter]
		foreach ipv4 [getIfcIPv4addrs $iter $ifc] {
		    set ipv4 [lindex [split $ipv4 "/"] 0]
		    if { $ctr == 0 } {
			set etc_hosts "$etc_hosts$ipv4	${node_name}\n"
		    } else {
			set etc_hosts "$etc_hosts$ipv4	${node_name}_${ctr}\n"
		    }
		    incr ctr
		}

		foreach ipv6 [getIfcIPv6addrs $iter $ifc] {
		    set ipv6 [lindex [split $ipv6 "/"] 0]
		    if { $ctr6 == 0 } {
			set etc_hosts "$etc_hosts$ipv6	${node_name}.6\n"
		    } else {
			set etc_hosts "$etc_hosts$ipv6	${node_name}_${ctr6}.6\n"
		    }
		    incr ctr6
		}
	    }
	}

	setToRunning "etc_hosts" $etc_hosts
    }

    writeDataToNodeFile $node_id /etc/hosts $etc_hosts
}

proc waitForConfStart { nodes nodeCount w } {
    global progressbarCount execMode

    set batchStep 0
    set nodes_left $nodes
    while { [llength $nodes_left] > 0 } {
	displayBatchProgress $batchStep $nodeCount
	foreach node $nodes_left {
	    if { ! [isNodeConfigured $node] } {
		continue
	    }

	    incr batchStep
	    incr progressbarCount

	    set name [getNodeName $node]
	    if { $execMode != "batch" } {
		statline "Node $name configured"
		$w.p configure -value $progressbarCount
		update
	    }
	    displayBatchProgress $batchStep $nodeCount

	    set nodes_left [removeFromList $nodes_left $node]
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc finishExecuting { status msg w } {
    global progressbarCount execMode

    foreach var "instantiate_nodes create_nodes_ifaces instantiate_links
	configure_links configure_nodes_ifaces configure_nodes" {

	setToExecuteVars "$var" ""
    }

    catch { pipesClose }
    if { $execMode == "batch" } {
	puts $msg
    } else {
	catch { destroy $w }

	set progressbarCount 0
	if { ! $status } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES error" \
		"$msg \nTerminate the experiment and report the bug!" info 0 Dismiss
	}
    }
}

proc checkForErrors { nodes nodeCount w } {
    global progressbarCount execMode

    set batchStep 0
    set err_nodes ""
    foreach node $nodes {
	set msg "no error"
	if { [isNodeError $node] } {
	    set msg "error found"
	    append err_nodes "[getNodeName $node] ($node), "
	}

	incr batchStep
	incr progressbarCount

	set name [getNodeName $node]
	if { $execMode != "batch" } {
	    statline "Node $name checked - $msg"
	    $w.p configure -value $progressbarCount
	    update
	}
	displayBatchProgress $batchStep $nodeCount
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }

    if { $err_nodes != "" } {
	set err_nodes [string trimright $err_nodes ", "]
	set msg "Issues encountered while configuring nodes:\n$err_nodes\nCheck their /err.log, /out.log and /boot.conf (or /custom.conf) files." \

	if { $execMode != "batch" } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES warning" \
		"$msg" \
		info 0 Dismiss
	} else {
	    puts "\nIMUNES warning - $msg\n"
	}
    }
}

proc checkForErrorsIfaces { nodes nodeCount w } {
    global progressbarCount execMode

    set batchStep 0
    set err_nodes ""
    foreach node $nodes {
	set msg "no error"
	if { [isNodeErrorIfaces $node] } {
	    set msg "error found"
	    append err_nodes "[getNodeName $node] ($node), "
	}

	incr batchStep
	incr progressbarCount

	set name [getNodeName $node]
	if { $execMode != "batch" } {
	    statline "Interfaces on node $name checked - $msg"
	    $w.p configure -value $progressbarCount
	    update
	}
	displayBatchProgress $batchStep $nodeCount
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }

    if { $err_nodes != "" } {
	set err_nodes [string trimright $err_nodes ", "]
	set msg "Issues encountered while configuring interfaces on nodes:\n$err_nodes\nCheck their /err_ifaces.log, /out_ifaces.log and /boot_ifaces.conf files." \

	if { $execMode != "batch" } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES warning" \
		"$msg" \
		info 0 Dismiss
	} else {
	    puts "\nIMUNES warning - $msg\n"
	}
    }
}

#****f* exec.tcl/startNodeFromMenu
# NAME
#   startNodeFromMenu -- start node from button3menu
# SYNOPSIS
#   startNodeFromMenu $node
# FUNCTION
#   Invokes the [typmodel $node].nodeConfigure procedure, along with services startup.
# INPUTS
#   * node -- node id
#****
proc startNodeFromMenu { node } {
    global progressbarCount execMode

    set progressbarCount 0
    set w ""
    if { $execMode != "batch" } {
	set w .startup
	catch { destroy $w }

	toplevel $w -takefocus 1
	wm transient $w .
	wm title $w "Starting node $node..."
	message $w.msg -justify left -aspect 1200 \
	    -text "Starting up virtual nodes and links."
	pack $w.msg
	update

	ttk::progressbar $w.p -orient horizontal -length 250 \
	    -mode determinate -maximum 1 -value $progressbarCount
	pack $w.p
	update

	grab $w
	wm protocol $w WM_DELETE_WINDOW {
	}
    }

    pipesCreate
    services start "NODEINST" $node
    services start "LINKINST" $node

    set allNodeCount 1
    try {
	execute_nodesConfigure $node 1 $w
	statline "Waiting for configuration on $allNodeCount node(s)..."
	waitForConfStart $node $allNodeCount $w
    } on error err {
	finishExecuting 0 "$err" $w
	return
    }

    services start "NODECONF" $node
    pipesClose

    finishExecuting 1 "" $w
}

