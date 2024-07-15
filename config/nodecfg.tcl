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
# This work was supported in part by Croatian Ministry of Science
# and Technology through the research contract #IP-2003-143.
#

# $Id: nodecfg.tcl 149 2015-03-27 15:50:14Z valter $


#****h* imunes/nodecfg.tcl
# NAME
#  nodecfg.tcl -- file used for manipultaion with nodes in IMUNES
# FUNCTION
#  This module is used to define all the actions used for configuring 
#  nodes in IMUNES. The definition of nodes is presented in NOTES
#  section.
#
# NOTES
#  The IMUNES configuration file contains declarations of IMUNES objects.
#  Each object declaration contains exactly the following three fields:
#
#     object_class object_id class_specific_config_string
#
#  Currently only two object classes are supported: node and link. In the
#  future we plan to implement a canvas object, which should allow placing
#  other objects into multiple visual maps.
#
#  "node" objects are further divided by their type, which can be one of
#  the following:
#  * router
#  * host
#  * pc
#  * lanswitch
#  * hub
#  * rj45
#  * pseudo
#
#  The following node types are to be implemented in the future:
#  * frswitch
#  * text
#  * image
#
#
# Routines for manipulation of per-node network configuration files
# IMUNES keeps per-node network configuration in an IOS / Zebra / Quagga
# style format.
#
# Network configuration is embedded in each node's config section via the
# "network-config" statement. The following functions can be used to
# manipulate the per-node network config:
#
# netconfFetchSection { node_id sectionhead }
#	Returns a section of a config file starting with the $sectionhead
#	line, and ending with the first occurence of the "!" sign.
#
# netconfClearSection { node_id sectionhead }
#	Removes the appropriate section from the config.
#
# netconfInsertSection { node_id section }
#	Inserts a section in the config file. Sections beginning with the
#	"interface" keyword are inserted at the head of the config, and
#	all other sequences are simply appended to the config tail.
#
# getIfcOperState { node_id ifc }
#	Returns "up" or "down".
#
# setIfcOperState { node_id ifc state }
#	Sets the new interface state. Implicit default is "up".
#
# getIfcNatState { node_id ifc }
#	Returns "on" or "off".
#
# setIfcNatState { node_id ifc state }
#	Sets the new interface NAT state. Implicit default is "off".
#
# getIfcQDisc { node_id ifc }
#	Returns "FIFO", "WFQ" or "DRR".
#
# setIfcQDisc { node_id ifc qdisc }
#	Sets the new queuing discipline. Implicit default is FIFO.
#
# getIfcQDrop { node_id ifc }
#	Returns "drop-tail" or "drop-head".
#
# setIfcQDrop { node_id ifc qdrop }
#	Sets the new queuing discipline. Implicit default is "drop-tail".
#
# getIfcQLen { node_id ifc }
#	Returns the queue length limit in packets.
#
# setIfcQLen { node_id ifc len }
#	Sets the new queue length limit.
#
# getIfcMTU { node_id ifc }
#	Returns the configured MTU, or an empty string if default MTU is used.
#
# setIfcMTU { node_id ifc mtu }
#	Sets the new MTU. Zero MTU value denotes the default MTU.
#
# getIfcIPv4addr { node_id ifc }
#	Returns a list of all IPv4 addresses assigned to an interface.
#
# setIfcIPv4addrs { node_id ifc addr }
#	Sets a new IPv4 address(es) on an interface. The correctness of the
#	IP address format is not checked / enforced.
#
# getIfcIPv6addr { node_id ifc }
#	Returns a list of all IPv6 addresses assigned to an interface.
#
# setIfcIPv6addrs { node_id ifc addr }
#	Sets a new IPv6 address(es) on an interface. The correctness of the
#	IP address format is not checked / enforced.
#
# getDefaultGateways { node subnet_gws nodes_l2data }
#	Returns a list of all default IPv4/IPv6 routes as {destination
#	gateway} pairs and updates existing subnet gateways and members.
#
# getStatIPv4routes { node_id }
#	Returns a list of all static IPv4 routes as a list of
#	{destination gateway {metric}} pairs.
#
# setStatIPv4routes { node_id route_list }
#	Replace all current static route entries with a new one, in form of
#	a list, as described above.
#
# getStatIPv6routes { node_id }
#	Returns a list of all static IPv6 routes as a list of
#	{destination gateway {metric}} pairs.
#
# setStatIPv6routes { node_id route_list }
#	Replace all current static route entries with a new one, in form of
#	a list, as described above.
#
# getNodeName { node_id }
#	Returns node's logical name.
#
# setNodeName { node_id name }
#	Sets a new node's logical name.
#
# getNodeType { node_id }
#	Returns node's type.
#
# getNodeModel { node_id }
#	Returns node's optional model identifier.
#
# setNodeModel { node_id model }
#	Sets the node's optional model identifier.
#
# getNodeCanvas { node_id }
#	Returns node's canvas affinity.
#
# setNodeCanvas { node_id canvas_id }
#	Sets the node's canvas affinity.
#
# getNodeCoords { node_id }
#	Return icon coords.
#
# setNodeCoords { node_id coords }
#	Sets the coordinates.
#
# getNodeSnapshot { node_id }
#	Return node's snapshot name.
#
# setNodeSnapshot { node_id coords }
#	Sets node's snapshot name.
#
# getSTPEnabled { node_id }
#	Returns true if STP is enabled.
#
# setSTPEnabled { node_id state }
#	Sets STP state.
#
# getNodeLabelCoords { node_id }
#	Return node label coordinates.
#
# setNodeLabelCoords { node_id coords }
#	Sets the label coordinates.
#
# getNodeCPUConf { node_id }
#	Returns node's CPU scheduling parameters { minp maxp weight }.
#
# setNodeCPUConf { node_id param_list }
#	Sets the node's CPU scheduling parameters.
#
# ifcList { node_id }
#	Returns a list of all interfaces present in a node.
#
# logicalPeerByIfc { node_id ifc }
#	Returns id of the logical node on the other side of the interface.
#
# ifcByPeer { local_node_id peer_node_id }
#	Returns the name of the interface connected to the specified peer 
#       if the peer is on the same canvas, otherwise returns an empty string.
#
# ifcByLogicalPeer { local_node_id peer_node_id }
#	Returns the name of the interface connected to the specified peer.
#	Returns the right interface even if the peer node is on the other
#	canvas.
#
# hasIPv4Addr { node_id }
# hasIPv6Addr { node_id }
#	Returns true if at least one interface has an IPv{4|6} address
#	configured, otherwise returns false.
#
# removeNode { node_id }
#	Removes the specified node as well as all the links that bind 
#       that node to any other node.
#
# newIfc { ifc_type node_id }
#	Returns the first available name for a new interface of the 
#       specified type.
#
# All of the above functions are independent to any Tk objects. This means
# they can be used for implementing tasks external to GUI, so inside the
# GUI any updating of related Tk objects (such as text labels etc.) will
# have to be implemented by additional Tk code.
#
# Additionally, an alternative configuration can be specified in 
# "custom-config" section.
#
# getCustomEnabled { node }
#
# setCustomEnabled { node state }
#
# getCustomConfigSelected { node }
#
# setCustomConfigSelected { node conf }
#
# getCustomConfig { node id }
#
# setCustomConfig { node id cmd config }
#
# removeCustomConfig { node id }
#
# getCustomConfigCommand { node id }
#
# getCustomConfigIDs { node }
#
#****

#****f* nodecfg.tcl/typemodel
# NAME
#   typemodel -- find node's type and routing model 
# SYNOPSIS
#   set typemod [typemodel $node]
# FUNCTION
#   For input node this procedure returns the node's type and routing model
#   (if exists) 
# INPUTS
#   * node -- node id
# RESULT
#   * typemod -- returns node's type and routing model in form type.model
#****
proc typemodel { node_id } {
    set type [getNodeType $node_id]
    set model [getNodeModel $node_id]
    if { $model != {} } {
	return $type.$model
    } else {
	return $type
    }
}

proc getNodeDir { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node_dir [getNodeCustomImage $node]
    if { $node_dir == "" } {
	set node_dir [getVrootDir]/$eid/$node
    }

    return $node_dir
}

#****f* nodecfg.tcl/getCustomEnabled
# NAME
#   getCustomEnabled -- get custom configuration enabled state 
# SYNOPSIS
#   set enabled [getCustomEnabled $node]
# FUNCTION
#   For input node this procedure returns true if custom configuration is
#   enabled for the specified node. 
# INPUTS
#   * node -- node id
# RESULT
#   * enabled -- returns true if custom configuration is enabled 
#****
proc getCustomEnabled { node_id } {
    return [cfgGet "nodes" $node_id "custom_enabled"]
}

#****f* nodecfg.tcl/setCustomEnabled
# NAME
#   setCustomEnabled -- set custom configuration enabled state 
# SYNOPSIS
#   setCustomEnabled $node $enabled
# FUNCTION
#   For input node this procedure enables or disables custom configuration.
# INPUTS
#   * node -- node id
#   * enabled -- true if enabling custom configuration, false if disabling 
#****
proc setCustomEnabled { node_id state } {
    cfgSet "nodes" $node_id "custom_enabled" $state
}

#****f* nodecfg.tcl/getCustomConfigSelected
# NAME
#   getCustomConfigSelected -- get default custom configuration
# SYNOPSIS
#   getCustomConfigSelected $node
# FUNCTION
#   For input node this procedure returns ID of a default configuration
# INPUTS
#   * node -- node id
# RESULT
#   * ID -- returns default custom configuration ID
#****
proc getCustomConfigSelected { node_id } {
    return [cfgGet "nodes" $node_id "custom_selected"]
}

#****f* nodecfg.tcl/setCustomConfigSelected
# NAME
#   setCustomConfigSelected -- set default custom configuration
# SYNOPSIS
#   setCustomConfigSelected $node
# FUNCTION
#   For input node this procedure sets ID of a default configuration
# INPUTS
#   * node -- node id
#   * conf -- custom-config id
#****
proc setCustomConfigSelected { node_id state } {
    cfgSet "nodes" $node_id "custom_selected" $state
}

#****f* nodecfg.tcl/getCustomConfig
# NAME
#   getCustomConfig -- get custom configuration
# SYNOPSIS
#   getCustomConfig $node $id
# FUNCTION
#   For input node and configuration ID this procedure returns custom
#   configuration.
# INPUTS
#   * node -- node id
#   * id -- configuration id
# RESULT
#   * customConfig -- returns custom configuration
#****
proc getCustomConfig { node_id cfg_id } {
    return [cfgGet "nodes" $node_id "custom_configs" $cfg_id "custom_config"]
}

#****f* nodecfg.tcl/setCustomConfig
# NAME
#   setCustomConfig -- set custom configuration
# SYNOPSIS
#   setCustomConfig $node $id $cmd $config
# FUNCTION
#   For input node this procedure sets custom configuration section in input
#   node.
# INPUTS
#   * node -- node id
#   * id -- custom-config id
#   * cmd -- custom command
#   * config -- custom configuration section
#****
proc setCustomConfig { node_id cfg_id cmd config } {
    cfgSet "nodes" $node_id "custom_configs" $cfg_id "custom_command" $cmd
    cfgSet "nodes" $node_id "custom_configs" $cfg_id "custom_config" $config
}

