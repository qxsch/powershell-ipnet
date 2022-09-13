class IP {
    [bool[]] hidden $ipbitmask
    [string] hidden $ip

    IP([string]$ip) {
        $this.ip = $ip.Trim()
        if($this.ip.Contains(".")) {
            $this.ipbitmask = [IP]::GetIP32BitMask($this.ip)    
        }
        elseif($this.ip.Contains(":")) {
            $this.ip = $this.ip.ToUpper()
            $this.ipbitmask = [IP]::GetIP128BitMask($this.ip)    
        }
        else {
            throw "Invalid IP Address: $ip"
        }

    }

    [string[]] hidden static GetIPv6Segments([string]$ip) {
        $ipa = $ip.Trim().Split(':')
        if($ipa.Count -ne 8) {
            $ipa = $ip.Trim().Split('::')
            if($ipa.Count -ne 2) {
                throw "Invalid IP Address: $ip"
            }
            
            $ipa1 = $ipa[0].Split(':')
            $ipa2 = $ipa[1].Split(':')
            $ipa = @()
            foreach($i in $ipa1) {
                if($i -eq "") {
                    $i = "0"
                }
                $ipa += $i
            }
            for($i = 0; $i -lt (8 - ($ipa1.Count + $ipa2.Count)); $i++) {
                $ipa += "0"
            }
            foreach($i in $ipa2) {
                if($i -eq "") {
                    $i = "0"
                }
                $ipa += $i
            }

            if($ipa.Count -ne 8) {
                throw "Invalid IP Address: $ip"
            }
        }
        return $ipa
    }

    [bool[]] hidden static GetIP128BitMask([string]$ip) {
        $bm = new-object bool[] 128

        for($i = 0; $i -lt 128; $i++) {
            $bm[$i] = $false
        }

        $ipa = [IP]::GetIPv6Segments($ip)

        for($i = 0; $i -lt 8; $i++) {
            if($ipa[$i] -eq "") {
                continue
            }
            $seg =  [Convert]::ToInt32($ipa[$i], 16)

            for($ii = 0; $seg -gt 0; $ii++) {
                $bm[($i * 16) + 16 - $ii - 1] = [bool]($seg % 2)
                $seg = [Math]::Floor($seg / 2)
            }

            $s = ""
            for($ii = 0; $ii -lt 16; $ii++) {
                if($bm[($i * 16) + $ii]) {
                    $s += "1"
                }
                else {
                    $s += "0"
                }
            }
        }

        return $bm
    }

    [bool[]] hidden static GetIP32BitMask([string]$ip) {
        $bm = new-object bool[] 32

        for($i = 0; $i -lt 32; $i++) {
            $bm[$i] = $false
        }

        $ipa = $ip.Trim().Split('.')
        if($ipa.Count -ne 4) {
            throw "Invalid IP Address: $ip"
        }

        for($i = 0; $i -lt 4; $i++) {
            $seg = [int]$ipa[$i]
            for($ii = 0; $seg -gt 0; $ii++) {
                #Write-Host ("" + (($i * 8) + 8 - $ii - 1) + " "  + ($seg % 2) + "  $seg")
                $bm[($i * 8) + 8 - $ii - 1] = [bool]($seg % 2)
                $seg = [Math]::Floor($seg / 2)
            }

            $s = ""
            for($ii = 0; $ii -lt 8; $ii++) {
                if($bm[($i * 8) + $ii]) {
                    $s += "1"
                }
                else {
                    $s += "0"
                }
            }
        }
        return $bm
    }

    [string] GetIP() {
        return $this.ip
    }

    [bool[]] GetBitMask() {
        return $this.ipbitmask
    }

    [string] GetBitMaskString() {
        if($this.ipbitmask.Count -eq 32) {
            $s = ""
            for($i = 0; $i -lt 32; $i++) {
                if(($i % 8) -eq 0  -and  $i -gt 0) {
                    $s += "."
                }
                if($this.ipbitmask[$i]) {
                    $s += "1"
                }
                else {
                    $s += "0"
                }
            }
            return $s
        }
        elseif($this.ipbitmask.Count -eq 128) {
            $s = ""
            for($i = 0; $i -lt 128; $i++) {
                if(($i % 16) -eq 0  -and  $i -gt 0) {
                    $s += ":"
                }
                if($this.ipbitmask[$i]) {
                    $s += "1"
                }
                else {
                    $s += "0"
                }
            }
            return $s
        }
        else {
            return ""
        }
    }

    [bool] IsIPv4() {
        return $this.ipbitmask.Count -eq 32
    }

    [bool] IsIPv6() {
        return $this.ipbitmask.Count -eq 128
    }

    [bool] BelongsToSubnet([string]$subnet) {
        return ([Subnet]::new($subnet)).ContainsIP($this)
    }

    [bool] BelongsToSubnet([Subnet]$subnet) {
        return $subnet.ContainsIP($this)
    }

    [string] ToString() {
        return ( "" + $this.ip )
    }

    [IP] ConvertToIPv6() {
        if($this.IsIPv6()) {
            return $this
        }
        
        if($this.IsIPv4()) {
            $ipstr = "::FFFF"
            $i = 0
            foreach($p in $this.ip.Split(".")) {
                if(($i % 2) -eq 0) {
                    $ipstr += ":"
                }
                $s = ([int]$p).ToString("X")
                if($s.Length -lt 2) {
                    $s = "0$s"
                }
                $ipstr += "$s"
                $i++
            }
            return [IP]::new($ipstr.ToUpper())
        }

        throw "IP cannot be converted to version 6"
    }
}


