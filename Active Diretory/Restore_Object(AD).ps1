# Modificado por Jamilton Santana
# Scrip para recuperar(excluidos por acidente) usuários , OUs , e Objetos do ActiveDirectory
# Links para consulta: 
# Fonte: https://technet.microsoft.com/en-us/library/179bd37c-5a8a-480e-81dc-ff648a4429a0
# http://www.mcsesolution.com/Windows-Server-2008-R2/lixeira-do-active-directory.html

Import-Module ActiveDirectory

Enable-ADOptionalFeature –Identity "CN=Recycle Bin Feature,CN=Optional Features,CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,DC=YOUDOMAIN,DC=com" –Scope ForestOrConfigurationSet –Target "YOUDOMAIN.com"

Get-ADOptionalFeature -Filter 'name -like "Recycle Bin Feature"'

Restaurar User = Get-ADObject -ldapFilter:"(sAMAccountName=Samid)" –IncludeDeletedObjects | Restore-ADObject

Restaurar OU = Get-ADObject -ldapFilter:"(msDS-LastKnownRDN=OU Name)" –IncludeDeletedObjects | Restore-ADObject

Restaurar Grupo = Get-ADObject -ldapFilter:"(msDS-LastKnownRDN=Group Name)" –IncludeDeletedObjects | Restore-ADObject

Restaurar Computador = Get-ADObject -ldapFilter:"(msDS-LastKnownRDN=Computer Name)" –IncludeDeletedObjects | Restore-ADObject