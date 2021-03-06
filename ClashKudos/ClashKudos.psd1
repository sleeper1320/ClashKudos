@{

# Script module or binary module file associated with this manifest.
RootModule = 'Config.psm1'

# Version number of this module.
ModuleVersion = '0.1'

# ID used to uniquely identify this module
GUID = '47288287-ebe3-4c10-8b29-c432d4896342'

# Author of this module
Author = 'sleepy'

# Company or vendor of this module
#CompanyName = ''

# Copyright statement for this module
#Copyright = ''

# Description of the functionality provided by this module
Description = "
    This module provides the necessary components to interface with SuperCell's Developer API and,
    when requested, will call Discord style webhooks to give a shoutout/kudos to the most contributing
    player.
    "

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
#RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @(
    'Config.psm1',
    'Discord.psm1',
    'PlayerClanGames',
    'PlayerDonations.psm1',
    'PlayerFetch.psm1',
    'SC API.psm1'
)

# Functions to export from this module
FunctionsToExport =
    'Get-*',
    'Invoke-SCAPICall',
    'Set-*',
    'Open-KudosConfig',
    'Publish-KudosClanGames',
    'Publish-KudosBestDonator',
    'Save-KudosConfig',
    'Send-WebhookMessage',
    'Test-SCToken',
    'Test-SCTokenIP',
    'Update-PlayerData'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
ModuleList = @(
    'Config.psm1',
    'Discord.psm1',
    'PlayerClanGames',
    'PlayerDonations.psm1',
    'PlayerFetch.psm1',
    'SC API.psm1'
)

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess
#PrivateData = @{}

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''
}
