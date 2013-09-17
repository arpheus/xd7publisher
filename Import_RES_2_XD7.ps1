#####################################################################
##                     Application Publisher                       ##
##               from Workspace Manager to XenDesktop 7            ##
##                                                                 ##
##                         Version : 1.2                           ##
##                        Date : 29/08/13                          ##
#####################################################################

#######################  PARAMETERS  #########################
##
##
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
    [String]$BrokerAdress,

    [Parameter(Mandatory=$False,Position=1)]
    [String]$BBPath,

    [Parameter(Mandatory=$False)]
    [switch]$AddMandatoryKeyword
)


#########################  INFOS #############################
##
## This script use informations from a Workspace Manager 2012
## building block to publish pwrgate.exe with the GUID of the
## application.
## It has to be launched from a Workspace Manager server, with
## XenDesktop 7 Broker SDK and Citrix.Common.Commands installed.
##
## Please specify a XD7 broker hostname or IP adress : 
##
if($BrokerAdress -eq $null){
##
       $BrokerAdress = "BrokerHostNameOrIPAdress"
##
}
##
## Do you want published applications to be automatically
## displayed on StoreFront ? 
## (KEYWORD=Auto)
##
if($AddMandatoryKeyword -eq $False){
##
       $AddMandatoryKeyword = $False
##
}
##
## [Optional] SCRIPT PARAM : Path to building block file
##
## If no path is specified, the script try to find the building
## block in its directory.
##
## Icons are imported from the RES IconCache directory.
##
## Authorized users are imported from RES configuration.



###################  FUNCTIONS #####################

#Teste un fichier XML, cherche un noeud "respowerfuse"
function IsBuildingBlock {
    
    param ($path)

    $xmlObj = New-Object -TypeName XML
    try{ $xmlObj.load($path) } catch { Write-Host "Unable to load specified XML"; return $False }
  
    $test = Select-XML -Xml $xmlObj -XPath '//respowerfuse'
        
    if($test.count -ne 0){
        
        return $True
            
    } else {

        return $False

    }

}

#####################  SCRIPT  #######################


if($BBPath -ne ""){

    #Le chemin du Buiding Block a été passé en argument.
    #On teste si le chemin est valide
    if(Test-Path $BBPath){

        #Chemin valide, on teste le fichier XML
        if(IsBuildingBlock($BBPath)){

            #Ok

        } else {

            throw "Specified XML file is not a valid building block"

        }

    } else {

       throw "Specified building block does not exist. Try to copy it in the script folder."

    }

#Pas d'argument, recherche dans le dossier 
} else {

    #Recherche des fichiers XML du dossier
    $ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
    $xmlFiles = Get-ChildItem $ScriptDir -filter "*.xml"

    foreach ($xmlFile in $xmlFiles){

        #test du fichier xml
        if(IsBuildingBlock($xmlFile.FullName)){
            
            $BBPath = $xmlFile.FullName
            break

        }
    }
    
    #Un fichier BB a t'il été trouvé ?
    if($BBPath -eq ""){

        throw "No building block file found in the script folder. Try to specify a BB path as argument (BBPath)."

    }
}


Add-PSSnapin Citrix*
$dgroups = Get-BrokerDesktopGroup -AdminAddress $BrokerAdress
$choice = $null
$dgroup = $null

if($dgroups -ne $null){

    echo "`n`n         Choose the Delivery Group to publish the apps to`n"
    $dgroups | % {$pos=0} {$pos.ToString() + " - " + $_.Name; $pos++}
    $choice = Read-Host "`n Choice "
    "`n`n`n`n"

    if($choice -lt $dgroups.Length){

        $dgroup = $dgroups[$choice]

    } else {

        throw "Invalid index."

    }

} else {

    throw "No Delivery Group find."

}

#On charge le fichier building Block
$bbObj = New-Object -TypeName XML
$bbObj.load($bbPath)

foreach ($app in $bbObj.respowerfuse.buildingblock.application){

    ########Creation d'une app
    #Récupérer les infos du BB
    $Name = $app.configuration.title
    $CommandLineExe = "C:\Program Files (x86)\RES Software\Workspace Manager\pwrgate.exe"
    $ApplicationType = "HostedOnDesktop"
    $BrowserName = $app.configuration.title
    $CommandLineArg = $app.guid
    $Description = @{$true="KEYWORDS:Auto      "+$app.configuration.description;$false=$app.configuration.description}[$AddMandatoryKeyword]
    $PublishedName = $app.configuration.title
    $WorkingDirectory = "C:\Program Files (x86)\RES Software\Workspace Manager\"

    $AccessType = $app.accesscontrol.accesstype
    $restriction = $AccessType -eq "group"
    
    $Icon = $null

    #Le nom de l'application doit être unique dans le site XenDesktop
    if((Test-BrokerApplicationNameAvailable -Name $Name -AdminAddress $BrokerAdress).Available){

        Write-Host "`n+  Publishing app $Name to Delivery Group :  $($dgroup.Name)" -foregroundcolor "Green"
        
        #Publication de l'application
         if($publishedApp = New-BrokerApplication -Name $Name -CommandLineExecutable $CommandLineExe -DesktopGroup $dgroup -ApplicationType $ApplicationType -BrowserName $BrowserName -CommandLineArgument $CommandLineArg -Description $Description -Enabled $True -PublishedName $PublishedName -Visible $True -WorkingDirectory $WorkingDirectory -UserFilterEnabled $Restriction -AdminAddress $BrokerAdress){
            
            #Gérer l'icône
            $iconPath = "C:\Program Files (x86)\RES Software\Workspace Manager\Data\DBCache\IconCache\$($app.guid)_32_256.ico"

            if(Test-Path $iconPath){

                #L'icône est dans le cache des icônes.
                $EncodedIcon = Get-CtxIcon -IconData (Get-Content $iconPath -Encoding Byte)
                $Icon = New-BrokerIcon -EncodedIconData $EncodedIcon.EncodedIconData
                Set-BrokerApplication -InputObject $publishedApp -IconUid $Icon.Uid
                Write-Host "`n     - Application icon succesfully imported"

            } else {

                Write-Host "`n     - No icon found for application" -foregroundcolor "Red"

            }

            #Gérer les utilisateurs autorisés
            if($AccessType -eq "group"){
                
                Write-Host "`n     - Defining authorized users for app : $Name"
                #On récupère la liste des utilisateurs autorisés
                $AuthorizedUsers = $app.accesscontrol.grouplist.group

                foreach($AuthorizedUser in $AuthorizedUsers){
                    
                    try{

                        Add-BrokerUser $AuthorizedUser."#text" -Application $publishedApp
                        Write-Host "              + Added user $($AuthorizedUser."#text")"

                    } catch {

                        Write-Host "              + Error adding user $($AuthorizedUser."#text")" -foregroundcolor "Red"

                    }
                }

            } else {
                
                Write-Host "`n     - No user restriction set." -ForegroundColor "Green"

            }
         }

    } else {

        Write-Host "`n+  Skipped application $Name because app name is already used." -foregroundcolor "yellow"


    }
}
Write-Host "`n`n ---------- End of script -----------"
Read-Host