#****f* nodecfg.tcl/removeCustomConfig
# NAME
#   removeCustomConfig -- remove custom configuration 
# SYNOPSIS
#   removeCustomConfig $node $id
# FUNCTION
#   For input node and configuration ID this procedure removes custom
#   configuration from node.
# INPUTS
#   * node -- node id
#   * id -- configuration id
#****
proc removeCustomConfig { node cfg_id } {
    cfgUnset "nodes" $node_id "custom_configs" $cfg_id
}

#****f* nodecfg.tcl/getCustomConfigCommand
# NAME
#   getCustomConfigCommand -- get custom configuration boot command
# SYNOPSIS
#   getCustomConfigCommand $node $id
# FUNCTION
#   For input node and configuration ID this procedure returns custom
#   configuration boot command.
# INPUTS
#   * node -- node id
#   * id -- configuration id
# RESULT
#   * customCmd -- returns custom configuration boot command
#****
proc getCustomConfigCommand { node_id cfg_id } {
    return [cfgGet "nodes" $node_id "custom_configs" $cfg_id "custom_command"]
}

#****f* nodecfg.tcl/getCustomConfigIDs
# NAME
#   getCustomConfigIDs -- get custom configuration IDs
# SYNOPSIS
#   getCustomConfigIDs $node
# FUNCTION
#   For input node this procedure returns all custom configuration IDs.
# INPUTS
#   * node -- node id
# RESULT
#   * IDs -- returns custom configuration IDs
#****
proc getCustomConfigIDs { node_id } {
    return [dict keys [cfgGet "nodes" $node_id "custom_configs"]]
}

#****f* nodecfg.tcl/netconfFetchSection
# NAME
#   netconfFetchSection -- fetch the network configuration section 
# SYNOPSIS
#   set section [netconfFetchSection $node $sectionhead]
# FUNCTION
#   Returns a section of a network part of a configuration file starting with
#   the $sectionhead line, and ending with the first occurrence of the "!"
#   sign.
# INPUTS
#   * node -- node id
#   * sectionhead -- represents the first line of the section in 
#     network-config part of the configuration file
# RESULT
#   * section -- returns a part of the configuration file between sectionhead
#     and "!"
#****
proc netconfFetchSection { node sectionhead } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set cfgmode global
    set section {}
    set netconf [lindex [lsearch -inline [set $node] "network-config *"] 1]
    foreach line $netconf {
	if { $cfgmode == "section" } {
	    if { "$line" == "!" } {
		return $section
	    }
	    lappend section "$line"
	    continue
	}
	if { "$line" == "$sectionhead" } {
	    set cfgmode section
	}
    }
}

#****f* nodecfg.tcl/netconfClearSection
# NAME
#   netconfClearSection -- clear the section from a network-config part
# SYNOPSIS
#   netconfClearSection $node $sectionhead
# FUNCTION
#   Removes the appropriate section from the network part of the
#   configuration.
# INPUTS
#   * node -- node id
#   * sectionhead -- represents the first line of the section that is to be
#     removed from network-config part of the configuration.
#****
proc netconfClearSection { node sectionhead } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set i [lsearch [set $node] "network-config *"]
    set netconf [lindex [lindex [set $node] $i] 1]
    set lnum_beg -1
    set lnum_end 0
    foreach line $netconf {
	if { $lnum_beg == -1 && "$line" == "$sectionhead" } {
	    set lnum_beg $lnum_end
	}
	if { $lnum_beg > -1 && "$line" == "!" } {
	    set netconf [lreplace $netconf $lnum_beg $lnum_end]
	    set $node [lreplace [set $node] $i $i \
		[list network-config $netconf]]
	    return
	}
	incr lnum_end
    }
}

#****f* nodecfg.tcl/netconfInsertSection
# NAME
#   netconfInsertSection -- Insert the section to a network-config
#   part of configuration
# SYNOPSIS
#   netconfInsertSection $node $section
# FUNCTION
#   Inserts a section in the configuration. Sections beginning with the
#   "interface" keyword are inserted at the head of the configuration, and all
#   other sequences are simply appended to the configuration tail.
# INPUTS
#   * node -- the node id of the node whose config section is inserted
#   * section -- represents the section that is being inserted. If there was a
#     section in network configuration with the same section head, it is lost.
#****
proc netconfInsertSection { node section } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set sectionhead [lindex $section 0]
    netconfClearSection $node $sectionhead
    set i [lsearch [set $node] "network-config *"]
    set netconf [lindex [lindex [set $node] $i] 1]
    set lnum_beg end
    if { "[lindex $sectionhead 0]" == "interface" } {
	set lnum [lsearch $netconf "hostname *"]
	if { $lnum >= 0 } {
	    set lnum_beg [expr $lnum + 2]
	}
    } elseif { "[lindex $sectionhead 0]" == "hostname" } {
	set lnum_beg 0
    }
    if { "[lindex $section end]" != "!" } {
	lappend section "!"
    }
    foreach line $section {
	set netconf [linsert $netconf $lnum_beg $line]
	if { $lnum_beg != "end" } {
	    incr lnum_beg
	}
    }
    set $node [lreplace [set $node] $i $i [list network-config $netconf]]
}

#****f* nodecfg.tcl/getIfcOperState
# NAME
#   getIfcOperState -- get interface operating state
# SYNOPSIS
#   set state [getIfcOperState $node $ifc]
# FUNCTION
#   Returns the operating state of the specified interface. It can be "up" or
#   "down".
# INPUTS
#   * node -- node id
#   * ifc -- the interface that is up or down
# RESULT
#   * state -- the operating state of the interface, can be either "up" or
#     "down".
#****
proc getIfcOperState { node_id iface } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    set group "ifaces"
    if { $iface in [dict keys [cfgGet "nodes" $node_id "logifaces"]] } {
	set group "logifaces"
    }

    return [getWithDefault "up" $dict_cfg "nodes" $node_id $group $iface "oper_state"]
}

#****f* nodecfg.tcl/setIfcOperState
# NAME
#   setIfcOperState -- set interface operating state
# SYNOPSIS
#   setIfcOperState $node $ifc
# FUNCTION
#   Sets the operating state of the specified interface. It can be set to "up"
#   or "down".
# INPUTS
#   * node -- node id
#   * ifc -- interface
#   * state -- new operating state of the interface, can be either "up" or
#     "down"
#****
proc setIfcOperState { node_id iface state } {
    set group "ifaces"
    if { $iface in [dict keys [cfgGet "nodes" $node_id "logifaces"]] } {
	set group "logifaces"
    }

    cfgSet "nodes" $node_id $group $iface "oper_state" $state
}

#****f* nodecfg.tcl/getIfcNatState
# NAME
#   getIfcNatState -- get interface NAT state
# SYNOPSIS
#   set state [getIfcNatState $node $ifc]
# FUNCTION
#   Returns the NAT state of the specified interface. It can be "on" or "off".
# INPUTS
#   * node -- node id
#   * ifc -- the interface that is used for NAT
# RESULT
#   * state -- the NAT state of the interface, can be either "on" or "off"
#****
proc getIfcNatState { node_id iface } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    set group "ifaces"
    if { $iface in [dict keys [cfgGet "nodes" $node_id "logifaces"]] } {
	set group "logifaces"
    }

    return [getWithDefault "off" $dict_cfg "nodes" $node_id $group $iface "nat_state"]
}

#****f* nodecfg.tcl/setIfcNatState
# NAME
#   setIfcNatState -- set interface NAT state
# SYNOPSIS
#   setIfcNatState $node $ifc
# FUNCTION
#   Sets the NAT state of the specified interface. It can be set to "on" or "off"
# INPUTS
#   * node -- node id
#   * ifc -- interface
#   * state -- new NAT state of the interface, can be either "on" or "off"
#****
proc setIfcNatState { node_id iface state } {
    set group "ifaces"
    if { $iface in [dict keys [cfgGet "nodes" $node_id "logifaces"]] } {
	set group "logifaces"
    }

    cfgSet "nodes" $node_id $group $iface "nat_state" $state
}

#****f* nodecfg.tcl/getIfcDirect
# NAME
#   getIfcDirect -- get interface queuing discipline
# SYNOPSIS
#   set direction [getIfcDirect $node $ifc]
# FUNCTION
#   Returns the direction of the specified interface. It can be set to 
#   "internal" or "external".
# INPUTS
#   * node -- represents the node id of the node whose interface's queuing
#     discipline is checked.
#   * ifc -- The interface name.
# RESULT
#   * direction -- the direction of the interface, can be either "internal" or
#     "external".
#****
proc getIfcDirect { node_id iface } {
    return [cfgGet "nodes" $node_id "ifaces" $iface "direction"]
}

#****f* nodecfg.tcl/setIfcDirect
# NAME
#   setIfcDirect -- set interface direction
# SYNOPSIS
#   setIfcDirect $node $ifc $direct
# FUNCTION
#   Sets the direction of the specified interface. It can be set to "internal"
#   or "external".
# INPUTS
#   * node -- node id
#   * ifc -- interface
#   * direct -- new direction of the interface, can be either "internal" or
#     "external"
#****
proc getIfcDirect { node_id iface direction } {
    cfgSet "nodes" $node_id "ifaces" $iface "direction" $direction
}

#****f* nodecfg.tcl/getIfcQDisc
# NAME
#   getIfcQDisc -- get interface queuing discipline
# SYNOPSIS
#   set qdisc [getIfcQDisc $node $ifc]
# FUNCTION
#   Returns one of the supported queuing discipline ("FIFO", "WFQ" or "DRR")
#   that is active for the specified interface.
# INPUTS
#   * node -- represents the node id of the node whose interface's queuing
#     discipline is checked.
#   * ifc -- The interface name.
# RESULT
#   * qdisc -- returns queuing discipline of the interface, can be "FIFO",
#     "WFQ" or "DRR".
#****
proc getIfcQDisc { node_id iface } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    set group "ifaces"
    if { $iface in [dict keys [cfgGet "nodes" $node_id "logifaces"]] } {
	set group "logifaces"
    }

    return [getWithDefault "FIFO" $dict_cfg "nodes" $node_id $group $iface "ifc_qdisc"]
}

#****f* nodecfg.tcl/setIfcQDisc
# NAME
#   setIfcQDisc -- set interface queueing discipline
# SYNOPSIS
#   setIfcQDisc $node $ifc $qdisc
# FUNCTION
#   Sets the new queuing discipline for the interface. Implicit default is 
#   FIFO.
# INPUTS
#   * node -- represents the node id of the node whose interface's queuing
#     discipline is set.
#   * ifc -- interface name.
#   * qdisc -- queuing discipline of the interface, can be "FIFO", "WFQ" or
#     "DRR".
#****
proc setIfcQDisc { node_id iface qdisc } {
    set group "ifaces"
    if { $iface in [dict keys [cfgGet "nodes" $node_id "logifaces"]] } {
	set group "logifaces"
    }

    cfgSet "nodes" $node_id $group $iface "ifc_qdisc" $qdisc
}

#****f* nodecfg.tcl/getIfcQDrop
# NAME
#   getIfcQDrop -- get interface queue dropping policy
# SYNOPSIS
#   set qdrop [getIfcQDrop $node $ifc]
# FUNCTION
#   Returns one of the supported queue dropping policies ("drop-tail" or
#   "drop-head") that is active for the specified interface.
# INPUTS
#   * node -- represents the node id of the node whose interface's queue
#     dropping policy is checked.
#   * ifc -- The interface name.
# RESULT
#   * qdrop -- returns queue dropping policy of the interface, can be
#     "drop-tail" or "drop-head".
#****
proc getIfcQDrop { node_id iface } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    set group "ifaces"
    if { $iface in [dict keys [cfgGet "nodes" $node_id "logifaces"]] } {
	set group "logifaces"
    }

    return [getWithDefault "drop-tail" $dict_cfg "nodes" $node_id $group $iface "ifc_qdrop"]
}