class Subnet {
    [IP] hidden $ip
    [IP] hidden $mask
    [int] hidden $cidr

    Subnet([string]$subnet) {
        $parts = $subnet -split "/"
        if($parts.Count -ne 2) {
            throw "Invalid subnet: $subnet"
        }
        $parts[0] = $parts[0].Trim()
        $parts[1] = $parts[1].Trim()
        $this.ip = [IP]::new($parts[0])

        if($parts[1] -match '^\d+$' ) {
            $this.cidr = ([int]$parts[1])
            $this.mask = [Subnet]::GetMaskIPFromCIDR($parts[1], $this.ip.GetBitMask().Count)
        }
        else {
            $this.cidr = -1
            $this.mask = [IP]::new($parts[1])
        }
        if($this.ip.IsIPv4() -and (-not $this.mask.IsIPv4())) {
            throw "Invalid subnet: $subnet"
        }
        if($this.ip.IsIPv6() -and (-not $this.mask.IsIPv6())) {
            throw "Invalid subnet: $subnet"
        }
    }

    [IP] hidden static  GetMaskIPFromCIDR([int]$int, [int]$len) {
        $bm = new-object bool[] $len

        for($i = 0; $i -lt $len; $i++) {
            $bm[$i] = $false
        }

        for($i = 0; $i -lt $int; $i++) {
            $bm[$i] = $true
        }

        return  [IP]::new([Subnet]::GetIPFromBitmask($bm))
    }

    [string] hidden static GetIPFromBitmask([bool[]] $bm) {
        if($bm.Count -eq 32) {
            $a=@()
            for($i = 0; $i -lt 4; $i++) {
                $d = 0;
                for($ii = 0; $ii -lt 8; $ii++) {
                    if($bm[($i*8) + $ii]) {
                        $d += [Math]::pow(2, 8 - $ii - 1)
                    }
                }
                $a += $d
            }
            return ($a -join ".")
        }
        elseif($bm.Count -eq 128) {
            $s = ""
            for($i = 0; $i -lt 32; $i++) {
                if(($i % 4) -eq 0  -and  $i -gt 0) {
                    $s+=":"
                }

                $d = 0
                for($ii = 0; $ii -lt 4 ; $ii++) {
                    if($bm[($i * 4) + $ii]) {
                        $d += [Math]::pow(2, 4 - $ii -1)
                    }
                }
                $s += ([int]$d).ToString("X")
            }
            # removed unwanted zeros
            $a = $s -split ":"
            for($i=0 ; $i -lt 8; $i++) {
                while($a[$i][0] -eq "0"  -and  $a[$i] -ne "0") {
                    $a[$i] = $a[$i].Substring(1)
                }
            }
            return ($a -join ":")
        }
        else {
            return ""
        }
    }

    [string] ToString() {
        if($this.cidr -ne -1) {
            return ( $this.ip.GetIP() + " / " + $this.cidr)
        }
        return ( $this.ip.GetIP() + " / " + $this.mask.GetIP())
    }

