# This script demonstrates how to calculate PFC pause response time with the current HW/SW/API abiity. This is done for Novus 100G.
# 04/26/2017
# Written by Hasmik Shakaryan and pseudo code by Dwayne Hunnicutt
# Solution: Tested on IxOS 8.20 EA
# Use a “tracer packet”
# For this solution we send a packet (or packets) before the pause traffic and have it routed to another Ixia port so we can get the Tx time of the packet before the pause frames and thus know the Tx time of the pause frame.
# This solution can be done today, we have all the features and hooks.  The main issue with this feature is if the DUT drops the stream traffic packet sent before the pause frames this will introduce a measurement error. We could mitigate this by having the DUT prioritize this traffic or send on the control PFC queue.

# NOTE
# Make sure the NOVUS card resource mode is in capture for both of the below ports.

# Pseudo-code:
# 1)	Load pfc_pause_frames.prt on Port A
# 2)	Load pfc_stream_traffic.prt on Port B
# 3)    Clear time stamps on Port A and Port B
# 4)	Start PG stats on Port A
# 5)	Start Capture on Port B
# 6)	Start traffic on Port A & Port B
# 7)	View Capture on Port B and identify and analyze the last packet of the pre-pause frames from Port A
# 8)	Extract the sequence # and timestamp from the captured pre-pause packet
# 9)	Calculate the timestamp of the first pause packet:
# 	a.	Pause Frame Timestamp = extracted timestamp + 6.72*(pre-pause count – sequence # + 1)
# 10)	Get last timestamp from Port A (pfcPauseFramePort) PG stats
# 11)	Calculate PFC response time:
# 	a.	Response Time = (PG Stats timestamp – Pause Frame Timestamp)
# 12)   Calculate the number of packets received after the PFC pause frame is sent.  It will require enhancements to the scripts.  Here are the basic ideas:
#	a.	Enable capture on PortA.  Set a trigger event that will never occur (like matching a DA to F0F0_F0F0_F0F0) , and configure the capture engine to
#		capture all packets before the trigger event.
#	b.	Start capture on PortA (the port that will send the pause frame).
#	c.	Add 5.12 ns (the duration of a 64B packet) to the pause packet timestamp calculated above to account for when the packet was fully received by the DUT.
#	f.	Iterate through the captured packets on PortA in reverse order (last to first), and extract the Tx timestamp embedded in each packet.
#		Identify the packet whose Tx timestamp is just under the timestamp of the pause packet.  This identifies the last packet to have been received before the pause packet was sent.
#	g.	Subtract this packet number from the total packets received.  This yields the number of packets received after the pause packet was sent.

# NOTE:
# We do not recommend calculating all priorities at the same time.  For each additional priority added to the test, will decrease the accuracy of the calculated reaction time.
# Estimated time running this test using port to port connection time {source pfcResponseTime.tcl} 17428037 microseconds per iteration, or 20956247 microseconds per iteration
# We expect the PFC Response time and Rx number of packets may vary for each test run

#Steps to run the script: pfcResponseTime.tcl

#1.	Modify script to point to your chassis, hostname
#2.	Modify the script to point to the location of the port files in the attached zip file. Note that this are Novus ports. If you choose to run on a different port, you need to create new port files with the same configuration
#   You can use usePortFile flag to either load the .prt file or configure the ports using the script.
#3.	Source pfcResponseTime.tcl from the IxOS wish console.