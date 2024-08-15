#
# Copyright 2005-2010 University of Zagreb, Croatia.
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
# This work was supported in part by Croatian Ministry of Science
# and Technology through the research contract #IP-2003-143.
#

#****h* imunes/stpswitch.tcl
# NAME
#  stpswitch.tcl -- defines stpswitch specific procedures
# FUNCTION
#  This module is used to define all the stpswitch specific procedures.
# NOTES
#  Procedures in this module start with the keyword stpswitch and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE stpswitch

registerModule $MODULE

proc $MODULE.prepareSystem {} {
    catch { exec kldload if_bridge }
    catch { exec kldload bridgestp }
#   catch { exec jexec sysctl net.link.bridge.log_stp=1 }
    catch { exec jexec sysctl net.link.bridge.pfil_member=0 }
    catch { exec jexec sysctl net.link.bridge.pfil_bridge=0 }
    catch { exec jexec sysctl net.link.bridge.pfil_onlyip=0 }
}

proc $MODULE.confNewIfc { node_id ifc } {
    autoMACaddr $node_id $ifc

    setBridgeIfcDiscover $node_id $ifc 1
    setBridgeIfcLearn $node_id $ifc 1
    setBridgeIfcStp $node_id $ifc 1
    setBridgeIfcAutoedge $node_id $ifc 1
    setBridgeIfcAutoptp $node_id $ifc 1
    setBridgeIfcPriority $node_id $ifc 128
    setBridgeIfcPathcost $node_id $ifc 0
    setBridgeIfcMaxaddr $node_id $ifc 0
}

proc $MODULE.confNewNode { node_id } {
    global nodeNamingBase

    setNodeName $node_id [getNewNodeNameType stpswitch $nodeNamingBase(stpswitch)]

    setBridgeProtocol $node_id "rstp"
    setBridgePriority $node_id "32768"
    setBridgeHoldCount $node_id "6"
    setBridgeMaxAge $node_id "20"
    setBridgeFwdDelay $node_id "15"
    setBridgeHelloTime $node_id "2"
    setBridgeMaxAddr $node_id "100"
    setBridgeTimeout $node_id "240"

    set logiface_id [newLogIface $node_id "lo"]
    setIfcIPv4addrs $node_id $logiface_id "127.0.0.1/8"
    setIfcIPv6addrs $node_id $logiface_id "::1/128"
}

proc $MODULE.icon {size} {
    global ROOTDIR LIBDIR

    switch $size {
	normal {
	    return $ROOTDIR/$LIBDIR/icons/normal/stpswitch.gif
	}
	small {
	    return $ROOTDIR/$LIBDIR/icons/small/stpswitch.gif
	}
	toolbar {
	    return $ROOTDIR/$LIBDIR/icons/tiny/stpswitch.gif
	}
    }
}

proc $MODULE.toolbarIconDescr {} {
    return "Add new RSTP switch"
}

proc $MODULE.notebookDimensions { wi } {
    set h 340
    set w 507

    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Interfaces" } {
	set h 320
    }
    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Bridge" } {
	set h 370
	set w 513
    }

    return [list $h $w]
}

proc $MODULE.ifcName {l r} {
    return [l3IfcName $l $r]
}

proc $MODULE.IPAddrRange {} {
    return 20
}

#****f* stpswitch.tcl/stpswitch.netlayer
# NAME
#   stpswitch.netlayer
# SYNOPSIS
#   set layer [stpswitch.netlayer]
# FUNCTION
#   Returns the layer on which the stpswitch communicates
#   i.e. returns LINK.
# RESULT
#   * layer -- set to LINK
#****

proc $MODULE.netlayer {} {
    return LINK
}

#****f* stpswitch.tcl/stpswitch.virtlayer
# NAME
#   stpswitch.virtlayer
# SYNOPSIS
#   set layer [stpswitch.virtlayer]
# FUNCTION
#   Returns the layer on which the stpswitch is instantiated
#   i.e. returns VIMAGE.
# RESULT
#   * layer -- set to VIMAGE
#****

proc $MODULE.virtlayer {} {
    return VIMAGE
}

#****f* stpswitch.tcl/stpswitch.cfggen
# NAME
#   stpswitch.cfggen
# SYNOPSIS
#   set config [stpswitch.cfggen $node_id]
# FUNCTION
#   Returns the generated configuration. This configuration represents
#   the configuration loaded on the booting time of the virtual nodes
#   and it is closly related to the procedure stpswitch.bootcmd
#   Foreach interface in the interface list of the node ip address is
#   configured and each static route from the simulator is added.
# INPUTS
#   * node_id - id of the node (type of the node is stpswitch)
# RESULT
#   * congif -- generated configuration
#****