#****f* nodecfg.tcl/setIfcQDrop
# NAME
#   setIfcQDrop -- set interface queue dropping policy
# SYNOPSIS
#   setIfcQDrop $node $ifc $qdrop
# FUNCTION
#   Sets the new queuing discipline. Implicit default is "drop-tail".
# INPUTS
#   * node -- represents the node id of the node whose interface's queue
#     droping policie is set.
#   * ifc -- interface name.
#   * qdrop -- new queue dropping policy of the interface, can be "drop-tail"
#     or "drop-head".
#****
proc setIfcQDrop { node_id iface qdrop } {
    set group "ifaces"
    if { $iface in [dict keys [cfgGet "nodes" $node_id "logifaces"]] } {
	set group "logifaces"
    }

    cfgSet "nodes" $node_id $group $iface "ifc_qdrop" $qdrop
}

#****f* nodecfg.tcl/getIfcQLen
# NAME
#   getIfcQLen -- get interface queue length
# SYNOPSIS
#   set qlen [getIfcQLen $node $ifc]
# FUNCTION
#   Returns the queue length limit in number of packets.
# INPUTS
#   * node -- represents the node id of the node whose interface's queue
#     length is checked.
#   * ifc -- interface name.
# RESULT
#   * qlen -- queue length limit represented in number of packets.
#****
proc getIfcQLen { node_id iface } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    set group "ifaces"
    if { $iface in [dict keys [cfgGet "nodes" $node_id "logifaces"]] } {
	set group "logifaces"
    }

    return [getWithDefault 50 $dict_cfg "nodes" $node_id $group $iface "queue_len"]
}

#****f* nodecfg.tcl/setIfcQLen
# NAME
#   setIfcQLen -- set interface queue length
# SYNOPSIS
#   setIfcQLen $node $ifc $len
# FUNCTION
#   Sets the queue length limit.
# INPUTS
#   * node -- represents the node id of the node whose interface's queue
#     length is set.
#   * ifc -- interface name.
#   * qlen -- queue length limit represented in number of packets.
#****
proc setIfcQLen { node_id iface len } {
    set group "ifaces"
    if { $iface in [dict keys [cfgGet "nodes" $node_id "logifaces"]] } {
	set group "logifaces"
    }

    cfgSet "nodes" $node_id $group $iface "queue_len" $len
}

#****f* nodecfg.tcl/getIfcMTU
# NAME
#   getIfcMTU -- get interface MTU size.
# SYNOPSIS
#   set mtu [getIfcMTU $node $ifc]
# FUNCTION
#   Returns the configured MTU, or a default MTU.
# INPUTS
#   * node -- represents the node id of the node whose interface's MTU is
#     checked.
#   * ifc -- interface name.
# RESULT
#   * mtu -- maximum transmission unit of the packet, represented in bytes.
#****
proc getIfcMTU { node_id iface } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    set default_mtu 1500
    set group "ifaces"
    if { $iface in [dict keys [cfgGet "nodes" $node_id "logifaces"]] } {
	set group "logifaces"
	switch -exact [getLogIfcType $node_id $iface] {
	    lo { set default_mtu 16384 }
	    se { set default_mtu 2044 }
	}
    }

    return [getWithDefault $default_mtu $dict_cfg "nodes" $node_id $group $iface "mtu"]
}

#****f* nodecfg.tcl/setIfcMTU
# NAME
#   setIfcMTU -- set interface MTU size.
# SYNOPSIS
#   setIfcMTU $node $ifc $mtu
# FUNCTION
#   Sets the new MTU. Zero MTU value denotes the default MTU.
# INPUTS
#   * node -- represents the node id of the node whose interface's MTU is set.
#   * ifc -- interface name.
#   * mtu -- maximum transmission unit of a packet, represented in bytes.
#****
proc setIfcMTU { node_id iface mtu } {
    set group "ifaces"
    if { $iface in [dict keys [cfgGet "nodes" $node_id "logifaces"]] } {
	set group "logifaces"
    }

    cfgSet "nodes" $node_id $group $iface "mtu" $mtu
}

#****f* nodecfg.tcl/getIfcMACaddr
# NAME
#   getIfcMACaddr -- get interface MAC address.
# SYNOPSIS
#   set addr [getIfcMACaddr $node $ifc]
# FUNCTION
#   Returns the MAC address assigned to the specified interface.
# INPUTS
#   * node -- node id
#   * ifc -- interface name.
# RESULT
#   * addr -- The MAC address assigned to the specified interface.
#****
proc getIfcMACaddr { node_id iface } {
    return [cfgGet "nodes" $node_id "ifaces" $iface "mac"]
}

#****f* nodecfg.tcl/setIfcMACaddr
# NAME
#   setIfcMACaddr -- set interface MAC address.
# SYNOPSIS
#   setIfcMACaddr $node $ifc $addr
# FUNCTION
#   Sets a new MAC address on an interface. The correctness of the MAC address
#   format is not checked / enforced.
# INPUTS
#   * node -- the node id of the node whose interface's MAC address is set.
#   * ifc -- interface name.
#   * addr -- new MAC address.
#****
proc setIfcMACaddr { node_id iface addr } {
    cfgSet "nodes" $node_id "ifaces" $iface "mac" $addr
}

#****f* nodecfg.tcl/getIfcIPv4addr
# NAME
#   getIfcIPv4addr -- get interface first IPv4 address.
# SYNOPSIS
#   set addr [getIfcIPv4addr $node $ifc]
# FUNCTION
#   Returns the first IPv4 address assigned to the specified interface.
# INPUTS
#   * node -- node id
#   * ifc -- interface name.
# RESULT
#   * addr -- first IPv4 address on the interface
#    
#****
proc getIfcIPv4addr { node_id iface } {
    return [lindex [getIfcIPv4addrs $node_id $iface] 0]
}

#****f* nodecfg.tcl/getIfcIPv4addrs
# NAME
#   getIfcIPv4addrs -- get interface IPv4 addresses.
# SYNOPSIS
#   set addrs [getIfcIPv4addrs $node $ifc]
# FUNCTION
#   Returns the list of IPv4 addresses assigned to the specified interface.
# INPUTS
#   * node -- node id
#   * ifc -- interface name.
# RESULT
#   * addrList -- A list of all the IPv4 addresses assigned to the specified
#     interface.
#****
proc getIfcIPv4addrs { node_id iface } {
    set group "ifaces"
    if { $iface in [dict keys [cfgGet "nodes" $node_id "logifaces"]] } {
	set group "logifaces"
    }

    return [cfgGet "nodes" $node_id $group $iface "ipv4_addrs"]
}

#****f* nodecfg.tcl/setIfcIPv4addrs
# NAME
#   setIfcIPv4addrs -- set interface IPv4 addresses.
# SYNOPSIS
#   setIfcIPv4addrs $node $ifc $addrs
# FUNCTION
#   Sets new IPv4 address(es) on an interface. The correctness of the IP
#   address format is not checked / enforced.
# INPUTS
#   * node -- the node id of the node whose interface's IPv4 address is set.
#   * ifc -- interface name.
#   * addrs -- new IPv4 addresses.
#****
proc setIfcIPv4addrs { node_id iface addrs } {
    set group "ifaces"
    if { $iface in [dict keys [cfgGet "nodes" $node_id "logifaces"]] } {
	set group "logifaces"
    }

    cfgSet "nodes" $node_id $group $iface "ipv4_addrs" $addrs
}

#****f* nodecfg.tcl/getIfcType
# NAME
#   getIfcType -- get logical interface type
# SYNOPSIS
#   getIfcType $node $ifc
# FUNCTION
#   Returns logical interface type from a node.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#****
proc getIfcType { node_id iface } {
    set group "ifaces"
    if { $iface in [dict keys [cfgGet "nodes" $node_id "logifaces"]] } {
	set group "logifaces"
    }

    return [cfgGet "nodes" $node_id $group $iface "type"]
}

#****f* nodecfg.tcl/setIfcType
# NAME
#   setIfcType -- set logical interface type
# SYNOPSIS
#   setIfcType $node $ifc $type
# FUNCTION
#   Sets node's logical interface type.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#   * type -- interface type
#****
proc setIfcType { node_id iface type } {
    set group "ifaces"
    if { $iface in [dict keys [cfgGet "nodes" $node_id "logifaces"]] } {
	set group "logifaces"
    }

    cfgSet "nodes" $node_id $group $iface "type" $type
}

#****f* nodecfg.tcl/getLogIfcType
# NAME
#   getLogIfcType -- get logical interface type
# SYNOPSIS
#   getLogIfcType $node $ifc
# FUNCTION
#   Returns logical interface type from a node.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#****
proc getLogIfcType { node_id iface } {
    return [cfgGet "nodes" $node_id "logifaces" $iface "type"]
}

#****f* nodecfg.tcl/setLogIfcType
# NAME
#   setLogIfcType -- set logical interface type
# SYNOPSIS
#   setLogIfcType $node $ifc $type
# FUNCTION
#   Sets node's logical interface type.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#   * type -- interface type
#****
proc setLogIfcType { node_id iface type } {
    cfgSet "nodes" $node_id "logifaces" $iface "type" $type
}

#****f* nodecfg.tcl/getIfcStolenIfc
# NAME
#   getIfcStolenIfc -- get logical interface type
# SYNOPSIS
#   getIfcStolenIfc $node $ifc
# FUNCTION
#   Returns logical interface type from a node.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#****
proc getIfcStolenIfc { node_id iface } {
    return [cfgGet "nodes" $node_id "ifaces" $iface "stolen_iface"]
}

#****f* nodecfg.tcl/setIfcStolenIfc
# NAME
#   setIfcStolenIfc -- set interface stolen interface
# SYNOPSIS
#   setIfcStolenIfc $node $iface $stolen_iface
# FUNCTION
#   Sets node's interface stolen stolen interface.
# INPUTS
#   * node -- node id
#   * iface -- interface name
#   * stolen_iface -- stolen interface
#****
proc setIfcStolenIfc { node_id iface stolen_iface } {
    cfgSet "nodes" $node_id "ifaces" $iface "stolen_iface" $stolen_iface
}

#****f* nodecfg.tcl/getNodeStolenIfaces
# NAME
#   getNodeStolenIfaces -- set node name.
# SYNOPSIS
#   getNodeStolenIfaces $node $name
# FUNCTION
#   Sets node's logical name.
# INPUTS
#   * node -- node id
#   * name -- logical name of the node
#****
proc getNodeStolenIfaces { node_id } {
    set external_ifaces {}
    foreach {iface iface_cfg} [cfgGet "nodes" $node_id "ifaces"] {
	if { [dictGet $iface_cfg "type"] == "stolen" } {
	    set stolen_iface [dictGet $iface_cfg "stolen_iface"]
	    lappend external_ifaces "$iface $stolen_iface"
	}
    }

    return $external_ifaces
}

