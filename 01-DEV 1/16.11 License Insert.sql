---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: License Load Script	
--- Customer: Redwood
--- Primary Developer: Ajay 
--- Secondary Developers:  
--- Created Date: 11/25/2023
--- Last Updated: 
--- Change Log: 
--- Prerequisites:
--- 
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Replicate Data
---------------------------------------------------------------------------------
USE SourceQA;

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Account','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Asset','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'SBQQ__Subscription__c','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Contract' ,'PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Product2','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','RW_Product_License_Component__c','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','RW_License_Component__c','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','RW_Component_License_Key__c','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','RW_Subscription_Instance__c','PKCHUNK'



---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'RW_Subscription_Instance__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[RW_Subscription_Instance__c_Load]


---------------------------------------------------------------------------------
-- Create Staging Table for Subscription Instance
---------------------------------------------------------------------------------
Select
	CAST('' AS nvarchar(18)) AS [ID]
	,CAST('' as nvarchar(2000)) as Error
	,sub.Id as Subscription__c
	,MAX(sub.CurrencyIsoCode) as CurrencyIsoCode
	,MAX(prod.name) as ProductName
	,MAX(prod.Id) as ProdId
	,MAX(sub.SBQQ__StartDate__c) as StartDate
	,MAX(sub.SBQQ__EndDate__c) as EndDate
	,MAX(a.SerialNumber) as SerialNumber

into StageQA.dbo.[RW_Subscription_Instance__c_Load]

FROM SourceQA.dbo.Asset a
	left join SourceQA.dbo.Account acc
		on acc.Id = a.AccountId
	left join SourceQA.dbo.SBQQ__Subscription__c sub
		on sub.Id = a.Subscription2__c
	left join SourceQA.dbo.Contract con
		on con.Id = sub.SBQQ__Contract__c
	left join SourceQA.dbo.Product2 prod
		on prod.Id = sub.SBQQ__Product__c

WHERE con.EndDate > getdate()
	and con.Status = 'Activated'
	and acc.Test_Account__c = 'false'
	--and sub.sbqq__bundled__c = 'false'
	--and prod.IsActive = 'true'
	--and sub.SBQQ__ProductOption__c = NULL
	--and con.Id = '8003t000008OEHMAA4'
group by sub.Id



select * from StageQA.dbo.[RW_Subscription_Instance__c_Load] where Subscription__c = 'a3I3t0000029EqdEAE'

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC StageQA.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(200)','SANDBOX_QA','RW_Subscription_Instance__c_Load'


---------------------------------------------------------------------------------
-- Replicate Data
---------------------------------------------------------------------------------
USE SourceQA;

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','RW_Subscription_Instance__c','PKCHUNK'

---------------------------------------------------------------------------------------------------------------------------------------------
-- Component License key Insert
---------------------------------------------------------------------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'RW_Component_License_Key__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[RW_Component_License_Key__c_Load]

---------------------------------------------------------------------------------
-- Create Staging Table for Component License Key
---------------------------------------------------------------------------------
Select
	CAST('' AS nvarchar(18)) AS [ID]
	,CAST('' as nvarchar(2000)) as Error
	,left(Prod.Name, 80) as Name
	,a.Subscription2__c as Subscription__c
	,PLC.Id as Product_License_Component__c
	,LC.Name as LicenseComponentName
	,PLC.Name as ProductLicenseComponentName
	,a.SerialNumber as License_Key__c
	,SI.Id as Subscription_Instance__c
	,sub.Name as SubscriptionName
	,con.ContractNumber as ContractNumber

into StageQA.dbo.[RW_Component_License_Key__c_Load]

FROM SourceQA.dbo.Asset a
	inner join SourceQA.dbo.SBQQ__Subscription__c sub
		on sub.Id = a.Subscription2__c
	left join SourceQA.dbo.RW_Subscription_Instance__c SI
		on SI.Subscription__c = Sub.Id
	left join SourceQA.dbo.Product2 prod
		on prod.Id = sub.SBQQ__Product__c 
	left join SourceQA.dbo.RW_Product_License_Component__c PLC 
		on prod.Id = PLC.Product__c
	left join SourceQA.dbo.RW_License_Component__c LC
		on LC.Id = PLC.License_Component__c
	left join SourceQA.dbo.Contract con
		on con.Id = sub.SBQQ__Contract__c
	left join SourceQA.dbo.Account acc
		on acc.Id = a.AccountId

WHERE con.EndDate > getdate()
	and con.Status = 'Activated'
	--and con.ContractNumber = '00003441'
	--and sub.Id = 'a3I3t000003SfGiEAK'
	and (prod.Name like (LC.Name+'%')
	or prod.Name = LC.Name)
	and acc.Test_Account__c = 'false'
Order by Prod.Name


---------------------------------------------------------------------------------
-- Validation
---------------------------------------------------------------------------------

select * from StageQA.dbo.[RW_Component_License_Key__c_Load] order by License_Key__c asc

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC StageQA.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(200)','SANDBOX_QA','RW_Component_License_Key__c_Load'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

Select error, * from RW_Component_License_Key__c_Load_Result a where error not like '%success%'
