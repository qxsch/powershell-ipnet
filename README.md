# powershell-ipnet Module

Exports the following Cmdlets:
 * ``New-IPAddress``  Creates a new IP Object
 * ``New-IPSubnet``   Creates a new Subnet Object
 * ``Get-IPSubnetInfo``    Displays the information of an IP
 * ``Get-IPAddressInfo``   Displays the information of a Subnet

See class diagram:
```mermaid
classDiagram
    class IP{
        IP(string ip)
        string GetIP()
        bool[] GetBitMask()
        string GetBitMaskString()
        bool IsIPv4()
        bool IsIPv6()
        bool BelongsToSubnet(string subnet)
        bool BelongsToSubnet(Subnet subnet)
        IP ConvertToIPv6()
        string ToString()
    }
    class Subnet{
        Subnet(string ip)
        IP GetSubnetIP()
        IP GetSubnetMask()
        IP GetFirstIP()
        IP GetLastIP()
        int GetAddressSpaceBits()
        string GetAddressSpace()
        bool IsIPv4()
        bool IsIPv6()
        bool Intersects(Subnet $snet)
        bool ContainsIP(string ip)
        bool ContainsIP(IP ip)
        Subnet ConvertToIPv6()
        string ToString()
    }
```