#****f* nodecfg.tcl/getIfcIPv6addr
# NAME
#   getIfcIPv6addr -- get interface first IPv6 address.
# SYNOPSIS
#   set addr [getIfcIPv6addr $node $ifc]
# FUNCTION
#   Returns the first IPv6 address assigned to the specified interface.
# INPUTS
#   * node -- node id
#   * ifc -- interface name.
# RESULT
#   * addr -- first IPv6 address on the interface
#
#****
proc getIfcIPv6addr { node_id iface } {
    return [lindex [getIfcIPv6addrs $node_id $iface] 0]
}

#****f* nodecfg.tcl/getIfcIPv6addrs
# NAME
#   getIfcIPv6addrs -- get interface IPv6 addresses.
# SYNOPSIS
#   set addrs [getIfcIPv6addrs $node $ifc]
# FUNCTION
#   Returns the list of IPv6 addresses assigned to the specified interface.
# INPUTS
#   * node -- the node id of the node whose interface's IPv6 addresses are returned.
#   * ifc -- interface name.
# RESULT
#   * addrList -- A list of all the IPv6 addresses assigned to the specified
#     interface.
#****
proc getIfcIPv6addrs { node_id iface } {
    set group "ifaces"
    if { $iface in [dict keys [cfgGet "nodes" $node_id "logifaces"]] } {
	set group "logifaces"
    }

    return [cfgGet "nodes" $node_id $group $iface "ipv6_addrs"]
}

#****f* nodecfg.tcl/setIfcIPv6addrs
# NAME
#   setIfcIPv6addrs -- set interface IPv6 addresses.
# SYNOPSIS
#   setIfcIPv6addrs $node $ifc $addrs
# FUNCTION
#   Sets new IPv6 address(es) on an interface. The correctness of the IP
#   address format is not checked / enforced.
# INPUTS
#   * node -- the node id of the node whose interface's IPv6 address is set.
#   * ifc -- interface name.
#   * addrs -- new IPv6 addresses.
#****
proc setIfcIPv6addrs { node_id iface addrs } {
    set group "ifaces"
    if { $iface in [dict keys [cfgGet "nodes" $node_id "logifaces"]] } {
	set group "logifaces"
    }

    cfgSet "nodes" $node_id $group $iface "ipv6_addrs" $addrs
}

proc getIfcPeer { node_id iface } {
    return [cfgGet "nodes" $node_id "ifaces" $iface "peer"]
}

proc setIfcPeer { node_id iface peer } {
    cfgSet "nodes" $node_id "ifaces" $iface "peer" $peer
}

#****f* nodecfg.tcl/getIfcLinkLocalIPv6addr
# NAME
#   getIfcLinkLocalIPv6addr -- get interface link-local IPv6 address.
# SYNOPSIS
#   set addr [getIfcLinkLocalIPv6addr $node $ifc]
# FUNCTION
#   Returns link-local IPv6 addresses that is calculated from the interface
#   MAC address. This can be done only for physical interfaces, or interfaces
#   with a MAC address assigned.
# INPUTS
#   * node -- the node id of the node whose link-local IPv6 address is returned.
#   * ifc -- interface name.
# RESULT
#   * addr -- The link-local IPv6 address that will be assigned to the
#     specified interface.
#****
proc getIfcLinkLocalIPv6addr { node_id iface } {
    if { [isIfcLogical $node_id $iface] } {
	return ""
    }

    set mac [getIfcMACaddr $node_id $iface]

    set bytes [split $mac :]
    set bytes [linsert $bytes 3 fe]
    set bytes [linsert $bytes 3 ff]

    set first [expr 0x[lindex $bytes 0]]
    set xored [expr $first^2]
    set result [format %02x $xored]

    set bytes [lreplace $bytes 0 0 $result]

    set i 0
    lappend final fe80::
    foreach b $bytes {
	lappend final $b
	if { [expr $i%2] == 1 && $i < 7 } {
	    lappend final :
	}
	incr i
    }
    lappend final /64

    return [ip::normalize [join $final ""]]
}

#****f* nodecfg.tcl/getDefaultGateways
# NAME
#   getDefaultGateways -- get default IPv4/IPv6 gateways.
# SYNOPSIS
#   lassign [getDefaultGateways $node $subnet_gws $nodes_l2data] \
#     my_gws subnets_and_gws
# FUNCTION
#   Returns a list of all default IPv4/IPv6 gateways for the subnets in which
#   this node belongs as a {getNodeType|gateway4|gateway6} values. Additionally,
#   it refreshes newly discovered gateways and subnet members to the existing
#   $subnet_gws list and $nodes_l2data dictionary.
# INPUTS
#   * node -- node id
#   * subnet_gws -- already known {getNodeType|gateway4|gateway6} values
#   * nodes_l2data -- a dictionary of already known {node ifc subnet_idx}
#   triplets in this subnet
# RESULT
#   * my_gws -- list of all possible default gateways for the specified node
#   * subnet_gws -- refreshed {getNodeType|gateway4|gateway6} values
#   * nodes_l2data -- refreshed dictionary of {node ifc subnet_idx} triplets in
#   this subnet
#****
proc getDefaultGateways { node_id subnet_gws nodes_l2data } {
    set all_ifc [ifcList $node_id]
    if { [llength $all_ifc] == 0 } {
	return [list {} {} {}]
    }

    # go through all interfaces and collect data for each subnet
    foreach ifc $all_ifc {
	if { [dict exists $nodes_l2data $node_id $ifc] } {
	    continue
	}

	# add new subnet at the end of the list
	set subnet_idx [llength $subnet_gws]
	set peer_node [logicalPeerByIfc $node_id $ifc]
	set peer_ifc [ifcByLogicalPeer $peer_node $node_id]
	lassign [getSubnetData $peer_node $peer_ifc \
	  $subnet_gws $nodes_l2data $subnet_idx] \
	  subnet_gws nodes_l2data
    }

    # merge all gateways values and return
    set my_gws {}
    foreach subnet_idx [lsort -unique [dict values [dict get $nodes_l2data $node_id]]] {
	set my_gws [concat $my_gws [lindex $subnet_gws $subnet_idx]]
    }

    return [list $my_gws $subnet_gws $nodes_l2data]
}

#****f* nodecfg.tcl/getSubnetData
# NAME
#   getSubnetData -- get subnet members and its IPv4/IPv6 gateways.
# SYNOPSIS
#   lassign [getSubnetData $this_node $this_ifc \
#     $subnet_gws $nodes_l2data $subnet_idx] \
#     subnet_gws nodes_l2data
# FUNCTION
#   Called when checking L2 network for routers/extnats in order to get all
#   default gateways. Returns all possible default IPv4/IPv6 gateways in this
#   LAN appended to the subnet_gws list and updates the members of this subnet
#   as {nodes ifc subnet_idx} triplets in the nodes_l2data dictionary.
# INPUTS
#   * this_node -- node id
#   * this_ifc -- node interface
#   * subnet_gws -- already known {getNodeType|gateway4|gateway6} values
#   * nodes_l2data -- a dictionary of already known {node ifc subnet_idx}
#   triplets in this subnet
# RESULT
#   * subnet_gws -- refreshed {getNodeType|gateway4|gateway6} values
#   * nodes_l2data -- refreshed dictionary of {node ifc subnet_idx} triplets in
#   this subnet
#****
proc getSubnetData { this_node_id this_ifc subnet_gws nodes_l2data subnet_idx } {
    set my_gws [lindex $subnet_gws $subnet_idx]

    if { [dict exists $nodes_l2data $this_node_id $this_ifc] } {
	# this node/ifc is already a part of this subnet
	set subnet_idx [dict get $nodes_l2data $this_node_id $this_ifc]
	return [list $subnet_gws $nodes_l2data]
    }

    dict set nodes_l2data $this_node_id $this_ifc $subnet_idx

    if { [[typemodel $this_node_id].layer] == "NETWORK" } {
	if { [getNodeType $this_node_id] in "router extnat" } {
	    # this node is a router/extnat, add our IP addresses to lists
	    set gw4 [lindex [split [getIfcIPv4addr $this_node_id $this_ifc] /] 0]
	    set gw6 [lindex [split [getIfcIPv6addr $this_node_id $this_ifc] /] 0]
	    lappend my_gws [getNodeType $this_node_id]|$gw4|$gw6
	    lset subnet_gws $subnet_idx $my_gws
	}

	# first, get this node/ifc peer's subnet data in case it is an L2 node
	# and we're not yet gone through it
	set peer_node [logicalPeerByIfc $this_node_id $this_ifc]
	set peer_ifc [ifcByLogicalPeer $peer_node $this_node_id]
	lassign [getSubnetData $peer_node $peer_ifc \
	  $subnet_gws $nodes_l2data $subnet_idx] \
	  subnet_gws nodes_l2data

	# this node is done, do nothing else
	return [list $subnet_gws $nodes_l2data]
    }

    # this node is an L2 node
    # - collect data from all interfaces
    foreach ifc [ifcList $this_node_id] {
	dict set nodes_l2data $this_node_id $ifc $subnet_idx

	set peer_node [logicalPeerByIfc $this_node_id $ifc]
	set peer_ifc [ifcByLogicalPeer $peer_node $this_node_id]
	lassign [getSubnetData $peer_node $peer_ifc \
	  $subnet_gws $nodes_l2data $subnet_idx] \
	  subnet_gws nodes_l2data
    }

    return [list $subnet_gws $nodes_l2data]
}

#****f* nodecfg.tcl/getStatIPv4routes
# NAME
#   getStatIPv4routes -- get static IPv4 routes.
# SYNOPSIS
#   set routes [getStatIPv4routes $node]
# FUNCTION
#   Returns a list of all static IPv4 routes as a list of
#   {destination gateway {metric}} pairs.
# INPUTS
#   * node -- node id
# RESULT
#   * routes -- list of all static routes defined for the specified node
#****
proc getStatIPv4routes { node_id } {
    return [cfgGet "nodes" $node_id "croutes4"]
}

#****f* nodecfg.tcl/setStatIPv4routes
# NAME
#   setStatIPv4routes -- set static IPv4 routes.
# SYNOPSIS
#   setStatIPv4routes $node $routes
# FUNCTION
#   Replace all current static route entries with a new one, in form of a list
#   of {destination gateway {metric}} pairs.
# INPUTS
#   * node -- the node id of the node whose static routes are set.
#   * routes -- list of all static routes defined for the specified node
#****
proc setStatIPv4routes { node_id routes } {
    cfgSet "nodes" $node_id "croutes4" $routes
}

#****f* nodecfg.tcl/getDefaultIPv4routes
# NAME
#   getDefaultIPv4routes -- get auto default IPv4 routes.
# SYNOPSIS
#   set routes [getDefaultIPv4routes $node]
# FUNCTION
#   Returns a list of all auto default IPv4 routes as a list of
#   {0.0.0.0/0 gateway} pairs.
# INPUTS
#   * node -- node id
# RESULT
#   * routes -- list of all IPv4 default routes defined for the specified node
#****
proc getDefaultIPv4routes { node_id } {
    return [cfgGet "nodes" $node_id "default_routes4"]
}

#****f* nodecfg.tcl/setDefaultIPv4routes
# NAME
#   setDefaultIPv4routes -- set auto default IPv4 routes.
# SYNOPSIS
#   setDefaultIPv4routes $node $routes
# FUNCTION
#   Replace all current auto default route entries with a new one, in form of a
#   list of {0.0.0.0/0 gateway} pairs.
# INPUTS
#   * node -- the node id of the node whose default routes are set
#   * routes -- list of all IPv4 default routes defined for the specified node
#****
proc setDefaultIPv4routes { node_id routes } {
    cfgSet "nodes" $node_id "default_routes4" $routes
}