    [IP] GetSubnetIP() {
        return $this.ip
    }

    [IP] GetSubnetMask() {
        return $this.mask
    }

    [IP] GetFirstIP() {
        $ipbm = $this.ip.GetBitMask()
        $maskbm = $this.mask.GetBitMask()

        $len = $ipbm.Count
        $bm = new-object bool[] $len

        for($i = 0; $i -lt $len; $i++) {
            if($maskbm[$i]) {
                $bm[$i] = $ipbm[$i]
            }
            else {
                $bm[$i] = $false
            }
        }

        return [IP]::new([Subnet]::GetIPFromBitmask($bm))
    }

    [IP] GetLastIP() {
        $ipbm = $this.ip.GetBitMask()
        $maskbm = $this.mask.GetBitMask()

        $len = $ipbm.Count
        $bm = new-object bool[] $len

        for($i = 0; $i -lt $len; $i++) {
            if($maskbm[$i]) {
                $bm[$i] = $ipbm[$i]
            }
            else {
                $bm[$i] = $true
            }
        }

        return [IP]::new([Subnet]::GetIPFromBitmask($bm))
    }

    [bool] ContainsIP([string]$ip) {
        return $this.ContainsIP([IP]::new($ip))
    }

    [bool] ContainsIP([IP]$ip) {
        $bm = $ip.GetBitMask()
        $ipbm = $this.ip.GetBitMask()
        $maskbm = $this.mask.GetBitMask()

        $len = $ipbm.Count

        # different ip versions? return false
        if($bm.Count -ne $len) {
            return $false
        }

        for($i = 0; $i -lt $len; $i++) {
            if($maskbm[$i]) {
                if($bm[$i] -ne $ipbm[$i]) {
                    return $false
                }
            }
        }

        return $true
    }

    [bool] Intersects([Subnet]$snet) {
        $ipbm = $this.ip.GetBitMask()
        $maskbm = $this.mask.GetBitMask()

        $ipbm2 = $snet.GetSubnetIP().GetBitMask()
        $maskbm2 = $this.GetSubnetMask().GetBitMask()

        $len = $ipbm.Count
        # different ip versions? return false
        if($ipbm2.Count -ne $len) {
            return $false
        }

        for($i = 0; $i -lt $len; $i++) {
            if($maskbm[$i] -and $maskbm2[$i]) {
                if($ipbm2[$i] -ne $ipbm[$i]) {
                    return $false
                }
            }
        }

        return $true
    }

    [bool] IsIPv4() {
        return $this.ip.GetBitMask().Count -eq 32
    }

    [bool] IsIPv6() {
        return $this.ip.GetBitMask().Count -eq 128
    }

    [Subnet] ConvertToIPv6() {
        if($this.IsIPv6()) {
            return $this
        }
        
        if($this.IsIPv4()) {
            if($this.cidr -ne -1) {
                return [Subnet]::new($this.ip.ConvertToIPv6().GetIP() + "/" + ($this.cidr + 96))
            }

            $bm = new-object bool[] 128
            for($i = 0; $i -lt 96; $i++) {
                $bm[$i] = $true
            }
    
            $bmm = $this.mask.GetBitMask()
            for($i = 0; $i -lt 32; $i++) {
                $bm[$i + 96] = $bmm[$i]
            }

            return [Subnet]::new($this.ip.ConvertToIPv6().GetIP() + "/" + [Subnet]::GetIPFromBitmask($bm))
        }

        throw "IP cannot be converted to version 6" 
    }

    [int] GetAddressSpaceBits() {
        $bm = $this.mask.GetBitMask()
        $len = $bm.Count
        $c = 0;
        for($i=0; $i -lt $len; $i++) {
            if($bm[$i] -eq $false) {
                $c++
            }
        }

        return $c
    }

    [string] GetAddressSpace() {
        $c = $this.GetAddressSpaceBits()
        if($c -eq 0) {
            return "0"
        }

        # calculate number
        $b = New-Object "System.Numerics.BigInteger" 1
        while($c -gt 0) {
            $b *= 2
            $c--
        }

        # beautify with '
        $b = [string]$b
        $len = $b.Length
        $s = ""
        for($i = 0; $i -lt $len; $i++) {
            $ii = $len - $i 
            if((($ii) % 3) -eq 0  -and  $ii -ne $len) {
                $s +=  "'"
            }
            $s += $b[$i]
        }
        
        return $s
    }
}


