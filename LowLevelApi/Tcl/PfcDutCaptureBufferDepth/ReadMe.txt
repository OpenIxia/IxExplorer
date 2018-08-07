# Requires a DUT
# This script demonstrates how to measure the DUT’s buffer depth with PFC HW/SW/API abiity. This is done for Novus 100G.
# 06/22/2018
# Written by Hasmik Shakaryan and pseudo code by CHRISTOPHER KOWALSKI and Dwayne Hunnicutt 
# Solution: Tested on IxOS 8.40 EA



# Pseudo-code: 
#Use two DUT ports (let’s call them A and B) and two Ixia ports (let’s call them 1 and 2).  Port A is connected to 1 and port B is connected to 2.

# 1. Configure the DUT to switch all ingress packets on port A to egress on port B.
# 2. From port 2 send pause frames with max quanta at line rate.  This will prevent any packets from being sent out of port B.
# 3. Do the following:
#	 A.	Send 10000 packets from port 1
#	 B.	Stop the pause traffic being sent by port 2
#	 C.	See how many packets are received on port 2.  The number received is the buffer size.  If all packets are received repeat the steps again but send more packets in step A.
# 4. If the DUT has a drop count you can use that also to calculate the buffer size:
#	 A.	Packets sent – drop count = buffer size
#    B. After following the steps below, multiply the number of received packets by 64B.  The result is the buffer depth.

# NOTE:
# NovusStreamTraffic corresponds to “Ixia port 1.”  NovusPauseFrames.prt corresponds to “Ixia port 2.”    
# NovusPauseFrames.prt has streams to pause specific PFC queues, but they are currently disabled.  The enabled stream will pause all PFC queues.
# 
# We do not recommend calculating all priorities at the same time.  

#Steps to run the script: pfcDutBufferSize.tcl

#1.	Modify script to point to your chassis, hostname
#2.	Modify the script to point to the location of the port files in the attached zip file. Note that this are Novus ports. If you choose to run on a different port, you need to create new port files with the same configuration
#   You can use usePortFile flag to either load the .prt file or configure the ports using the script.
#3.	Source pfcDutBufferSize.tcl from the IxOS wish console.