#****f* nodecfg.tcl/getDefaultIPv6routes
# NAME
#   getDefaultIPv6routes -- get auto default IPv6 routes.
# SYNOPSIS
#   set routes [getDefaultIPv6routes $node]
# FUNCTION
#   Returns a list of all auto default IPv6 routes as a list of
#   {::/0 gateway} pairs.
# INPUTS
#   * node -- node id
# RESULT
#   * routes -- list of all IPv6 default routes defined for the specified node
#****
proc getDefaultIPv6routes { node_id } {
    return [cfgGet "nodes" $node_id "default_routes6"]
}

#****f* nodecfg.tcl/setDefaultIPv6routes
# NAME
#   setDefaultIPv6routes -- set auto default IPv6 routes.
# SYNOPSIS
#   setDefaultIPv6routes $node $routes
# FUNCTION
#   Replace all current auto default route entries with a new one, in form of a
#   list of {::/0 gateway} pairs.
# INPUTS
#   * node -- the node id of the node whose default routes are set
#   * routes -- list of all IPv6 default routes defined for the specified node
#****
proc setDefaultIPv6routes { node_id routes } {
    cfgSet "nodes" $node_id "default_routes6" $routes
}

#****f* nodecfg.tcl/getStatIPv6routes
# NAME
#   getStatIPv6routes -- get static IPv6 routes.
# SYNOPSIS
#   set routes [getStatIPv6routes $node]
# FUNCTION
#   Returns a list of all static IPv6 routes as a list of
#   {destination gateway {metric}} pairs.
# INPUTS
#   * node -- node id
# RESULT
#   * routes -- list of all static routes defined for the specified node
#****
proc getStatIPv6routes { node_id } {
    return [cfgGet "nodes" $node_id "croutes6"]
}

#****f* nodecfg.tcl/setStatIPv6routes
# NAME
#   setStatIPv4routes -- set static IPv6 routes.
# SYNOPSIS
#   setStatIPv6routes $node $routes
# FUNCTION
#   Replace all current static route entries with a new one, in form of a list
#   of {destination gateway {metric}} pairs.
# INPUTS
#   * node -- node id
#   * routes -- list of all static routes defined for the specified node
#****
proc setStatIPv6routes { node_id routes } {
    cfgSet "nodes" $node_id "croutes6" $routes
}

#****f* nodecfg.tcl/getDefaultRoutesConfig
# NAME
#   getDefaultRoutesConfig -- get node default routes in a configuration format
# SYNOPSIS
#   lassign [getDefaultRoutesConfig $node $gws] routes4 routes6
# FUNCTION
#   Called when translating IMUNES default gateways configuration to node
#   pre-running configuration. Returns IPv4 and IPv6 routes lists.
# INPUTS
#   * node -- node id
#   * gws -- gateway values in the {getNodeType|gateway4|gateway6} format
# RESULT
#   * all_routes4 -- {0.0.0.0/0 gw4} pairs of default IPv4 routes
#   * all_routes6 -- {0.0.0.0/0 gw6} pairs of default IPv6 routes
#****
proc getDefaultRoutesConfig { node_id gws } {
    set all_routes4 {}
    set all_routes6 {}
    foreach route $gws {
	lassign [split $route "|"] route_type gateway4 gateway6
	if { [getNodeType $node_id] == "router" } {
	    if { $route_type == "extnat" } {
		if { "0.0.0.0/0 $gateway4" ni [list "0.0.0.0/0 " $all_routes4] } {
		    lappend all_routes4 "0.0.0.0/0 $gateway4"
		}
		if { "::/0 $gateway6" ni [list "::/0 " $all_routes6] } {
		    lappend all_routes6 "::/0 $gateway6"
		}
	    }
	} else {
	    if { "0.0.0.0/0 $gateway4" ni [list "0.0.0.0/0 " $all_routes4] } {
		lappend all_routes4 "0.0.0.0/0 $gateway4"
	    }
	    if { "::/0 $gateway6" ni [list "::/0 " $all_routes6] } {
		lappend all_routes6 "::/0 $gateway6"
	    }
	}
    }

    return "\"$all_routes4\" \"$all_routes6\""
}

#****f* nodecfg.tcl/getNodeName
# NAME
#   getNodeName -- get node name.
# SYNOPSIS
#   set name [getNodeName $node]
# FUNCTION
#   Returns node's logical name.
# INPUTS
#   * node -- node id
# RESULT
#   * name -- logical name of the node
#****
proc getNodeName { node_id } {
    return [cfgGet "nodes" $node_id "name"]
}

#****f* nodecfg.tcl/setNodeName
# NAME
#   setNodeName -- set node name.
# SYNOPSIS
#   setNodeName $node $name
# FUNCTION
#   Sets node's logical name.
# INPUTS
#   * node -- node id
#   * name -- logical name of the node
#****
proc setNodeName { node_id name } {
    cfgSet "nodes" $node_id "name" $name
}

#****f* nodecfg.tcl/getNodeType
# NAME
#   getNodeType -- get node type.
# SYNOPSIS
#   set type [getNodeType $node]
# FUNCTION
#   Returns node's type.
# INPUTS
#   * node -- node id
# RESULT
#   * type -- type of the node
#****
proc getNodeType { node_id } {
    return [cfgGet "nodes" $node_id "type"]
}

#****f* nodecfg.tcl/getNodeModel
# NAME
#   getNodeModel -- get node routing model.
# SYNOPSIS
#   set model [getNodeModel $node]
# FUNCTION
#   Returns node's optional routing model. Currently supported models are 
#   frr, quagga and static and only nodes of type router have a defined model.
# INPUTS
#   * node -- node id
# RESULT
#   * model -- routing model of the specified node
#****
proc getNodeModel { node_id } {
    return [cfgGet "nodes" $node_id "model"]
}

#****f* nodecfg.tcl/setNodeModel
# NAME
#   setNodeModel -- set node routing model.
# SYNOPSIS
#   setNodeModel $node $model
# FUNCTION
#   Sets an optional routing model to the node. Currently supported models are
#   frr, quagga and static and only nodes of type router have a defined model.
# INPUTS
#   * node -- node id
#   * model -- routing model of the specified node
#****
proc setNodeModel { node_id model } {
    cfgSet "nodes" $node_id "model" $model
}

#****f* nodecfg.tcl/getNodeSnapshot
# NAME
#   getNodeSnapshot -- get node snapshot image name.
# SYNOPSIS
#   set snapshot [getNodeSnapshot $node]
# FUNCTION
#   Returns node's snapshot name.
# INPUTS
#   * node -- node id
# RESULT
#   * snapshot -- snapshot name for the specified node
#****
proc getNodeSnapshot { node_id } {
    return [cfgGet "nodes" $node_id "snapshot"]
}

#****f* nodecfg.tcl/setNodeSnapshot
# NAME
#   setNodeSnapshot -- set node snapshot image name.
# SYNOPSIS
#   setNodeSnapshot $node $snapshot
# FUNCTION
#   Sets node's snapshot name.
# INPUTS
#   * node -- node id
#   * snapshot -- snapshot name for the specified node
#****
proc setNodeSnapshot { node_id snapshot } {
    cfgSet "nodes" $node_id "snapshot" $snapshot
}

#****f* nodecfg.tcl/getStpEnabled
# NAME
#   getStpEnabled -- get STP enabled state 
# SYNOPSIS
#   set enabled [getStpEnabled $node]
# FUNCTION
#   For input node this procedure returns true if STP is enabled
#   for the specified node. 
# INPUTS
#   * node -- node id
# RESULT
#   * enabled -- returns true if STP is enabled
#****
proc getStpEnabled { node_id } {
    return [cfgGet "nodes" $node_id "stp_enabled"]
}

#****f* nodecfg.tcl/setStpEnabled
# NAME
#   setStpEnabled -- set STP enabled state 
# SYNOPSIS
#   setStpEnabled $node $enabled
# FUNCTION
#   For input node this procedure enables or disables STP.
# INPUTS
#   * node -- node id
#   * enabled -- true if enabling STP, false if disabling 
#****
proc setStpEnabled { node_id state } {
    cfgSet "nodes" $node_id "stp_enabled" $state
}

#****f* nodecfg.tcl/getNodeCoords
# NAME
#   getNodeCoords -- get node icon coordinates.
# SYNOPSIS
#   set coords [getNodeCoords $node]
# FUNCTION
#   Returns node's icon coordinates.
# INPUTS
#   * node -- node id
# RESULT
#   * coords -- coordinates of the node's icon in form of {Xcoord Ycoord}
#****
proc getNodeCoords { node_id } {
    return [cfgGet "nodes" $node_id "iconcoords"]
}

#****f* nodecfg.tcl/setNodeCoords
# NAME
#   setNodeCoords -- set node's icon coordinates.
# SYNOPSIS
#   setNodeCoords $node $coords
# FUNCTION
#   Sets node's icon coordinates.
# INPUTS
#   * node -- node id
#   * coords -- coordinates of the node's icon in form of {Xcoord Ycoord}
#****
proc setNodeCoords { node_id coords } {
    foreach c $coords {
	set x [expr round($c)]
	lappend roundcoords $x
    }

    cfgSet "nodes" $node_id "iconcoords" $roundcoords
}

#****f* nodecfg.tcl/getNodeLabelCoords
# NAME
#   getNodeLabelCoords -- get node's label coordinates.
# SYNOPSIS
#   set coords [getNodeLabelCoords $node]
# FUNCTION
#   Returns node's label coordinates.
# INPUTS
#   * node -- node id
# RESULT
#   * coords -- coordinates of the node's label in form of {Xcoord Ycoord}
#****
proc getNodeLabelCoords { node_id } {
    return [cfgGet "nodes" $node_id "labelcoords"]
}

#****f* nodecfg.tcl/setNodeLabelCoords
# NAME
#   setNodeLabelCoords -- set node's label coordinates.
# SYNOPSIS
#   setNodeLabelCoords $node $coords
# FUNCTION
#   Sets node's label coordinates.
# INPUTS
#   * node -- node id
#   * coords -- coordinates of the node's label in form of Xcoord Ycoord
#****
proc setNodeLabelCoords { node_id coords } {
    foreach c $coords {
	set x [expr round($c)]
	lappend roundcoords $x
    }

    cfgSet "nodes" $node_id "labelcoords" $roundcoords
}

#****f* nodecfg.tcl/getNodeCPUConf
# NAME
#   getNodeCPUConf -- get node's CPU configuration
# SYNOPSIS
#   set conf [getNodeCPUConf $node]
# FUNCTION
#   Returns node's CPU scheduling parameters { minp maxp weight }.
# INPUTS
#   * node -- node id
# RESULT
#   * conf -- node's CPU scheduling parameters { minp maxp weight }
#****
proc getNodeCPUConf { node_id } {
    return [cfgGet "nodes" $node_id "cpu"]
}

#****f* nodecfg.tcl/setNodeCPUConf
# NAME
#   setNodeCPUConf -- set node's CPU configuration
# SYNOPSIS
#   setNodeCPUConf $node $param_list
# FUNCTION
#   Sets the node's CPU scheduling parameters.
# INPUTS
#   * node -- node id
#   * param_list -- node's CPU scheduling parameters { minp maxp weight }
#****
proc setNodeCPUConf { node_id param_list } {
    cfgSet "nodes" $node_id "cpu" $param_list
}

