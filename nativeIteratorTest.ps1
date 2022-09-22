

class BitArrayIterator : System.Collections.IEnumerator {
    [bool[]] hidden $bitarray
    [bool] hidden $minusOne = $true

    BitArrayIterator([int]$bits) {
        if($bits -lt 1) {
            throw "Invalid Value"
        }

        $this.bitarray = new-object bool[] $bits
        $this.Reset()
    }

    [void] Reset() {
        $len = $this.bitarray.Count
        for($i = 0; $i -lt $len; $i++) {
            $this.bitarray[$i] = $false
        }
        $this.minusOne = $true
    }

    # Enumerators are positioned before the first element
    # until the first MoveNext() call.
    [bool] MoveNext() {
        if($this.minusOne -eq $true) {
            $this.minusOne = $false
            return $true
        }
        $len = $this.bitarray.Count
        for($i = $len - 1; $i -ge 0; $i--) {
            if($this.bitarray[$i] -eq $true) {
                $this.bitarray[$i] = $false
            }
            else {
                $this.bitarray[$i] = $true
                return $true;
            }
        }
        return $false
    }

    [object] get_Current() {
        return $this.bitarray
    }

    [bool] Skip([int]$num) {
        if($num -lt 1) {
            return $false
        }
        if($this.minusOne) {
            $this.minusOne = $false
            if($num -eq 1) {
                return $true
            }
            $num--
        }
        for($i = 0; $i -lt $num; $i++) {
            if(-not $this.MoveNext()) {
                return $false
            }
        }
        return $true
    }

    [bool] SetPosition([bool[]]$bits) {
        if($bits.Count -eq $this.bitarray.Count) {
            $this.bitarray = $bits
            return $true
        }
        return $false
    }
}


$e = [BitArrayIterator]::new(4)
foreach ($i in $e) {
    $len = $i.Count
    for($ii = 0; $ii -lt $len; $ii++) {
        if($i[$ii]) {
            Write-Host -NoNewline "1"
        }
        else {
            Write-Host -NoNewline "0"
        }
        
    }
    Write-Host "     $i"
}

Write-Host "-------"

$e.Reset()
#$e.Skip(12) | Out-Null
while($e.MoveNext()) {
    $i = $e.get_Current();

    $len = $i.Count
    for($ii = 0; $ii -lt $len; $ii++) {
        if($i[$ii]) {
            Write-Host -NoNewline "1"
        }
        else {
            Write-Host -NoNewline "0"
        }
        
    }
    Write-Host "     $i"
    $e.Skip(1) | Out-Null  # just print every second number
}