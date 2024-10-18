
# Automata Building Automation Controller

![Automata Logo](https://github.com/AutomataControls/AutomataBuildingManagment-HvacController/blob/main/splash.png?raw=true)

---

![Version](https://img.shields.io/badge/version-1.0.0-darkgrey?style=flat-square)
![Teal Badge](https://img.shields.io/badge/status-active-teal?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-darkorange?style=flat-square)
![Python](https://img.shields.io/badge/python-3.8%2B-teal?style=flat-square)

---

<h2 style="color: teal;">Executive Summary</h2>

<p style="color: darkorange;">Automata Building Management & HVAC Controller is an advanced IoT-driven, scalable, and energy-efficient solution designed for commercial and industrial applications. The controller provides intelligent HVAC management, lighting control, energy optimization, and predictive maintenance features, all within a user-friendly interface and scalable architecture.</p>

The solution allows for real-time monitoring, data collection, and system control, making it an ideal choice for facility managers and building automation professionals.

---

## <span style="color: teal;">Table of Contents</span>

1. [Executive Summary](#executive-summary)
2. [Key Features](#key-features)
3. [System Architecture](#system-architecture)
4. [Installation](#installation)
5. [Usage](#usage)
6. [Data Collection and Sensor Integration](#data-collection-and-sensor-integration)
7. [Control Logic and Decision Making](#control-logic-and-decision-making)
8. [Safety Protocols and Fail-Safe Mechanisms](#safety-protocols-and-fail-safe-mechanisms)
9. [IT Department Considerations](#it-department-considerations)
10. [Corporate Compliance and EH&S](#corporate-compliance-and-ehs)
11. [Technical Specifications](#technical-specifications)
12. [Testing and Operational Experience](#testing-and-operational-experience)
13. [Troubleshooting](#troubleshooting)
14. [Roadmap](#roadmap)
15. [Contributing](#contributing)
16. [License](#license)
17. [Support](#support)
18. [Acknowledgments](#acknowledgments)

---

## <span style="color: teal;">Key Features</span>

1. **Intelligent HVAC Management**
   - Predictive temperature control based on occupancy patterns and weather forecasts
   - Zoned climate control for optimized comfort and energy efficiency

2. **Advanced Lighting Control**
   - Daylight harvesting to reduce artificial lighting needs
   - Occupancy-based lighting adjustments

3. **Comprehensive Security Integration**
   - Real-time monitoring and alerting for unauthorized access
   - Integration with existing security systems for centralized control

4. **Energy Optimization**
   - Real-time energy consumption monitoring and reporting
   - Automated demand response capabilities for peak load management

5. **Predictive Maintenance**
   - AI-driven equipment performance analysis
   - Early warning system for potential equipment failures

6. **Scalable Architecture**
   - Modular design allows for easy expansion and integration of new systems
   - Cloud-based management for multi-site deployments

7. **User-Friendly Interface**
   - Intuitive dashboard for real-time system monitoring and control
   - Mobile app for remote access and notifications

8. **Data Analytics and Reporting**
   - Comprehensive data visualization tools
   - Customizable reports for energy usage, system performance, and more

---

## <span style="color: teal;">Installation</span>

### Prerequisites

- Raspberry Pi 4B (8GB RAM) or compatible hardware
- Raspbian Linux OS
- Internet connection for package downloads

### Step-by-Step Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/AutomataControls/AutomataBuildingManagment-HvacController.git
   ```

---

## <span style="color: teal;">Acknowledgments</span>

This project utilizes several open-source tools and libraries. We would like to acknowledge the following projects and their contributors:

### Core Components
- [Node-RED](https://nodered.org/) - A programming tool for wiring together hardware devices, APIs, and online services.
- [Mosquitto](https://mosquitto.org/) - An open-source MQTT broker.

### Sequent Microsystems Drivers
- [megabas-rpi](https://github.com/sequentmicrosystems/megabas-rpi)
- [megaind-rpi](https://github.com/sequentmicrosystems/megaind-rpi)
- [16univin-rpi](https://github.com/sequentmicrosystems/16univin-rpi)
- [16relind-rpi](https://github.com/sequentmicrosystems/16relind-rpi)
- [8relind-rpi](https://github.com/sequentmicrosystems/8relind-rpi)

### Node-RED Nodes and Packages
- "node-red-contrib-ui-led"
- "node-red-dashboard"
- "node-red-contrib-sm-16inpind"
- "node-red-contrib-sm-16relind"
- "node-red-contrib-sm-8inputs"
- "node-red-contrib-sm-8relind"
- "node-red-contrib-sm-bas"
- "node-red-contrib-sm-ind"
- "node-red-node-openweathermap"
- "node-red-contrib-influxdb"
- "node-red-node-email"
- "node-red-contrib-boolean-logic-ultimate"
- "node-red-contrib-cpu"
- "node-red-contrib-bme280-rpi"
- "node-red-contrib-bme280"
- "node-red-node-aws33"
- "@node-red-contrib-themes/theme-collection" # Added theme collection

We would like to express our gratitude to **Current Mechanical** for the Freedom to Dream and Develop. Their support has made this project possible, inspiring us to explore innovative solutions in building automation and IoT systems.

We are grateful to the developers and contributors of these projects for their valuable work.

---

## <span style="color: teal;">License</span>

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

