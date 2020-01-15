#requires -Module ModuleBuilder, Configuration
[CmdletBinding()]
param(
    # A specific folder to build into
    $OutputDirectory = $PSScriptRoot,

    # The version of the output module
    [Alias("ModuleVersion")]
    [string]$SemVer
)
Push-Location $PSScriptRoot -StackName BuildTestStack

if (!$SemVer -and (Get-Command gitversion -ErrorAction Ignore)) {
    $PSBoundParameters['SemVer'] = gitversion -showvariable nugetversion
}

try {
    ## Build the actual module
    $MetadataInfo = Build-Module -SourcePath .\Source\Metadata `
                        -Target CleanBuild -Passthru `
                        @PSBoundParameters

    $ConfigurationInfo = Build-Module -SourcePath .\Source\Configuration `
                        -Target Build -Passthru `
                        @PSBoundParameters

    # Because this is a double-module, combine the exports of both modules
    Update-Metadata -Path $ConfigurationInfo.Path -PropertyName FunctionsToExport `
                    -Value @(
                        $MetadataInfo.ExportedFunctions.Keys
                        $ConfigurationInfo.ExportedFunctions.Keys
                        # @('*')
                    )

    $ConfigurationInfo

    # Remove the extra metadata file
    Remove-Item $MetadataInfo.Path
} finally {
    Pop-Location -StackName BuildTestStack
}