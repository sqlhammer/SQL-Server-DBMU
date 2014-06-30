[CmdletBinding(DefaultParameterSetName="RootDirectory",
               SupportsShouldProcess=$TRUE)]
Param
(
    [Parameter(ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true,
               HelpMessage="Path to connection strings file (include file name)...")]
    [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
    [string]$ConnectionStringsFilePath=$null,
    [Parameter(ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true,
               HelpMessage="Path to *.publish.xml file (include file name)...")]
    [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
    [string]$PublishXMLFilePath=(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent) + "\Mass-Deploy.publish.xml",
    [Parameter(ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true,
               HelpMessage="Path to *.dacpac file (include file name)...")]
    [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
    [string]$SourceFilePath=(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent) + "\Utility.dacpac",
    [Parameter(ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true,
               HelpMessage="Path to Deploy Report (*.xml) file (include file name)...")]
    [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
    [string]$DeployReportFilePath=(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent) + "\DeployReport.xml",
    [Parameter(ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true,
               HelpMessage="Service Account (i.e. LIBERTY\Utility)...")]
    [string]$ServiceAccount=$null,
    [Parameter(Mandatory=$true,
               ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true,
               HelpMessage="Deployment environment must be DEV, SIT, QA, or PROD...")]
    [ValidateSet("DEV","SIT","QA","PROD")]
    [string]$Environment,
    [Parameter(Mandatory=$true,
               ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true,
               HelpMessage="Service Account Password...")]
    [Security.SecureString]$SecureServiceAccountPassword,
    [Parameter(Mandatory=$true,
               ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true,
               HelpMessage="Deployment version...")]
    [ValidatePattern('^\d+\.\d+\.\d$')]
    [string]$Version,
    [switch]$Deploy
)

####################################################################################################
# Main()
####################################################################################################

    ##########################
    # Declare
    ##########################

    # set default path context
    $scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
    
    # decrypt SecureServiceAccountPassword
    [string]$ServiceAccountPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureServiceAccountPassword))

    # set environment specific config
    switch ($Environment) {

        "DEV"
            {
                if(!$ConnectionStringsFilePath) {
                    $ConnectionStringsFilePath="$scriptDir\DEVConnectionStrings\ConnectionStrings.txt"
                }

                if(!$ServiceAccount) {
                    $ServiceAccount="LIBERTY\DevUtility"
                }
            }

        "SIT"
            {
                if(!$ConnectionStringsFilePath) {
                    $ConnectionStringsFilePath="$scriptDir\SITConnectionStrings\ConnectionStrings.txt"
                }

                if(!$ServiceAccount) {
                    $ServiceAccount="LIBERTY\SITUtility"
                }
            }

        "QA"
            {
                if(!$ConnectionStringsFilePath) {
                    $ConnectionStringsFilePath="$scriptDir\QAConnectionStrings\ConnectionStrings.txt"
                }

                if(!$ServiceAccount) {
                    $ServiceAccount="LIBERTY\QAUtility"
                }
            }

        "PROD"
            {
                if(!$ConnectionStringsFilePath) {
                    $ConnectionStringsFilePath="$scriptDir\PRODConnectionStrings\ConnectionStrings.txt"
                }

                if(!$ServiceAccount) {
                    $ServiceAccount="LIBERTY\Utility"
                }
            }
        
    }

    if( (!$ConnectionStringsFilePath) ) {
        throw "Invalid Connection String Path: $ConnectionStringsFilePath"
    }

     # create deployment configuration [hashtable]
    [hashtable]$deployConfig_ht = @{"ConnectStringsPath"=$ConnectionStringsFilePath;
                                    "PublishXmlPath"=$PublishXMLFilePath;
                                    "SourceFilePath"=$SourceFilePath;
                                    "DeployReportFilePath"=$DeployReportFilePath;
                                    "ServiceAccount"=$ServiceAccount;
                                    "ServiceAccountPassword"=$ServiceAccountPassword;
                                    "Environment"=$Environment;
                                    "Version"=$Version}

    # hashes - used for Select-Xml cmdlet
    [hashtable]$nameSpaces = @{"nmsp1"="http://schemas.microsoft.com/developer/msbuild/2003";
                               "nmsp2"="http://schemas.microsoft.com/sqlserver/dac/DeployReport/2012/02"}

    [hashtable]$xPaths = @{"publishXml"=@{"TargetConnectionString"="//nmsp1:TargetConnectionString";
                                          "Environment"='//nmsp1:SqlCmdVariable[@Include="Environment"]/nmsp1:Value';
                                          "ServiceAccount"='//nmsp1:SqlCmdVariable[@Include="ServiceAccount"]/nmsp1:Value';
                                          "ServiceAccountPassword"='//nmsp1:SqlCmdVariable[@Include="ServiceAccountPassword"]/nmsp1:Value';
                                          "Version"='//nmsp1:SqlCmdVariable[@Include="Version"]/nmsp1:Value'};
                           "deployReportXml"=@{"Alerts"="//nmsp2:Alerts"}
                          }
    
    # script block objects created from strings
    $depRptString = "$scriptDir\SsdtDeploymentTool\Redistribute\SqlPackage.exe /Action:DeployReport /SourceFile:`"" +
                     $deployConfig_ht.SourceFilePath + "`" /Profile:`"" + $deployConfig_ht.PublishXmlPath + "`" /OutputPath:`"" +
                     $deployConfig_ht.DeployReportFilePath + "`""

    $depRptExe = [ScriptBlock]::Create($depRptString)

    $deployString = "$scriptDir\SsdtDeploymentTool\Redistribute\SqlPackage.exe /Action:Publish /SourceFile:`"" +
                     $deployConfig_ht.SourceFilePath + "`" /Profile:`"" + $deployConfig_ht.PublishXmlPath + "`""

    $deployExe = [ScriptBlock]::Create($deployString)

    # connection string file contents
    $connectionStrings = (Get-Content -Path $ConnectionStringsFilePath)

    # *.publish.xml file contents
    [xml]$xmlContent = [xml](Get-Content -Path $PublishXMLFilePath)

    # progress bar parameter values
    $countComplete = 0

    $countMax = $connectionStrings.Length

    $PercentComplete = 0

    # error log file path
    $DeployLogFilePath = $scriptDir + "\deployLog.txt"
        
     
    ##########################
    # Begin
    ##########################

    # edit *.publish.xml with deployment configuration values
    $xPaths.publishXml.GetEnumerator() | foreach {
        
        ( Select-Xml -Xml $xmlContent -XPath $_.value -Namespace $nameSpaces ).Node.InnerText = $deployConfig_ht["$($_.key)"]

        $xmlContent.Save($deployConfig_ht.PublishXmlPath)

    }

    if($Deploy) {
    
        # clear out deployLog.txt
        if(Test-Path -Path $DeployLogFilePath -PathType Leaf) {

            Clear-Content $DeployLogFilePath

        }

        # header for the deployLog.txt file
        Add-Content $DeployLogFilePath -Value "$((Get-Date).DateTime): Mass database deployment to the $(($deployConfig_ht).Environment) environment"

    }
    
    # loop through server list and create pre-deployment report and then conditionally deploy to current server
    foreach($connectString in $connectionStrings) {

        ( Select-Xml -Xml $xmlContent -XPath $xPaths."publishXml"."TargetConnectionString" -Namespace $nameSpaces ).Node.InnerText = "Data Source=" + $connectString + ";Integrated Security=True;Pooling=False"

        $xmlContent.Save($PublishXMLFilePath)

        $PercentComplete = [math]::Round($CountComplete / $CountMax * 100)

        $activity = "Deploying Utility Database to " + $deployConfig_ht.Environment + " Environment..."

        Write-Progress -Activity $activity -PercentComplete ( $PercentComplete ) -CurrentOperation "$PercentComplete `% done." -Status "Currently creating pre-deployment report for $connectString..."

        Invoke-Command $depRptExe

        if( $LASTEXITCODE -ne 0 ) {

            return

        }

        if($Deploy) {

            # append current server to deployLog.txt file
            Add-Content $DeployLogFilePath "[$connectString]`n"

            # server deployment started message
            Write-Host "Deploying to $connectString...`n"
            
            Write-Progress -Activity $activity -PercentComplete ( $PercentComplete ) -CurrentOperation "$PercentComplete `% done." -Status "Currently deploying to $connectString..."

            [array]$output = Invoke-Command $deployExe

            if( $LASTEXITCODE -ne 0 ) {

                return

            }

            foreach($result in $output) {

                Add-Content $DeployLogFilePath "`t$result`n"

            }
            
            # server deployment complete message
            Write-Host "$connectString deployment complete...`n`n"

        }

        $CountComplete++

    }
