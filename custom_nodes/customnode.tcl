#
# Copyright 2005-2013 University of Zagreb.
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

# $Id: customnode.tcl 63 2013-10-03 12:17:50Z valter $


#****h* imunes/customnode.tcl
# NAME
#  customnode.tcl -- defines customnode specific procedures
# FUNCTION
#  This module is used to define all the customnode specific procedures.
# NOTES
#  Procedures in this module start with the keyword customnode and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

# CUSTOMNODE change custom node type
set MODULE customnode

registerModule $MODULE

global nodeNamingBase
# CUSTOMNODE change this (used for naming new nodes: 'node-type name-prefix')
array set nodeNamingBase {
    customnode cn
}

#****f* customnode.tcl/customnode.confNewIfc
# NAME
#   customnode.confNewIfc -- configure new interface
# SYNOPSIS
#   customnode.confNewIfc $node $ifc
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#****
proc $MODULE.confNewIfc { node ifc } {
    global changeAddressRange changeAddressRange6
    set changeAddressRange 0
    set changeAddressRange6 0
    autoIPv4addr $node $ifc
    autoIPv6addr $node $ifc
    autoMACaddr $node $ifc
}

#****f* customnode.tcl/customnode.confNewNode
# NAME
#   customnode.confNewNode -- configure new node
# SYNOPSIS
#   customnode.confNewNode $node
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node -- node id
#****
proc $MODULE.confNewNode { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    global nodeNamingBase

    # CUSTOMNODE change this (used for naming new nodes: 'node-type name-prefix')
    set nconfig [list \
	"hostname [getNewNodeNameType customnode $nodeNamingBase(customnode)]" \
	! ]
    lappend $node "network-config [list $nconfig]"

    setAutoDefaultRoutesStatus $node "enabled"
    setLogIfcType $node lo0 lo
    setIfcIPv4addr $node lo0 "127.0.0.1/8"
    setIfcIPv6addr $node lo0 "::1/128"

    # CUSTOMNODE the only functional difference from the PC node
    setNodeCustomImage $node "imunes/template:some-other-tag"
}

#****f* customnode.tcl/customnode.icon
# NAME
#   customnode.icon -- icon
# SYNOPSIS
#   customnode.icon $size
# FUNCTION
#   Returns path to node icon, depending on the specified size.
# INPUTS
#   * size -- "normal", "small" or "toolbar"
# RESULT
#   * path -- path to icon
#****
proc $MODULE.icon { size } {
    global ROOTDIR LIBDIR
    switch $size {
      normal {
	# CUSTOMNODE change custom node icon
	return $ROOTDIR/$LIBDIR/custom_nodes/icons/normal/customnode.gif
      }
      small {
	# CUSTOMNODE change custom node icon
	return $ROOTDIR/$LIBDIR/custom_nodes/icons/small/customnode.gif
      }
      toolbar {
	# CUSTOMNODE change custom node icon
	return $ROOTDIR/$LIBDIR/custom_nodes/icons/tiny/customnode.gif
      }
    }
}

#****f* customnode.tcl/customnode.toolbarIconDescr
# NAME
#   customnode.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   customnode.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
    # CUSTOMNODE change custom node GUI description
    return "Add new customnode"
}

#****f* customnode.tcl/customnode.notebookDimensions
# NAME
#   customnode.notebookDimensions -- notebook dimensions
# SYNOPSIS
#   customnode.notebookDimensions $wi
# FUNCTION
#   Returns the specified notebook height and width.
# INPUTS
#   * wi -- widget
# RESULT
#   * size -- notebook size as {height width}
#****
proc $MODULE.notebookDimensions { wi } {
    set h 210
    set w 507

    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Configuration" } {
	set h 320
	set w 507
    }
    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Interfaces" } {
	set h 370
	set w 507
    }

    return [list $h $w]
}

#****f* customnode.tcl/customnode.ifcName
# NAME
#   customnode.ifcName -- interface name
# SYNOPSIS
#   customnode.ifcName
# FUNCTION
#   Returns customnode interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifcName {l r} {
    return [l3IfcName $l $r]
}

