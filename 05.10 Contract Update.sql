---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Contract Load Script	
--- Customer: PowerDMS PlanIt Migration
--- Primary Developer: Patrick Bowen
--- Secondary Developers:  
--- Created Date: 13 June 2022
--- Last Updated: 
--- Change Log: 
--- Prerequisites:
--- 1. Disable Workflow Rule "Activate Contract After Billing"
--- 2. Disable Workflow Rule "Activated Contract = Renewal Quoted/Forcast"
--- 3. Disable Workflow Rule "Contract - Expired"
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Replicate Data
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;

EXEC SF_Refresh 'INSERT_LINKED_SERVER_NAME', 'Account', 'yes'
EXEC SF_Refresh 'INSERT_LINKED_SERVER_NAME', 'PriceBook2', 'yes'
EXEC SF_Refresh 'INSERT_LINKED_SERVER_NAME', 'RecordType', 'yes'
EXEC SF_Refresh 'INSERT_LINKED_SERVER_NAME', 'sbqq__Quote__c', 'yes'
EXEC SF_Refresh 'INSERT_LINKED_SERVER_NAME', 'Opportunity', 'yes'
EXEC SF_Refresh 'INSERT_LINKED_SERVER_NAME', 'Contract', 'yes'


---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Contract_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE [Contract_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;

WITH Contract_CTE as 
(
	Select 
	Row_Number() OVER (Partition by a.[Correct SF Account ID], a.[End Date] Order By a.[start date], a.[Product] Asc) as RowNum,
	a.[Correct SF Account ID] as AccountID, a.[End Date] as EndDate,
	a.*
	FROM [Insert_SOURCE_Database_Name_Here].[dbo].[MasterSubscriptions] a
),
TERM_CTE as
(
	Select a.[Correct SF Account ID] as AccountID, a.[End Date] as EndDate, Round(Max(a.[sub term]), 0) as Term, min(a.[Start Date]) as StartDate,
	SUM(ARR) as ARR
	FROM [Insert_SOURCE_Database_Name_Here].[dbo].[MasterSubscriptions] a
	GROUP BY a.[Correct SF Account ID], a.[End Date]
)

Select 
	Cast('' as nvarchar(18)) as Id,
	CAST('' as nvarchar(255)) as Error,
	Acct.ID as AccountId, 
	PB.Id as Pricebook2Id, 
	Term.[StartDate] as StartDate, 
	Term.Term as ContractTerm, 
	'Draft' as [Status],
	'Migrated PlanIt Contract' as [Description], 
	RT.Id as RecordTypeId, 
	Oppty.Id as SBQQ__Opportunity__c, 
	Qte.Id as SBQQ__Quote__c, 
	'true' as SBQQ__RenewalForecast__c, 
	'true' as SBQQ__RenewalQuoted__c, 
	'12' as SBQQ__RenewalTerm__c, 
	'Contract Based' as RenewalModel__c, 
	'Uplift' as RenewalPricingMethod__c, 
	Term.[ARR] as ARR__c, 
	'Latest End Date' as SBQQ__AmendmentRenewalBehavior__c, 
	'true' as Auto_RUN__c, 
	Concat(Acct.Id, ':', Convert(varchar(10), a.[End Date], 120) ) as Migration_id2__c,
	'Neocol Migration: ' + Convert(varchar, getdate(), 121) as Migration_Status__c
	INTO Contract_Load
	FROM Contract_CTE a
	LEFT OUTER JOIN Account Acct ON a.AccountID = Acct.ID 
	LEFT OUTER JOIN Term_CTE Term ON a.AccountID = Term.AccountID and a.EndDate = Term.EndDate
	LEFT OUTER JOIN Pricebook2 PB ON PB.[Name] = 'PowerDMS Price book (New)'
	LEFT OUTER JOIN RecordType RT ON RT.[Name] = 'Standard Contract' and SobjectType = 'Contract'
	LEFT OUTER JOIN sbqq__Quote__c Qte ON Concat(Acct.Id, ':', Convert(varchar(10), a.[End Date], 120)) = Qte.Migration_ID__c
	LEFT OUTER JOIN Opportunity Oppty ON Concat(Acct.Id, ':', Convert(varchar(10), a.[End Date], 120)) = Oppty.Migration_ID__c
	LEFT OUTER JOIN [Contract] Contr ON Concat(Acct.Id, ':', Convert(varchar(10), a.[End Date], 120)) = Contr.Migration_ID2__c
	WHERE a.RowNum = 1
	and Contr.ID IS NULL
	AND isnull(a.[Ignore], '') <> '1'
	AND a.AccountID <> '0012K00001hoG6XQAU'
	ORDER BY Acct.ID

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE [Contract_Load]
ADD [Sort] int IDENTITY (1,1)

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;
EXEC SF_Tableloader 'Upsert: bulkapi, batchsize(10)', 'INSERT_LINKED_SERVER_NAME', 'Contract_Load', 'Migration_Id2__c'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- Select error, * from Contract_Load_Result a where error not like '%success%'