proc $MODULE.cfggen { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set cfg {}

    foreach ifc [ifcList $node_id] {
	set addr [getIfcIPv4addr $node_id $ifc]
	if { $addr != "" } {
	    lappend cfg "ifconfig $ifc inet $addr"
	}
	set addr [getIfcIPv6addr $node_id $ifc]
	if { $addr != "" } {
	    lappend cfg "ifconfig $ifc inet6 $addr"
	}
    }

    lappend cfg ""

    lappend cfg "bridgeName=`ifconfig bridge create`"

    set bridgeProtocol [getBridgeProtocol $node_id]
    if { $bridgeProtocol != "" } {
	lappend cfg "ifconfig \$bridgeName proto $bridgeProtocol"
    }

    set bridgePriority [getBridgePriority $node_id]
    if { $bridgePriority != "" } {
	lappend cfg "ifconfig \$bridgeName priority $bridgePriority"
    }

    set bridgeMaxAge [getBridgeMaxAge $node_id]
    if { $bridgeMaxAge != "" } {
	lappend cfg "ifconfig \$bridgeName maxage $bridgeMaxAge"
    }

    set bridgeFwdDelay [getBridgeFwdDelay $node_id]
    if { $bridgeFwdDelay != "" } {
	lappend cfg "ifconfig \$bridgeName fwddelay $bridgeFwdDelay"
    }

    set bridgeHoldCnt [getBridgeHoldCount $node_id]
    if { $bridgeHoldCnt != "" } {
	lappend cfg "ifconfig \$bridgeName holdcnt $bridgeHoldCnt"
    }

    set bridgeHelloTime [getBridgeHelloTime $node_id]
    if { $bridgeHelloTime != "" && $bridgeProtocol == "stp" } {
	lappend cfg "ifconfig \$bridgeName hellotime $bridgeHelloTime"
    }

    set bridgeMaxAddr [getBridgeMaxAddr $node_id]
    if { $bridgeMaxAddr != "" } {
	lappend cfg "ifconfig \$bridgeName maxaddr $bridgeMaxAddr"
    }

    set bridgeTimeout [getBridgeTimeout $node_id]
    if { $bridgeTimeout != "" } {
	lappend cfg "ifconfig \$bridgeName timeout $bridgeTimeout"
    }

    lappend cfg ""

    foreach ifc [ifcList $node_id] {

	if {[getIfcOperState $node_id $ifc] == "down"} {
	    lappend cfg "ifconfig $ifc down"
	} else {
	    lappend cfg "ifconfig $ifc up"
	}

	if {[getBridgeIfcSnoop $node_id $ifc] == "1"} {
	    lappend cfg "ifconfig \$bridgeName span $ifc"
	    lappend cfg ""
	    continue
	}

	lappend cfg "ifconfig \$bridgeName addm $ifc up"

	if {[getBridgeIfcStp $node_id $ifc] == "1"} {
	    lappend cfg "ifconfig \$bridgeName stp $ifc"
	} else {
	    lappend cfg "ifconfig \$bridgeName -stp $ifc"
	}

	if {[getBridgeIfcDiscover $node_id $ifc] == "1"} {
	    lappend cfg "ifconfig \$bridgeName discover $ifc"
	} else {
	    lappend cfg "ifconfig \$bridgeName -discover $ifc"
	}

	if {[getBridgeIfcLearn $node_id $ifc] == "1"} {
	    lappend cfg "ifconfig \$bridgeName learn $ifc"
	} else {
	    lappend cfg "ifconfig \$bridgeName -learn $ifc"
	}

	if {[getBridgeIfcSticky $node_id $ifc] == "1"} {
	    lappend cfg "ifconfig \$bridgeName sticky $ifc"
	} else {
	    lappend cfg "ifconfig \$bridgeName -sticky $ifc"
	}

	if {[getBridgeIfcPrivate $node_id $ifc] == "1"} {
	    lappend cfg "ifconfig \$bridgeName private $ifc"
	} else {
	    lappend cfg "ifconfig \$bridgeName -private $ifc"
	}

	if {[getBridgeIfcEdge $node_id $ifc] == "1"} {
	    lappend cfg "ifconfig \$bridgeName edge $ifc"
	} else {
	    lappend cfg "ifconfig \$bridgeName -edge $ifc"
	}

	if {[getBridgeIfcAutoedge $node_id $ifc] == "1"} {
	    lappend cfg "ifconfig \$bridgeName autoedge $ifc"
	} else {
	    lappend cfg "ifconfig \$bridgeName -autoedge $ifc"
	}

	if {[getBridgeIfcPtp $node_id $ifc] == "1"} {
	    lappend cfg "ifconfig \$bridgeName ptp $ifc"
	} else {
	    lappend cfg "ifconfig \$bridgeName -ptp $ifc"
	}

	if {[getBridgeIfcAutoptp $node_id $ifc] == "1"} {
	    lappend cfg "ifconfig \$bridgeName autoptp $ifc"
	} else {
	    lappend cfg "ifconfig \$bridgeName -autoptp $ifc"
	}

	set priority [getBridgeIfcPriority $node_id $ifc]
	lappend cfg "ifconfig \$bridgeName ifpriority $ifc $priority"

	set pathcost [getBridgeIfcPathcost $node_id $ifc]
	lappend cfg "ifconfig \$bridgeName ifpathcost $ifc $pathcost"

	set maxaddr [getBridgeIfcMaxaddr $node_id $ifc]
	lappend cfg "ifconfig \$bridgeName ifmaxaddr $ifc $maxaddr"

	lappend cfg ""
    }

    return $cfg
}