#****f* customnode.tcl/customnode.IPAddrRange
# NAME
#   customnode.IPAddrRange -- IP address range
# SYNOPSIS
#   customnode.IPAddrRange
# FUNCTION
#   Returns customnode IP address range
# RESULT
#   * range -- customnode IP address range
#****
proc $MODULE.IPAddrRange {} {
    return 20
}

#****f* customnode.tcl/customnode.layer
# NAME
#   customnode.layer -- layer
# SYNOPSIS
#   set layer [customnode.layer]
# FUNCTION
#   Returns the layer on which the customnode communicates, i.e. returns NETWORK.
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.layer {} {
    return NETWORK
}

#****f* customnode.tcl/customnode.virtlayer
# NAME
#   customnode.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [customnode.virtlayer]
# FUNCTION
#   Returns the layer on which the customnode is instantiated i.e. returns VIMAGE.
# RESULT
#   * layer -- set to VIMAGE
#****
proc $MODULE.virtlayer {} {
    return VIMAGE
}

#****f* customnode.tcl/customnode.cfggen
# NAME
#   customnode.cfggen -- configuration generator
# SYNOPSIS
#   set config [customnode.cfggen $node]
# FUNCTION
#   Returns the generated configuration. This configuration represents
#   the configuration loaded on the booting time of the virtual nodes
#   and it is closly related to the procedure customnode.bootcmd.
#   For each interface in the interface list of the node, ip address is
#   configured and each static route from the simulator is added.
# INPUTS
#   * node -- node id (type of the node is customnode)
# RESULT
#   * congif -- generated configuration
#****
proc $MODULE.cfggen { node } {
    set cfg {}
    set cfg [concat $cfg [nodeCfggenIfcIPv4 $node]]
    set cfg [concat $cfg [nodeCfggenIfcIPv6 $node]]
    lappend cfg ""

    set cfg [concat $cfg [nodeCfggenRouteIPv4 $node]]
    set cfg [concat $cfg [nodeCfggenRouteIPv6 $node]]

    return $cfg
}

#****f* customnode.tcl/customnode.bootcmd
# NAME
#   customnode.bootcmd -- boot command
# SYNOPSIS
#   set appl [customnode.bootcmd $node]
# FUNCTION
#   Procedure bootcmd returns the application that reads and employes the
#   configuration generated in customnode.cfggen.
#   In this case (procedure customnode.bootcmd) specific application is /bin/sh
# INPUTS
#   * node -- node id (type of the node is customnode)
# RESULT
#   * appl -- application that reads the configuration (/bin/sh)
#****
proc $MODULE.bootcmd { node } {
    return "/bin/sh"
}

#****f* customnode.tcl/customnode.shellcmds
# NAME
#   customnode.shellcmds -- shell commands
# SYNOPSIS
#   set shells [customnode.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system.
# RESULT
#   * shells -- default shells for the customnode node
#****
proc $MODULE.shellcmds {} {
    return "csh bash sh tcsh"
}

#****f* customnode.tcl/customnode.instantiate
# NAME
#   customnode.instantiate -- instantiate
# SYNOPSIS
#   customnode.instantiate $eid $node
# FUNCTION
#   Procedure instantiate creates a new virtaul node
#   for a given node in imunes.
#   Procedure customnode.instantiate cretaes a new virtual node with
#   all the interfaces and CPU parameters as defined in imunes.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is customnode)
#****
proc $MODULE.instantiate { eid node } {
    l3node.instantiate $eid $node
}

proc $MODULE.setupNamespace { eid node } {
    l3node.setupNamespace $eid $node
}

proc $MODULE.initConfigure { eid node } {
    l3node.initConfigure $eid $node
}

proc $MODULE.createIfcs { eid node ifcs } {
    l3node.createIfcs $eid $node $ifcs
}

