# #HansonLattice Contributor Guide 📊

We welcome independent telemetry verification from bare-metal nodes. 

## 📋 Data Submission Process
1. Run `./setup.sh` and reboot the physical node.
2. Run `./logger.sh` for a minimum validation window of 10 minutes.
3. Submit a Pull Request containing your `lattice_telemetry_*.csv` file.

## 📝 Format for PR Descriptions
When uploading your telemetry results, include your exact hardware parameters:
* **Node Chassis Model**: (e.g., Node: M90Q-001)
* **Processor Architecture**: (e.g., Intel i9-13900T / AMD Ryzen 9)
* **Cooling Topology**: (e.g., Air-Cooled / Closed-Loop / Dielectric Immersion)
* **Baseline Latency Reduction**: (Average latency difference before and after isolation)

*All submitted code, adjustments, and system logs fall legally under the repository GNU GPLv3 copyleft mandate.*