#****f* stpswitch.tcl/stpswitch.bootcmd
# NAME
#   stpswitch.bootcmd
# SYNOPSIS
#   set appl [stpswitch.bootcmd $node_id]
# FUNCTION
#   Procedure bootcmd returns the application that reads and
#   employes the configuration generated in stpswitch.cfggen.
#   In this case (procedure stpswitch.bootcmd) specific application
#   is /bin/sh
# INPUTS
#   * node_id - id of the node (type of the node is stpswitch)
# RESULT
#   * appl -- application that reads the configuration (/bin/sh)
#****

proc $MODULE.bootcmd { node_id } {
    return "/bin/sh"
}

#****f* stpswitch.tcl/stpswitch.shellcmds
# NAME
#   stpswitch.shellcmds
# SYNOPSIS
#   set shells [stpswitch.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system.
# RESULT
#   * shells -- default shells for the stpswitch
#****

proc $MODULE.shellcmds { } {
        return "csh bash sh tcsh"
}

#****f* stpswitch.tcl/stpswitch.instantiate
# NAME
#   stpswitch.instantiate
# SYNOPSIS
#   stpswitch.instantiate $eid $node_id
# FUNCTION
#   Procedure instantiate creates a new virtaul node
#   for a given node in imunes.
#   Procedure stpswitch.instantiate cretaes a new virtual node
#   with all the interfaces and CPU parameters as defined
#   in imunes.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node (type of the node is stpswitch)
#****

proc $MODULE.instantiate { eid node_id } {
    l3node.instantiate $eid $node_id
}

proc $MODULE.setupNamespace { eid node_id } {
    l3node.setupNamespace $eid $node_id
}

proc $MODULE.initConfigure { eid node_id } {
    l3node.initConfigure $eid $node_id
}

proc $MODULE.createIfcs { eid node_id ifcs } {
    l3node.createIfcs $eid $node_id $ifcs
}

#****f* stpswitch.tcl/stpswitch.start
# NAME
#   stpswitch.start
# SYNOPSIS
#   stpswitch.start $eid $node_id
# FUNCTION
#   Starts a new stpswitch. The node can be started if it is instantiated.
#   Simulates the booting proces of a stpswitch, by calling l3node.start
#   procedure.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node (type of the node is stpswitch)
#****
proc $MODULE.start { eid node_id } {
    l3node.start $eid $node_id
}

#****f* stpswitch.tcl/stpswitch.shutdown
# NAME
#   stpswitch.shutdown
# SYNOPSIS
#   stpswitch.shutdown $eid $node_id
# FUNCTION
#   Shutdowns a stpswitch. Simulates the shutdown proces of a stpswitch,
#   by calling the l3node.shutdown procedure.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node (type of the node is stpswitch)
#****
proc $MODULE.shutdown { eid node_id } {
    l3node.shutdown $eid $node_id
    catch { exec jexec $eid.$node_id ifconfig | grep bridge | cut -d : -f1} br
    set bridges [split $br]
    foreach bridge $bridges {
	catch {exec jexec $eid.$node_id ifconfig $bridge destroy}
    }
}