proc getAutoDefaultRoutesStatus { node_id } {
    return [cfgGet "nodes" $node_id "auto_default_routes"]
}

proc setAutoDefaultRoutesStatus { node_id state } {
    cfgSet "nodes" $node_id "auto_default_routes" $state
}

#****f* nodecfg.tcl/ifcList
# NAME
#   ifcList -- get list of all interfaces
# SYNOPSIS
#   set ifcs [ifcList $node]
# FUNCTION
#   Returns a list of all interfaces present in a node.
# INPUTS
#   * node -- node id
# RESULT
#   * interfaces -- list of all node's interfaces
#****
proc ifcList { node_id } {
    return [dict keys [cfgGet "nodes" $node_id "ifaces"]]
}

#****f* nodecfg.tcl/logIfcList
# NAME
#   logIfcList -- logical interfaces list
# SYNOPSIS
#   logIfcList $node
# FUNCTION
#   Returns the list of all the node's logical interfaces.
# INPUTS
#   * node -- node id
# RESULT
#   * interfaces -- list of node's logical interfaces
#****
proc logIfcList { node_id } {
    return [dict keys [cfgGet "nodes" $node_id "logifaces"]]
}

#****f* nodecfg.tcl/isIfcLogical
# NAME
#   isIfcLogical -- is given interface logical
# SYNOPSIS
#   isIfcLogical $node $ifc
# FUNCTION
#   Returns true or false whether the node's interface is logical or not.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
# RESULT
#   * check -- true if the interface is logical, otherwise false.
#****
proc isIfcLogical { node_id iface } {
    if { $iface in [logIfcList $node_id] } {
	return true
    }

    return false
}

#****f* nodecfg.tcl/allIfcList
# NAME
#   allIfcList -- all interfaces list
# SYNOPSIS
#   allIfcList $node
# FUNCTION
#   Returns the list of all node's interfaces.
# INPUTS
#   * node -- node id
# RESULT
#   * interfaces -- list of node's interfaces
#****
proc allIfcList { node_id } {
    return [concat [logIfcList $node_id] [ifcList $node_id]]
}

#****f* nodecfg.tcl/logicalPeerByIfc
# NAME
#   logicalPeerByIfc -- get node's peer by interface.
# SYNOPSIS
#   set peer [logicalPeerByIfc $node $ifc]
# FUNCTION
#   Returns id of the node on the other side of the interface. If the node on
#   the other side of the interface is connected via normal link (not split)
#   this function acts the same as the function getIfcPeer, but if the nodes
#   are connected via split links or situated on different canvases this
#   function returns the logical peer node.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
# RESULT
#   * peer -- node id of the node on the other side of the interface
#****
proc logicalPeerByIfc { node_id iface } {
    set peer [getIfcPeer $node_id $iface]
    if { [getNodeType $peer] != "pseudo" } {
	return $peer
    } else {
	set mirror_node [getNodeMirror $peer]
	set mirror_ifc [ifcList $mirror_node]

	return [getIfcPeer $mirror_node $mirror_ifc]
    }
}

#****f* nodecfg.tcl/ifcByPeer
# NAME
#   ifcByPeer -- get node interface by peer.
# SYNOPSIS
#   set ifc [ifcByPeer $node $peer]
# FUNCTION
#   Returns the name of the interface connected to the specified peer. If the
#   peer node is on different canvas or connected via split link to the
#   specified node this function returns an empty string.
# INPUTS
#   * node -- node id
#   * peer -- id of the peer node
# RESULT
#   * ifc -- interface name
#****
proc ifcByPeer { node_id peer_id } {
    set ifc_list {}

    foreach {iface iface_cfg} [cfgGet "nodes" $node_id "ifaces"] {
	if { [dictGet $iface_cfg "peer"] == $peer_id } {
	    lappend ifc_list $iface
	}
    }

    return $ifc_list
}

#****f* nodecfg.tcl/ifcByLogicalPeer
# NAME
#   ifcByPeer -- get node interface by peer.
# SYNOPSIS
#   set ifc [ifcByLogicalPeer $node $peer]
# FUNCTION
#   Returns the name of the interface connected to the specified peer. Returns
#   the right interface even if the peer node is on the other canvas or
#   connected via split link.
# INPUTS
#   * node -- node id
#   * peer -- id of the peer node
# RESULT
#   * ifc -- interface name
#****
proc ifcByLogicalPeer { node_id peer_id } {
    set iface [ifcByPeer $node_id $peer_id]
    if { $iface == "" } {
	#
	# Must search through pseudo peers
	#
	foreach iface [ifcList $node_id] {
	    set t_peer [getIfcPeer $node_id $iface]
	    if { [getNodeType $t_peer] == "pseudo" } {
		set mirror [getNodeMirror $t_peer]
		if { [getIfcPeer $mirror [ifcList $mirror]] == $peer_id } {
		    return $iface
		}
	    }
	}
	return ""
    }

    return $iface
}

#****f* nodecfg.tcl/hasIPv4Addr
# NAME
#   hasIPv4Addr -- has IPv4 address.
# SYNOPSIS
#   set check [hasIPv4Addr $node]
# FUNCTION
#   Returns true if at least one interface has an IPv4 address configured,
#   otherwise returns false.
# INPUTS
#   * node -- node id
# RESULT
#   * check -- true if at least one interface has an IPv4 address, otherwise
#     false.
#****
proc hasIPv4Addr { node_id } {
    foreach ifc [ifcList $node_id] {
	if { [getIfcIPv4addr $node_id $ifc] != "" } {
	    return true
	}
    }

    return false
}

#****f* nodecfg.tcl/hasIPv6Addr
# NAME
#   hasIPv6Addr -- has IPv6 address.
# SYNOPSIS
#   set check [hasIPv6Addr $node]
# FUNCTION
#   Retruns true if at least one interface has an IPv6 address configured,
#   otherwise returns false.
# INPUTS
#   * node -- node id
# RESULT
#   * check -- true if at least one interface has an IPv6 address, otherwise
#     false.
#****
proc hasIPv6Addr { node_id } {
    foreach ifc [ifcList $node_id] {
	if { [getIfcIPv6addr $node_id $ifc] != "" } {
	    return true
	}
    }
    return false
}

#****f* nodecfg.tcl/removeNode
# NAME
#   removeNode -- removes the node
# SYNOPSIS
#   removeNode $node
# FUNCTION
#   Removes the specified node as well as all the links binding that node to
#   the other nodes.
# INPUTS
#   * node -- node id
#****
proc removeNode { node_id } {
    global nodeNamingBase

    if { [getCustomIcon $node_id] != "" } {
	removeImageReference [getCustomIcon $node_id] $node_id
    }

    foreach ifc [ifcList $node_id] {
	set peer_id [getIfcPeer $node_id $ifc]
	set link [linkByPeers $node_id $peer_id]
	removeLink $link
    }

    setToRunning "node_list" [removeFromList [getFromRunning "node_list"] $node_id]

    set node_type [getNodeType $node_id]
    if { $node_type in [array names nodeNamingBase] } {
	recalculateNumType $node_type $nodeNamingBase($node_type)
    }

    cfgUnset "nodes" $node_id
}

#****f* nodecfg.tcl/getNodeCanvas
# NAME
#   getNodeCanvas -- get node canvas id
# SYNOPSIS
#   set canvas [getNodeCanvas $node]
# FUNCTION
#   Returns node's canvas affinity.
# INPUTS
#   * node -- node id
# RESULT
#   * canvas -- canvas id
#****
proc getNodeCanvas { node_id } {
    return [cfgGet "nodes" $node_id "canvas"]
}

#****f* nodecfg.tcl/setNodeCanvas
# NAME
#   setNodeCanvas -- set node canvas
# SYNOPSIS
#   setNodeCanvas $node $canvas
# FUNCTION
#   Sets node's canvas affinity.
# INPUTS
#   * node -- node id
#   * canvas -- canvas id
#****
proc setNodeCanvas { node_id canvas_id } {
    cfgSet "nodes" $node_id "canvas" $canvas_id
}

#****f* nodecfg.tcl/newIfc
# NAME
#   newIfc -- new interface
# SYNOPSIS
#   set ifc [newIfc $type $node]
# FUNCTION
#   Returns the first available name for a new interface of the specified type.
# INPUTS
#   * type -- interface type
#   * node -- node id
# RESULT
#   * ifc -- the first available name for a interface of the specified type
#****
proc newIfc { type node_id } {
    set interfaces [ifcList $node_id]
    for { set id 0 } { [lsearch -exact $interfaces $type$id] >= 0 } {incr id} {}

    return $type$id
}

#****f* nodecfg.tcl/newLogIfc
# NAME
#   newLogIfc -- new logical interface
# SYNOPSIS
#   newLogIfc $type $node
# FUNCTION
#   Returns the first available name for a new logical interface of the
#   specified type.
# INPUTS
#   * type -- interface type
#   * node -- node id
#****
proc newLogIfc { type node_id } {
    set interfaces [logIfcList $node_id]
    for { set id 0 } { [lsearch -exact $interfaces $type$id] >= 0 } {incr id} {}

    return $type$id
}

#****f* nodecfg.tcl/newNode
# NAME
#   newNode -- new node
# SYNOPSIS
#   set node_id [newNode $type]
# FUNCTION
#   Returns the node id of a new node of the specified type.
# INPUTS
#   * type -- node type
# RESULT
#   * node_id -- node id of a new node of the specified type
#****
proc newNode { type } {
    global viewid
    catch { unset viewid }
	
    set node_id [newObjectId "node"]
    setNodeType $node_id $type
    lappendToRunning "node_list" $node_id

    if { [info procs $type.confNewNode] == "$type.confNewNode" } {
	$type.confNewNode $node_id
    }

    return $node_id
}

#****f* nodecfg.tcl/getNodeMirror
# NAME
#   getNodeMirror -- get node mirror
# SYNOPSIS
#   set mirror_node_id [getNodeMirror $node]
# FUNCTION
#   Returns the node id of a mirror pseudo node of the node. Mirror node is
#   the corresponding pseudo node. The pair of pseudo nodes, node and his
#   mirror node, are introduced to form a split in a link. This split can be
#   used for avoiding crossed links or for displaying a link between the nodes
#   on a different canvas.
# INPUTS
#   * node -- node id
# RESULT
#   * mirror_node_id -- node id of a mirror node
#****
proc getNodeMirror { node_id } {
    return [cfgGet "nodes" $node_id "mirror"]
}

#****f* nodecfg.tcl/setNodeMirror
# NAME
#   setNodeMirror -- set node mirror
# SYNOPSIS
#   setNodeMirror $node $value
# FUNCTION
#   Sets the node id of a mirror pseudo node of the specified node. Mirror
#   node is the corresponding pseudo node. The pair of pseudo nodes, node and
#   his mirror node, are introduced to form a split in a link. This split can
#   be used for avoiding crossed links or for displaying a link between the
#   nodes on a different canvas.
# INPUTS
#   * node -- node id
#   * value -- node id of a mirror node
#****
proc setNodeMirror { node_id value } {
    cfgSet "nodes" $node_id "mirror" $value
}

#****f* nodecfg.tcl/getNodeProtocolRip
# NAME
#   getNodeProtocolRip
# SYNOPSIS
#   getNodeProtocolRip $node
# FUNCTION
#   Checks if node's current protocol is rip.
# INPUTS
#   * node -- node id 
# RESULT
#   * check -- 1 if it is rip, otherwise 0
#****
proc getNodeProtocolRip { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node    
	   
    if { [netconfFetchSection $node "router rip"] != "" } {
	return 1;
    } else {	
	return 0;
    }	    
}

