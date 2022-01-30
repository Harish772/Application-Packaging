#0bject Members and variables 
#variables are very flexible 
$Service=Get-Service -Name bits 
$Service | GM 
$Service.Status 
$Service.stop() 
$Msg="service Name is $($service.name.TOUpper())" 
$Msg
#working with multiple objects 
$Services=Get-service 
$Services[0]
$Services[0].Status
#[-1] indicates the Last one
$Service[-1].Name
"Service Name is $($Services[4].DisplayName)"
"Service Name is $($Services[4].Name.ToUpper())"

#The range operator is '..'
1..4
$Services[1..5]
$Services[5..1]
$Services.Count
#[-1..-5] Indicates last 5 in the column 
$Services[-1..-5]