proc $MODULE.destroyIfcs { eid node_id ifcs } {
    l3node.destroyIfcs $eid $node_id $ifcs
}

#****f* stpswitch.tcl/stpswitch.destroy
# NAME
#   stpswitch.destroy
# SYNOPSIS
#   stpswitch.destroy $eid $node_id
# FUNCTION
#   Destroys a stpswitch. Destroys all the interfaces of the stpswitch
#   and the vimage itself by calling l3node.destroy procedure.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node (type of the node is stpswitch)
#****
proc $MODULE.destroy { eid node_id } {
    l3node.destroy $eid $node_id
}

#****f* stpswitch.tcl/stpswitch.nghook
# NAME
#   stpswitch.nghook
# SYNOPSIS
#   stpswitch.nghook $eid $node_id $ifc
# FUNCTION
#   Returns the id of the netgraph node and the name of the
#   netgraph hook which is used for connecting two netgraph
#   nodes. This procedure calls l3node.hook procedure and
#   passes the result of that procedure.
# INPUTS
#   * eid - experiment id
#   * node_id - node id
#   * ifc - interface name
# RESULT
#   * nghook - the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****

proc $MODULE.nghook { eid node_id ifc } {
    return [l3node.nghook $eid $node_id $ifc]
}


#****f* stpswitch.tcl/stpswitch.configGUI
# NAME
#   stpswitch.configGUI
# SYNOPSIS
#   stpswitch.configGUI $c $node_id
# FUNCTION
#   Defines the structure of the stpswitch configuration window
#   by calling procedures for creating and organising the
#   window, as well as procedures for adding certain modules
#   to that window.
# INPUTS
#   * c - tk canvas
#   * node_id - node id
#****
proc $MODULE.configGUI { c node_id } {
    global wi
    global guielements treecolumns
    global brguielements
    global brtreecolumns

    set guielements {}
    set brguielements {}

    configGUI_createConfigPopupWin $c
    wm title $wi "stpswitch configuration"
    configGUI_nodeName $wi $node_id "Node name:"

    set tabs [configGUI_addNotebook $wi $node_id {"Configuration" "Interfaces" \
    "Bridge"}]
    set configtab [lindex $tabs 0]
    set ifctab [lindex $tabs 1]
    set bridgeifctab [lindex $tabs 2]

    set treecolumns { "OperState State" "NatState Nat" "IPv4addr IPv4 addr" \
	"IPv6addr IPv6 addr" "MACaddr MAC addr" "MTU MTU" \
	"QLen Queue len" "QDisc Queue disc" "QDrop Queue drop"}
    configGUI_addTree $ifctab $node_id

    set brtreecolumns { "Snoop Snoop" "Stp STP" "Priority Priority" \
	"Discover Discover" "Learn Learn" "Sticky Sticky" "Private Private" \
	"Edge Edge" "Autoedge AutoEdge" "Ptp Ptp" "Autoptp AutoPtp" \
	"Maxaddr Max addr" "Pathcost Pathcost" }
    configGUI_addBridgeTree $bridgeifctab $node_id

    configGUI_bridgeConfig $configtab $node_id
    # TODO: are these needed?
    configGUI_staticRoutes $configtab $node_id
    configGUI_customConfig $configtab $node_id

    configGUI_buttonsACNode $wi $node_id
}


#****f* stpswitch.tcl/stpswitch.configInterfacesGUI
# NAME
#   stpswitch.configInterfacesGUI
# SYNOPSIS
#   stpswitch.configInterfacesGUI $wi $node_id $ifc
# FUNCTION
#   Defines which modules for changing interfaces parameters
#   are contained in the stpswitch configuration window. It is done
#   by calling procedures for adding certain modules to the window.
# INPUTS
#   * wi - widget
#   * node_id - node id
#   * ifc - interface id
#****
proc $MODULE.configInterfacesGUI { wi node_id ifc } {
    global guielements

    configGUI_ifcEssentials $wi $node_id $ifc
    configGUI_ifcQueueConfig $wi $node_id $ifc
    configGUI_ifcMACAddress $wi $node_id $ifc
    configGUI_ifcIPv4Address $wi $node_id $ifc
    configGUI_ifcIPv6Address $wi $node_id $ifc
}

proc $MODULE.configBridgeInterfacesGUI { wi node_id ifc } {
    global guielements

    configGUI_ifcBridgeAttributes $wi $node_id $ifc
}
