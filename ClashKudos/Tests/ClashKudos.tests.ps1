<#
 # Test the module itself for consistency.
 #>

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$manifestPath = (Join-Path $root -ChildPath '..' |Join-Path -ChildPath 'ClashKudos.psd1')
$manifestFile = $null

Describe "Module Manifest" {
    Context 'Manifest Integrity' {
        it 'should be a valid manifest' {
            {
                $script:manifestFile = (Test-ModuleManifest -Path $script:manifestPath -ErrorAction Stop -WarningAction SilentlyContinue)
            } | Should Not Throw
        }

        it 'should contain no warnings' {
            {Test-ModuleManifest -Path $script:manifestPath -ErrorAction SilentlyContinue -WarningAction Stop} | Should Not Throw
        }
    }

    Context 'Manifest Content' {
        it 'should have the correct name' {
            $script:manifestFile.Name | Should be 'ClashKudos'
        }

        it 'should have the correct GUID' {
            $script:manifestFile.Guid |Should be '47288287-ebe3-4c10-8b29-c432d4896342'
        }

        it 'should have a valid description' {
            $script:manifestFile.Description | Should Not BeNullOrEmpty
        }
    }

    Context 'Module Functions/Style' {

        #============================================================================
        # Code style and ideals mimic Pester. Much of the code used below is courtesy
        # of the Pester team themselves.
        #============================================================================

        Import-Module $script:manifestPath

        #Module files/tests
        $files = @(
            Get-ChildItem $root | where {$_.Extension -in ('.ps1')}
            Get-ChildItem (Join-Path $root '..') | where {$_.Extension -in ('.ps1','.psm1','.psd1')}
        )

        it 'All public funcitons use cmdletbinding()' {
            $result = Get-Command -Module ClashKudos | `
                ? { -not $_.CmdletBinding }

            $result | Should BeNullOrEmpty
        }

        it 'All public functions have help documentation' {
            $result = Get-Command -Module ClashKudos | `
                ? { -not ($_ | Get-Help).Description}

            $result | Should BeNullOrEmpty
        }

        it 'All modules and tests contain no trailing whitespace' {
            $badLines = @(
                foreach ($file in $files)
                {
                    $lines = [System.IO.File]::ReadAllLines($file.FullName)
                    $lineCount = $lines.Count

                    for ($i = 0; $i -lt $lineCount; $i++)
                    {
                        if ($lines[$i] -match '\s+$') {
                            'File: {0}, Line: {1}' -f $file.FullName, ($i + 1)
                        }
                    }
                }
            )

            if ($badLines.Count -gt 0)
            {
                throw "The following $($badLines.Count) lines contain trailing whitespace: " +
                    "$([System.Environment]::NewLine)$([System.Environment]::NewLine)"+
                    "$($badLines -join "$([System.Environment]::NewLine)")"
            }
        }

        it 'All modules and tests use spaces for indentation' {
            $badLines = @(
                foreach ($file in $files)
                {
                    $lines = [System.IO.File]::ReadAllLines($file.FullName)
                    $lineCount = $lines.Count

                    for ($i = 0; $i -lt $lineCount; $i++)
                    {
                        if ($lines[$i] -match '^[  ]*\t|^\t|^\t[  ]*') {
                            'File: {0}, Line: {1}' -f $file.FullName, ($i + 1)
                        }
                    }
                }
            )

            if ($badLines.Count -gt 0)
            {
                throw "The following $($badLines.Count) lines start with a tab character: "+
                "$([System.Environment]::NewLine)$([System.Environment]::NewLine)$($badLines -join "$([System.Environment]::NewLine)")"
            }
        }

        it 'All modules and tests end with a newline' {
            $badFiles = @(
                foreach ($file in $files) {
                    $string = [System.IO.File]::ReadAllText($file.FullName)
                    if ($string.Length -gt 0 -and $string[-1] -ne "`n") {
                        $file.FullName
                    }
                }
            )

            if ($badFiles.Count -gt 0) {
                throw "The following files do not end with a newline: " +
                "$([System.Environment]::NewLine)$([System.Environment]::NewLine)$($badFiles -join "$([System.Environment]::NewLine)")"
            }
        }
    }
}