#****f* customnode.tcl/customnode.start
# NAME
#   customnode.start -- start
# SYNOPSIS
#   customnode.start $eid $node
# FUNCTION
#   Starts a new customnode. The node can be started if it is instantiated.
#   Simulates the booting proces of a customnode, by calling l3node.start procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is customnode)
#****
proc $MODULE.start { eid node } {
    l3node.start $eid $node
}

#****f* customnode.tcl/customnode.shutdown
# NAME
#   customnode.shutdown -- shutdown
# SYNOPSIS
#   customnode.shutdown $eid $node
# FUNCTION
#   Shutdowns a customnode. Simulates the shutdown proces of a customnode,
#   by calling the l3node.shutdown procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is customnode)
#****
proc $MODULE.shutdown { eid node } {
    l3node.shutdown $eid $node
}

proc $MODULE.destroyIfcs { eid node ifcs } {
    l3node.destroyIfcs $eid $node $ifcs
}

#****f* customnode.tcl/customnode.destroy
# NAME
#   customnode.destroy -- destroy
# SYNOPSIS
#   customnode.destroy $eid $node
# FUNCTION
#   Destroys a customnode. Destroys all the interfaces of the customnode
#   and the vimage itself by calling l3node.destroy procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is customnode)
#****
proc $MODULE.destroy { eid node } {
    l3node.destroy $eid $node
}

#****f* customnode.tcl/customnode.nghook
# NAME
#   customnode.nghook -- nghook
# SYNOPSIS
#   customnode.nghook $eid $node $ifc
# FUNCTION
#   Returns the id of the netgraph node and the name of the netgraph hook
#   which is used for connecting two netgraph nodes. This procedure calls
#   l3node.hook procedure and passes the result of that procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#   * ifc -- interface name
# RESULT
#   * nghook -- the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node ifc } {
    return [l3node.nghook $eid $node $ifc]
}

#****f* customnode.tcl/customnode.configGUI
# NAME
#   customnode.configGUI -- configuration GUI
# SYNOPSIS
#   customnode.configGUI $c $node
# FUNCTION
#   Defines the structure of the customnode configuration window by calling
#   procedures for creating and organising the window, as well as
#   procedures for adding certain modules to that window.
# INPUTS
#   * c -- tk canvas
#   * node -- node id
#****
proc $MODULE.configGUI { c node } {
    global wi
    global guielements treecolumns
    set guielements {}

    configGUI_createConfigPopupWin $c
    # CUSTOMNODE change custom node GUI window title
    wm title $wi "customnode configuration"
    configGUI_nodeName $wi $node "Node name:"

    set tabs [configGUI_addNotebook $wi $node {"Configuration" "Interfaces"}]
    set configtab [lindex $tabs 0]
    set ifctab [lindex $tabs 1]

    set treecolumns {"OperState State" "NatState Nat" "IPv4addr IPv4 addr" "IPv6addr IPv6 addr" \
	    "MACaddr MAC addr" "MTU MTU" "QLen Queue len" "QDisc Queue disc" "QDrop Queue drop"}
    configGUI_addTree $ifctab $node

    configGUI_customImage $configtab $node
    configGUI_attachDockerToExt $configtab $node
    configGUI_servicesConfig $configtab $node
    configGUI_staticRoutes $configtab $node
    configGUI_snapshots $configtab $node
    configGUI_customConfig $configtab $node

    configGUI_buttonsACNode $wi $node
}

#****f* customnode.tcl/customnode.configInterfacesGUI
# NAME
#   customnode.configInterfacesGUI -- configuration of interfaces GUI
# SYNOPSIS
#   customnode.configInterfacesGUI $wi $node $ifc
# FUNCTION
#   Defines which modules for changing interfaces parameters are contained in
#   the customnode configuration window. It is done by calling procedures for adding
#   certain modules to the window.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc $MODULE.configInterfacesGUI { wi node ifc } {
    global guielements

    configGUI_ifcEssentials $wi $node $ifc
    configGUI_ifcQueueConfig $wi $node $ifc
    configGUI_ifcMACAddress $wi $node $ifc
    configGUI_ifcIPv4Address $wi $node $ifc
    configGUI_ifcIPv6Address $wi $node $ifc
}