<#
 .Synopsis
  Creates a new IP Address Object

 .Description
  Creates a new IP Address Object

 .Parameter ip
  The IP Address in V4 or V6 Format

 .Example
   $ip = New-IPAddress "192.168.1.2"
   $ip.BelongsToSubnet("192.168.1.0/24")

 .Example
   $ip = New-IPAddress "::FFFF:0A0A:0A0A"

 .Example
   $ip = New-IPAddress "192.168.1.2"
   $ip.ConvertToIPv6()
#>
function New-IPAddress {
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$ip
    )

    return [IP]::new($ip)
}

<#
 .Synopsis
  Creates a new IP Subnet Object

 .Description
  Creates a new IP Subnet Object

 .Parameter subnet
  The IP Subnet in V4 or V6 Format

 .Example
   $snet = New-IPSubnet "192.168.1.0/24"
   $snet.ConvertToIPv6()

 .Example
   $snet = New-IPSubnet "::FFFF:0A0A:0A00/120"
   Write-Host ( "First IP is " + $snet.GetFirstIP() )
   Write-Host ( "Last  IP is " + $snet.GetLastIP() )
   Write-Host ( "Address Space is " + $snet.GetAddressSpace() )

 .Example
   $snet = New-IPSubnet "192.168.1.0/255.255.255.0"
   $snet.ContainsIP("192.168.1.2")

 .Example
   $snet = New-IPSubnet "::FFFF:0A0A:0A00 / FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FF00"
   $snet.ContainsIP("::FFFF:0A0A:0A0A")
#>
function New-IPSubnet {
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$subnet
    )

    return [Subnet]::new($subnet)
}


<#
 .Synopsis
  Displays the information of an IP Subnet

 .Description
  Displays the information of an IP Subnet

 .Parameter subnet
  The IP Subnet in V4 or V6 Format

 .Example
   Get-IPSubnetInfo "192.168.1.0/24"

 .Example
   Get-IPSubnetInfo "::FFFF:0A0A:0A00/120"

 .Example
   Get-IPSubnetInfo "192.168.1.0/255.255.255.0"

 .Example
   Get-IPSubnetInfo "::FFFF:0A0A:0A00 / FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FF00"
#>
function Get-IPSubnetInfo {
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$subnet
    )

    $snet = [Subnet]::new($subnet)
    return @{
        "Subnet"  = ([string]$snet)
        "IPv4" = $snet.IsIPv4()
        "IPv6" = $snet.IsIPv6()
        "FirstIP" = $snet.GetFirstIP()
        "LastIP" = $snet.GetLastIP()
        "IPBitArray" = $snet.GetSubnetIP().GetBitMask()
        "IPBitString" = $snet.GetSubnetIP().GetBitMaskString()
        "MaskBitArray" = $snet.GetSubnetMask().GetBitMask()
        "MaskBitString" = $snet.GetSubnetMask().GetBitMaskString()
        "IPv6Representation" = ([string]$snet.ConvertToIPv6())
        "AddressSpace" = $snet.GetAddressSpace()
    }
}

<#
 .Synopsis
  Displays the information of an IP Address

 .Description
  Displays the information of an IP Address

 .Parameter ip
  The IP Address in V4 or V6 Format

 .Example
   Get-IPAddressInfo "192.168.1.2"

 .Example
   Get-IPAddressInfo "::FFFF:0A0A:0A0A"

#>
function Get-IPAddressInfo {
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$ip
    )

    $a = [IP]::new($ip)
    return @{
        "IP"  = $a.GetIP()
        "IPv4" = $a.IsIPv4()
        "IPv6" = $a.IsIPv6()
        "IPBitArray" = $a.GetBitMask()
        "IPBitString" = $a.GetBitMaskString()
        "IPv6Representation" = ([string]$a.ConvertToIPv6())
    }
}

Export-ModuleMember -Function New-IPAddress, New-IPSubnet, Get-IPSubnetInfo, Get-IPAddressInfo