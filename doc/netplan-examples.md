### Netplan examples

#### LACP Bonded Interface

```yaml
network:
  version: 2
  ethernets:
    eth0:
      mtu: 9000
    eth1:
      mtu: 9000
  bonds:
    bond0:
      interfaces:
        - eth0
        - eth1
      dhcp4: true
      mtu: 9000
      parameters:
        down-delay: 0
        lacp-rate: fast
        mii-monitor-interval: 100
        mode: 802.3ad
        transmit-hash-policy: layer3+4
        up-delay: 0
```

```json
{
  "network": {
    "version": 2,
    "ethernets": {
      "eth0": {
        "mtu": 9000
      },
      "eth1": {
        "mtu": 9000
      }
    },
    "bonds": {
      "bond0": {
        "interfaces": ["eth0", "eth1"],
        "dhcp4": true,
        "mtu": 9000,
        "parameters": {
          "down-delay": 0,
          "lacp-rate": "fast",
          "mii-monitor-interval": 100,
          "mode": "802.3ad",
          "transmit-hash-policy": "layer3+4",
          "up-delay": 0
        }
      }
    }
  }
}
```

#### LACP Bonded interface with multiple 802.1q VLAN-Tagged Interfaces, each servicing a single Bridge interface

```yaml
network:
  version: 2
  ethernets:
    eth0:
      mtu: 9000
    eth1:
      mtu: 9000
  bonds:
    bond0:
      interfaces:
        - eth0
        - eth1
      mtu: 9000
      parameters:
        down-delay: 0
        lacp-rate: fast
        mii-monitor-interval: 100
        mode: 802.3ad
        transmit-hash-policy: layer3+4
        up-delay: 0
  bridges:
    br0:
      dhcp4: true
      interfaces:
        - bond0.10
      mtu: 9000
      parameters:
        forward-delay: 0
        stp: false
    br11:
      interfaces:
        - bond0.11
      mtu: 9000
      parameters:
        forward-delay: 0
        stp: false
    br12:
      interfaces:
        - bond0.12
      mtu: 9000
      parameters:
        forward-delay: 0
        stp: false
    br20:
      interfaces:
        - bond0.20
      mtu: 9000
      parameters:
        forward-delay: 0
        stp: false
  vlans:
    bond0.10:
      id: 10
      link: bond0
      mtu: 9000
    bond0.11:
      id: 11
      link: bond0
      mtu: 9000
    bond0.12:
      id: 12
      link: bond0
      mtu: 9000
    bond0.20:
      id: 20
      link: bond0
      mtu: 9000
```

```json
{
  "network": {
    "version": 2,
    "ethernets": {
      "eth0": {
        "mtu": 9000
      },
      "eth1": {
        "mtu": 9000
      }
    },
    "bonds": {
      "bond0": {
        "interfaces": ["eth0", "eth1"],
        "mtu": 9000,
        "parameters": {
          "down-delay": 0,
          "lacp-rate": "fast",
          "mii-monitor-interval": 100,
          "mode": "802.3ad",
          "transmit-hash-policy": "layer3+4",
          "up-delay": 0
        }
      }
    },
    "bridges": {
      "br0": {
        "dhcp4": true,
        "interfaces": ["bond0.10"],
        "mtu": 9000,
        "parameters": {
          "forward-delay": 0,
          "stp": false
        }
      },
      "br11": {
        "interfaces": ["bond0.11"],
        "mtu": 9000,
        "parameters": {
          "forward-delay": 0,
          "stp": false
        }
      },
      "br12": {
        "interfaces": ["bond0.12"],
        "mtu": 9000,
        "parameters": {
          "forward-delay": 0,
          "stp": false
        }
      },
      "br20": {
        "interfaces": ["bond0.20"],
        "mtu": 9000,
        "parameters": {
          "forward-delay": 0,
          "stp": false
        }
      }
    },
    "vlans": {
      "bond0.10": {
        "id": 10,
        "link": "bond0",
        "mtu": 9000
      },
      "bond0.11": {
        "id": 11,
        "link": "bond0",
        "mtu": 9000
      },
      "bond0.12": {
        "id": 12,
        "link": "bond0",
        "mtu": 9000
      },
      "bond0.20": {
        "id": 20,
        "link": "bond0",
        "mtu": 9000
      }
    }
  }
}
```
