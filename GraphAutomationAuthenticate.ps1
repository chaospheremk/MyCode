$TenantId = "092ec6d1-91bb-41cc-a354-90068582d5c8"
$ApplicationId = "9831de77-e353-4cda-b5f9-16580cdbb8ea"
$CertificateThumbprint = "B747A10321E5220D091244321B4D9D8D5C99ADE9"
 
Connect-MgGraph -ClientID $ApplicationId -TenantId $TenantId -CertificateThumbprint $CertificateThumbprint