proc getNodeProtocol { node_id protocol } {
    return [cfgGet "nodes" $node_id "router_config" $protocol]
}

proc setNodeProtocol { node_id protocol state } {
    cfgSet "nodes" $node_id "router_config" $protocol $state
}

#****f* nodecfg.tcl/getNodeProtocolRipng
# NAME
#   getNodeProtocolRipng
# SYNOPSIS
#   getNodeProtocolRipng $node
# FUNCTION
#   Checks if node's current protocol is ripng.
# INPUTS
#   * node -- node id
# RESULT
#   * check -- 1 if it is ripng, otherwise 0
#****
proc getNodeProtocolRipng { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node    
	   
    if { [netconfFetchSection $node "router ripng"] != "" } {
	return 1;
    } else {	
	return 0;
    }	    
}

#****f* nodecfg.tcl/getNodeProtocolOspfv2
# NAME
#   getNodeProtocolOspfv2
# SYNOPSIS
#   getNodeProtocolOspfv2 $node
# FUNCTION
#   Checks if node's current protocol is ospfv2.
# INPUTS
#   * node -- node id
# RESULT
#   * check -- 1 if it is ospfv2, otherwise 0
#****
proc getNodeProtocolOspfv2 { node } { 
    upvar 0 ::cf::[set ::curcfg]::$node $node

    if { [netconfFetchSection $node "router ospf"] != ""} {	
	return 1;
    } else {	
	return 0;
    }	
}

#****f* nodecfg.tcl/getNodeProtocolOspfv3
# NAME
#   getNodeProtocolOspfv3
# SYNOPSIS
#   getNodeProtocolOspfv3 $node
# FUNCTION
#   Checks if node's current protocol is ospfv3.
# INPUTS
#   * node -- node id
# RESULT
#   * check -- 1 if it is ospfv3, otherwise 0
#****
proc getNodeProtocolOspfv3 { node } { 
    upvar 0 ::cf::[set ::curcfg]::$node $node

    if { [netconfFetchSection $node "router ospf6"] != ""} {	
	return 1;
    } else {	
	return 0;
    }	
}

#****f* nodecfg.tcl/setNodeProtocolRip
# NAME
#   setNodeProtocolRip
# SYNOPSIS
#   setNodeProtocolRip $node $ripEnable
# FUNCTION
#   Sets node's protocol to rip.
# INPUTS
#   * node -- node id
#   * ripEnable -- 1 if enabling rip, 0 if disabling 
#****
proc setNodeProtocolRip { node ripEnable } {
    upvar 0 ::cf::[set ::curcfg]::$node $node    
	   
    if { $ripEnable == 1 } {
	netconfInsertSection $node [list "router rip" \
		" redistribute static" \
		" redistribute connected" \
		" redistribute ospf" \
		" network 0.0.0.0/0" \
		! ]
    } else {	
	netconfClearSection $node "router rip"	
    }	    
}

#****f* nodecfg.tcl/setNodeProtocolRipng
# NAME
#   setNodeProtocolRipng
# SYNOPSIS
#   setNodeProtocolRipng $node $ripngEnable
# FUNCTION
#   Sets node's protocol to ripng.
# INPUTS
#   * node -- node id
#   * ripngEnable -- 1 if enabling ripng, 0 if disabling 
#****
proc setNodeProtocolRipng { node ripngEnable } {
    upvar 0 ::cf::[set ::curcfg]::$node $node    
	   
    if { $ripngEnable == 1 } {
	netconfInsertSection $node [list "router ripng" \
		" redistribute static" \
		" redistribute connected" \
		" redistribute ospf6" \
		" network ::/0" \
		! ]
    } else {	
 	netconfClearSection $node "router ripng"	
    }	    
}

#****f* nodecfg.tcl/setNodeProtocolOspfv2
# NAME
#   setNodeProtocolOspfv2
# SYNOPSIS
#   setNodeProtocolOspfv2 $node $ospfEnable
# FUNCTION
#   Sets node's protocol to ospf.
# INPUTS
#   * node -- node id
#   * ospfEnable -- 1 if enabling ospf, 0 if disabling
#****
proc setNodeProtocolOspfv2 { node ospfEnable } { 
    upvar 0 ::cf::[set ::curcfg]::$node $node

    if { $ospfEnable == 1 } {
	netconfInsertSection $node [list "router ospf" \
		" redistribute static" \
		" redistribute connected" \
		" redistribute rip" \
		" network 0.0.0.0/0 area 0.0.0.0" \
		! ]
    } else {
	netconfClearSection $node "router ospf"
    }
}

#****f* nodecfg.tcl/setNodeProtocolOspfv3
# NAME
#   setNodeProtocolOspfv3
# SYNOPSIS
#   setNodeProtocolOspfv3 $node $ospf6Enable
# FUNCTION
#   Sets node's protocol to Ospfv3.
# INPUTS
#   * node -- node id
#   * ospf6Enable -- 1 if enabling ospf6, 0 if disabling
#****
proc setNodeProtocolOspfv3 { node ospf6Enable } { 
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set router_id [ip::intToString [expr 1 + [string trimleft $node "n"]]]

    set area_string "area 0.0.0.0 range ::/0"
    if { [getNodeModel $node] == "quagga" } {
	set area_string "network ::/0 area 0.0.0.0"
    }

    if { $ospf6Enable == 1 } {
	netconfInsertSection $node [list "router ospf6" \
		" ospf6 router-id $router_id" \
		" redistribute static" \
		" redistribute connected" \
		" redistribute ripng" \
		" $area_string" \
		! ]
    } else {
	netconfClearSection $node "router ospf6"
    }
}

#****f* nodecfg.tcl/setNodeType
# NAME
#   setNodeType -- set node's type.
# SYNOPSIS
#   setNodeType $node $type
# FUNCTION
#   Sets node's type.
# INPUTS
#   * node -- node id
#   * type -- type of node
#****
proc setNodeType { node_id type } {
    cfgSet "nodes" $node_id "type" $type
}

#****f* nodecfg.tcl/setCloudParts
# NAME
#   setCloudParts -- set cloud parts
# SYNOPSIS
#   setCloudParts $node $nr_parts
# FUNCTION
#   Sets the parts of the node's cloud.
# INPUTS
#   * node -- node id
#   * nr_parts -- cloud parts
#****
proc setCloudParts { node_id num_parts } {
    cfgSet "nodes" $node_id "num_parts" $num_parts
}

#****f* nodecfg.tcl/getCloudParts
# NAME
#   getCloudParts -- get cloud parts
# SYNOPSIS
#   getCloudParts $node
# FUNCTION
#   Returns the node's cloud parts.
# INPUTS
#   * node -- node id
# RESULT
#   * part -- cloud parts
#****
proc getCloudParts { node_id } {
    return [cfgGet "node" $node_id "num_parts"]
}

#****f* nodecfg.tcl/registerModule
# NAME
#   registerModule -- register module
# SYNOPSIS
#   registerModule $module
# FUNCTION
#   Adds a module to all_modules_list.
# INPUTS
#   * module -- module to add
#****
proc registerModule { module } {
    global all_modules_list

    lappend all_modules_list $module
}

#****f* nodecfg.tcl/deregisterModule
# NAME
#   deregisterModule -- deregister module
# SYNOPSIS
#   deregisterModule $module
# FUNCTION
#   Removes a module from all_modules_list.
# INPUTS
#   * module -- module to remove
#****
proc deregisterModule { module } {
    global all_modules_list

    set all_modules_list [removeFromList $all_modules_list $module]
}

#****f* nodecfg.tcl/getIfcVlanDev
# NAME
#   getIfcVlanDev -- get interface vlan-dev
# SYNOPSIS
#   getIfcVlanDev $node $ifc
# FUNCTION
#   Returns node's interface's vlan dev.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
# RESULT
#   * tag -- interfaces's vlan-dev
#****
proc getIfcVlanDev { node_id iface } {
    return [cfgGet "nodes" $node_id "logifaces" $iface "vlan_dev"]
}

#****f* nodecfg.tcl/setIfcVlanDev
# NAME
#   setIfcVlanDev -- set interface vlan-dev
# SYNOPSIS
#   setIfcVlanDev $node $ifc $dev
# FUNCTION
#   Sets the node's interface's vlan dev.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#   * dev -- vlan-dev
#****
proc setIfcVlanDev { node_id iface dev } {
    cfgSet "nodes" $node_id "logifaces" $iface "vlan_dev" $dev
}

#****f* nodecfg.tcl/getIfcVlanTag
# NAME
#   getIfcVlanTag -- get interface vlan-tag
# SYNOPSIS
#   getIfcVlanTag $node $ifc
# FUNCTION
#   Returns node's interface's vlan tag.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
# RESULT
#   * tag -- interfaces's vlan-tag
#****
proc getIfcVlanTag { node_id iface } {
    return [cfgGet "nodes" $node_id "logifaces" $iface "vlan_tag"]
}

#****f* nodecfg.tcl/setIfcVlanTag
# NAME
#   setIfcVlanTag -- set interface vlan-tag
# SYNOPSIS
#   setIfcVlanTag $node $ifc $tag
# FUNCTION
#   Sets the node's interface's vlan tag.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#   * dev -- vlan-tag
#****
proc setIfcVlanTag { node_id iface tag } {
    cfgSet "nodes" $node_id "logifaces" $iface "vlan_tag" $tag
}

#****f* nodecfg.tcl/getEtherVlanEnabled
# NAME
#   getEtherVlanEnabled -- get node rj45 vlan.
# SYNOPSIS
#   set value [getEtherVlanEnabled $node]
# FUNCTION
#   Returns whether the rj45 node is vlan enabled.
# INPUTS
#   * node -- node id
# RESULT
#   * value -- vlan enabled
#****
proc getEtherVlanEnabled { node_id } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    return [getWithDefault 0 $dict_cfg "nodes" $node_id "vlan" "enabled"]
}

#****f* nodecfg.tcl/setEtherVlanEnabled
# NAME
#   setEtherVlanEnabled -- set node rj45 vlan.
# SYNOPSIS
#   setEtherVlanEnabled $node $value
# FUNCTION
#   Sets rj45 node vlan setting.
# INPUTS
#   * node -- node id
#   * value -- vlan enabled
#****
proc setEtherVlanEnabled { node_id state } {
    cfgSet "nodes" $node_id "vlan" "enabled" $state
}

#****f* nodecfg.tcl/getEtherVlanTag
# NAME
#   getEtherVlanTag -- get node rj45 vlan tag.
# SYNOPSIS
#   set value [getEtherVlanTag $node]
# FUNCTION
#   Returns rj45 node vlan tag.
# INPUTS
#   * node -- node id
# RESULT
#   * value -- vlan tag
#****
proc getEtherVlanTag { node_id } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    return [getWithDefault 1 $dict_cfg "nodes" $node_id "vlan" "tag"]
}

#****f* nodecfg.tcl/setEtherVlanTag
# NAME
#   setEtherVlanTag -- set node rj45 vlan tag.
# SYNOPSIS
#   setEtherVlanTag $node $value
# FUNCTION
#   Sets rj45 node vlan tag.
# INPUTS
#   * node -- node id
#   * value -- vlan tag
#****
proc setEtherVlanTag { node_id tag } {
    cfgSet "nodes" $node_id "vlan" "tag" $tag
}

