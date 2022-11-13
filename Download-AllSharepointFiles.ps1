Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
# Function to Download All Files from a SharePoint Library
Function DownloadFiles($SPFolderURL, $LocalFolderPath)
{
        #Get the Source SharePoint Folder
        $SPFolder = $web.GetFolder($SPFolderURL)
 
        $LocalFolderPath = Join-Path $LocalFolderPath $SPFolder.Name 
        #Ensure the destination local folder exists! 
        if (!(Test-Path -path $LocalFolderPath))
        {    
             #If it doesn't exist, Create
             $LocalFolder = New-Item $LocalFolderPath -type directory 
        }
 
     #Loop through each file in the folder and download it to Destination
     foreach ($File in $SPFolder.Files) 
     {
         #Download the file
         $Data = $File.OpenBinary()
         $FilePath= Join-Path $LocalFolderPath $File.Name
         [System.IO.File]::WriteAllBytes($FilePath, $data)
     }
 
     #Process the Sub Folders & Recursively call the function
     foreach ($SubFolder in $SPFolder.SubFolders)
     {
           if($SubFolder.Name -ne "Forms") #Leave "Forms" Folder
             {
                  #Call the function Recursively
                  DownloadFiles $SubFolder $LocalFolderPath
             }
     }
  
}
 
#Get the Source Web
$Web = Get-SPWeb "https://sharepoint.crescent.com/sites/Operations"
  
#Get the Source SharePoint Library's Root Folder
$SourceLibrary =  $Web.Lists["Design Documents"].RootFolder
 
#Local Folder, where the Files to be downloaded 
$DestinationPath = "C:\Test"
 
#Call the Download Files Function
DownloadFiles $SourceLibrary $DestinationPath