#****f* nodecfg.tcl/getNodeServices
# NAME
#   getNodeServices -- get node active services.
# SYNOPSIS
#   set services [getNodeServices $node]
# FUNCTION
#   Returns node's selected services.
# INPUTS
#   * node -- node id
# RESULT
#   * services -- active services
#****
proc getNodeServices { node_id } {
    return [cfgGet "nodes" $node_id "services"]
}

#****f* nodecfg.tcl/setNodeServices
# NAME
#   setNodeServices -- set node active services.
# SYNOPSIS
#   setNodeServices $node $services
# FUNCTION
#   Sets node selected services.
# INPUTS
#   * node -- node id
#   * services -- list of services
#****
proc setNodeServices { node_id services } {
    cfgSet "nodes" $node_id "services" $services
}

#****f* nodecfg.tcl/getNodeCustomImage
# NAME
#   getNodeCustomImage -- get node custom image.
# SYNOPSIS
#   set value [getNodeCustomImage $node]
# FUNCTION
#   Returns node custom image setting.
# INPUTS
#   * node -- node id
# RESULT
#   * status -- custom image identifier
#****
proc getNodeCustomImage { node_id } {
    return [cfgGet "nodes" $node_id "custom_image"]
}

#****f* nodecfg.tcl/setNodeCustomImage
# NAME
#   setNodeCustomImage -- set node custom image.
# SYNOPSIS
#   setNodeCustomImage $node $img
# FUNCTION
#   Sets node custom image.
# INPUTS
#   * node -- node id
#   * img -- image identifier
#****
proc setNodeCustomImage { node_id img } {
    cfgSet "nodes" $node_id "custom_image" $img
}

#****f* nodecfg.tcl/getNodeDockerAttach
# NAME
#   getNodeDockerAttach -- get node docker ext ifc attach.
# SYNOPSIS
#   set value [getNodeDockerAttach $node]
# FUNCTION
#   Returns node docker ext ifc attach setting.
# INPUTS
#   * node -- node id
# RESULT
#   * status -- attach enabled
#****
proc getNodeDockerAttach { node_id } {
    return [cfgGet "nodes" $node_id "docker_attach"]
}

#****f* nodecfg.tcl/setNodeDockerAttach
# NAME
#   setNodeDockerAttach -- set node docker ext ifc attach.
# SYNOPSIS
#   setNodeDockerAttach $node $enabled
# FUNCTION
#   Sets node docker ext ifc attach status.
# INPUTS
#   * node -- node id
#   * enabled -- attach status
#****
proc setNodeDockerAttach { node_id state } {
    cfgSet "nodes" $node_id "docker_attach" $state
}

#****f* nodecfg.tcl/registerRouterModule
# NAME
#   registerRouterModule -- register module
# SYNOPSIS
#   registerRouterModule $module
# FUNCTION
#   Adds a module to router_modules_list.
# INPUTS
#   * module -- module to add
#****
proc registerRouterModule { module } {
    global router_modules_list

    lappend router_modules_list $module
}

#****f* nodecfg.tcl/isNodeRouter
# NAME
#   isNodeRouter -- check whether a node is registered as a router
# SYNOPSIS
#   isNodeRouter $node
# FUNCTION
#   Checks if a node is a router.
# INPUTS
#   * node -- node to check
#****
proc isNodeRouter { node_id } {
    global router_modules_list

    if { [getNodeType $node_id] in $router_modules_list } {
	return 1
    }

    return 0
}

#****f* nodecfg.tcl/nodeCfggenIfcIPv4
# NAME
#   nodeCfggenIfcIPv4 -- generate interface IPv4 configuration
# SYNOPSIS
#   nodeCfggenIfcIPv4 $node
# FUNCTION
#   Generate configuration for all IPv4 addresses on all node
#   interfaces.
# INPUTS
#   * node -- node to generate configuration for
# RESULT
#   * value -- interface IPv4 configuration script
#****
proc nodeCfggenIfcIPv4 { node_id } {
    set cfg {}
    foreach ifc [allIfcList $node_id] {
	set primary 1
	foreach addr [getIfcIPv4addrs $node_id $ifc] {
	    if { $addr != "" } {
		lappend cfg [getIPv4IfcCmd $ifc $addr $primary]
		set primary 0
	    }
	}
    }

    return $cfg
}

#****f* nodecfg.tcl/nodeCfggenIfcIPv6
# NAME
#   nodeCfggenIfcIPv6 -- generate interface IPv6 configuration
# SYNOPSIS
#   nodeCfggenIfcIPv6 $node
# FUNCTION
#   Generate configuration for all IPv6 addresses on all node
#   interfaces.
# INPUTS
#   * node -- node to generate configuration for
# RESULT
#   * value -- interface IPv6 configuration script
#****
proc nodeCfggenIfcIPv6 { node_id } {
    set cfg {}
    foreach ifc [allIfcList $node_id] {
	set primary 1
	foreach addr [getIfcIPv6addrs $node_id $ifc] {
	    if { $addr != "" } { 
		lappend cfg [getIPv6IfcCmd $ifc $addr $primary]
		set primary 0
	    }
	}
    }

    return $cfg
}

#****f* nodecfg.tcl/nodeCfggenRouteIPv4
# NAME
#   nodeCfggenRouteIPv4 -- generate ifconfig IPv4 configuration
# SYNOPSIS
#   nodeCfggenRouteIPv4 $node
# FUNCTION
#   Generate IPv4 route configuration.
# INPUTS
#   * node -- node to generate configuration for
# RESULT
#   * value -- route IPv4 configuration script
#****
proc nodeCfggenRouteIPv4 { node_id } {
    set cfg {}
    foreach statrte [getStatIPv4routes $node_id] {
	lappend cfg [getIPv4RouteCmd $statrte]
    }

    if { [getAutoDefaultRoutesStatus $node_id] == "enabled" } {
	foreach statrte [getDefaultIPv4routes $node_id] {
	    lappend cfg [getIPv4RouteCmd $statrte]
	}
	setDefaultIPv4routes $node_id {}
    }

    return $cfg
}

#****f* nodecfg.tcl/nodeCfggenRouteIPv6
# NAME
#   nodeCfggenRouteIPv6 -- generate ifconfig IPv6 configuration
# SYNOPSIS
#   nodeCfggenRouteIPv6 $node
# FUNCTION
#   Generate IPv6 route configuration.
# INPUTS
#   * node -- node to generate configuration for
# RESULT
#   * value -- route IPv6 configuration script
#****
proc nodeCfggenRouteIPv6 { node_id } {
    set cfg {}
    foreach statrte [getStatIPv6routes $node_id] {
	lappend cfg [getIPv6RouteCmd $statrte]
    }

    if { [getAutoDefaultRoutesStatus $node_id] == "enabled" } {
	foreach statrte [getDefaultIPv6routes $node_id] {
	    lappend cfg [getIPv6RouteCmd $statrte]
	}
	setDefaultIPv6routes $node_id {}
    }

    return $cfg
}

#****f* nodecfg.tcl/getAllNodesType
# NAME
#   getAllNodesType -- get list of all nodes of a certain type
# SYNOPSIS
#   getAllNodesType $type
# FUNCTION
#   Passes through the list of all nodes and returns a list of nodes of the
#   specified type.
# INPUTS
#   * type -- node type
# RESULT
#   * list -- list of all nodes of the type
#****
proc getAllNodesType { type } {
    set type_list ""
    foreach node_id [getFromRunning "node_list"] {
	if { [string match "$type*" [typemodel $node_id]] } {
	    lappend type_list $node_id
	}
    }

    return $type_list
}

#****f* nodecfg.tcl/getNewNodeNameType
# NAME
#   getNewNodeNameType -- get a new node name for a certain type
# SYNOPSIS
#   getNewNodeNameType $type $namebase
# FUNCTION
#   Returns a new node name for the type and namebase, e.g. pc0 for pc.
# INPUTS
#   * type -- node type
#   * namebase -- base for the node name
# RESULT
#   * name -- new node name to be assigned
#****
proc getNewNodeNameType { type namebase } {
    upvar 0 ::cf::[set ::curcfg]::num$type num$type

    #if the variable pcnodes isn't set we need to check through all the nodes
    #to assign a non duplicate name
    if { ! [info exists num$type] } {
	recalculateNumType $type $namebase
    }

    incr num$type

    return $namebase[set num$type]
}

#****f* nodecfg.tcl/recalculateNumType
# NAME
#   recalculateNumType -- recalculate number for type
# SYNOPSIS
#   recalculateNumType $type $namebase
# FUNCTION
#   Calculates largest number for the given type
# INPUTS
#   * type -- node type
#   * namebase -- base for the node name
#****
proc recalculateNumType { type namebase } {
    upvar 0 ::cf::[set ::curcfg]::num$type num$type

    set num$type 0
    foreach n [getAllNodesType $type] {
	set name [getNodeName $n]
	if { [string match "$namebase*" $name] } {
	    set rest [string trimleft $name $namebase]
	    if { [string is integer $rest] && $rest > [set num$type] } {
		set num$type $rest
	    }
	}
    }
}

#****f* nodecfg.tcl/transformNodes
# NAME
#   transformNodes -- change nodes' types
# SYNOPSIS
#   transformNodes $nodes $to_type
# FUNCTION
#   Changes nodes' type and configuration. Conversion is possible between router
#   on the one side, and the pc or host on the other side.
# INPUTS
#   * nodes -- node ids
#   * to_type -- new type of node
#****
proc transformNodes { nodes to_type } {
    global routerRipEnable routerRipngEnable routerOspfEnable routerOspf6Enable
    global rdconfig routerDefaultsModel
    global changed

    lassign $rdconfig ripEnable ripngEnable ospfEnable ospf6Enable

    foreach node_id $nodes {
	if { [[typemodel $node_id].layer] == "NETWORK" } {
	    set from_type [getNodeType $node_id]

	    # replace type
	    setNodeType $node_id $to_type

	    if { $to_type == "pc" || $to_type == "host" } {
		if { $from_type == "router" } {
		    setNodeModel $node_id {}
		    cfgUnset "nodes" $node_id "router_config"
		}

		set changed 1
	    } elseif { $from_type != "router" && $to_type == "router" } {
		setNodeModel $node_id $routerDefaultsModel
		if { $routerDefaultsModel != "static" } {
		    setNodeProtocol $node_id "rip" $ripEnable
		    setNodeProtocol $node_id "ripng" $ripngEnable
		    setNodeProtocol $node_id "ospf" $ospfEnable
		    setNodeProtocol $node_id "ospf6" $ospf6Enable
		}

		set changed 1
	    }
	}
    }
}

#****f* nodecfg.tcl/pseudo.layer
# NAME
#   pseudo.layer -- pseudo layer
# SYNOPSIS
#   set layer [pseudo.layer]
# FUNCTION
#   Returns the layer on which the pseudo node operates
#   i.e. returns no layer.
# RESULT
#   * layer -- returns an empty string
#****
proc pseudo.layer {} {
}

#****f* nodecfg.tcl/pseudo.virtlayer
# NAME
#   pseudo.virtlayer -- pseudo virtlayer
# SYNOPSIS
#   set virtlayer [pseudo.virtlayer]
# FUNCTION
#   Returns the virtlayer on which the pseudo node operates
#   i.e. returns no layer.
# RESULT
#   * virtlayer -- returns an empty string
#****
proc pseudo.virtlayer {} {
}
