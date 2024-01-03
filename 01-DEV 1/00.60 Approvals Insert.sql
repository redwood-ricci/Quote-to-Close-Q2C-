---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Dimensions Insert
--- Customer: Redwood
--- Primary Developer: Ajay Santhosh
--- Secondary Developers:  
--- Created Date: 20/11/2023
--- Last Updated: 
--- Change Log: 
--- 	
--- Prerequisites:
--- 1. 
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Replicate Data
---------------------------------------------------------------------------------
USE [Source_Production_SALESFORCE]

EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','sbaa__ApprovalChain__c','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','sbaa__ApprovalRule__c ','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','sbaa__ApprovalCondition__c','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','sbaa__ApprovalVariable__c','PKCHUNK'

USE SourceQA

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','sbaa__ApprovalChain__c','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','sbaa__ApprovalRule__c ','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','sbaa__ApprovalCondition__c','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','sbaa__ApprovalVariable__c','PKCHUNK'

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'sbaa__ApprovalChain__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.[sbaa__ApprovalChain__c_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	Coalesce(ac_qa.Id, CAST('' AS nvarchar(18))) AS [ID] 
	,ac.Id as Approval_Chain_External_Id__c
	,ac.Name as Name
	,CAST('' as nvarchar(2000)) as Error

INTO Stage_Production_SALESFORCE.dbo.sbaa__ApprovalChain__c_Load

FROM SourceQA.dbo.sbaa__ApprovalChain__c ac
	left join Source_Production_SALESFORCE.dbo.sbaa__ApprovalChain__c ac_qa
		on ac_qa.Name = ac.Name

	
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from Stage_Production_SALESFORCE.dbo.sbaa__ApprovalChain__c_Load


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'UPSERT:bulkapi,batchsize(100)','Production_SALESFORCE','sbaa__ApprovalChain__c_Load', 'Id'


-------------------------------------------------------------------------------------
-- Approval Rules
-------------------------------------------------------------------------------------
---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'sbaa__ApprovalRule__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.[sbaa__ApprovalRule__c_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	Coalesce(ar_qa.Id, CAST('' AS nvarchar(18))) AS [ID] 
	,ac.Id as sbaa__ApprovalChain__c
	,ar.Id as Approval_Rule_External_Id__c
	,ar.Name as Name
	,ar.sbaa__Active__c as sbaa__Active__c
	,ar.sbaa__AdvancedCondition__c as sbaa__AdvancedCondition__c
	,ar.sbaa__ApprovalRecipients__c as sbaa__ApprovalRecipients__c
	,ar.sbaa__ApprovalStep__c as sbaa__ApprovalStep__c
	,ar_qa.sbaa__ApprovalTemplate__c as sbaa__ApprovalTemplate__c
	,ar_qa.sbaa__Approver__c as sbaa__Approver__c
	,ar_qa.sbaa__RecallTemplate__c as sbaa__RecallTemplate__c
	,ar_qa.sbaa__RejectionTemplate__c as sbaa__RejectionTemplate__c 
	,ar_qa.sbaa__RequestTemplate__c as sbaa__RequestTemplate__c 
	,ar.sbaa__RejectionRecipients__c as sbaa__RejectionRecipients__c
	,ar.sbaa__ApproverField__c as sbaa__ApproverField__c
	--,ar.sbaa__ConditionsMet__c as sbaa__ConditionsMet__c
	,ar.sbaa__RequireExplicitApproval__c as sbaa__RequireExplicitApproval__c
	,ar.sbaa__SmartApprovalIgnoresConditionsMet__c as sbaa__SmartApprovalIgnoresConditionsMet__c
	,ar.sbaa__TargetObject__c  as sbaa__TargetObject__c 
	,CAST('' as nvarchar(2000)) as Error

INTO Stage_Production_SALESFORCE.dbo.sbaa__ApprovalRule__c_Load

FROM SourceQA.dbo.sbaa__ApprovalRule__c ar
	left join Source_Production_SALESFORCE.dbo.sbaa__ApprovalRule__c ar_qa
		on ar_qa.Name = ar.Name
		and ar_qa.sbaa__ApprovalStep__c = ar.sbaa__ApprovalStep__c
	left join Source_Production_SALESFORCE.dbo.sbaa__ApprovalChain__c ac
		on ac.Approval_Chain_External_Id__c = ar.sbaa__ApprovalChain__c

	
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from Stage_Production_SALESFORCE.dbo.sbaa__ApprovalRule__c_Load


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'UPSERT:bulkapi,batchsize(100)','Production_SALESFORCE','sbaa__ApprovalRule__c_Load', 'Id'

Select error, count(*) as num from sbaa__ApprovalRule__c_Load a
where error not like '%success%'
group by error
order by num desc


-------------------------------------------------------------------------------------
-- Approval Variable
-------------------------------------------------------------------------------------
---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'sbaa__ApprovalVariable__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.sbaa__ApprovalVariable__c_Load

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	Coalesce(av_qa.Id, CAST('' AS nvarchar(18))) AS [ID] 
	,av.Id as Approval_Variable_External_Id__c 
	,av.Name as Name
	,av.sbaa__AggregateField__c as sbaa__AggregateField__c
	,av.sbaa__AggregateFunction__c as sbaa__AggregateFunction__c
	,av.sbaa__CombineWith__c as sbaa__CombineWith__c
	,av.sbaa__FilterValue__c as sbaa__FilterValue__c
	,av.sbaa__ListVariable__c as sbaa__ListVariable__c
	,av.sbaa__NetVariable__c as sbaa__NetVariable__c
	,av.sbaa__Operator__c as sbaa__Operator__c
	,av.sbaa__TargetObject__c as sbaa__TargetObject__c
	,av.sbaa__Type__c as sbaa__Type__c
	,av.sbaa__FilterField__c as sbaa__FilterField__c
	,CAST('' as nvarchar(2000)) as Error

INTO Stage_Production_SALESFORCE.dbo.sbaa__ApprovalVariable__c_Load

FROM SourceQA.dbo.sbaa__ApprovalVariable__c  av	
	left join Source_Production_SALESFORCE.dbo.sbaa__ApprovalVariable__c av_qa
		on av_qa.Name = av.Name
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from Stage_Production_SALESFORCE.dbo.sbaa__ApprovalVariable__c_Load


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'UPSERT:bulkapi,batchsize(100)','Production_SALESFORCE','sbaa__ApprovalVariable__c_Load', 'Id'

Select error, count(*) as num from sbaa__ApprovalVariable__c_Load a
where error not like '%success%'
group by error
order by num desc


-------------------------------------------------------------------------------------------------------------------
-- Approval Condition
-------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'sbaa__ApprovalCondition__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.[sbaa__ApprovalCondition__c_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	CAST('' AS nvarchar(18)) AS [ID] 
	,ac.Id as Approval_Condition_External_Id__c 
	,ac.Name as Name
	,ar_qa.Name as RuleName
	,ar_qa.Id as sbaa__ApprovalRule__c
	,ac.sbaa__EnableSmartApproval__c as sbaa__EnableSmartApproval__c
	,ac.sbaa__FilterField__c as sbaa__FilterField__c
	,ac.sbaa__FilterType__c as sbaa__FilterType__c
	,ac.sbaa__FilterValue__c as sbaa__FilterValue__c
	,ac.sbaa__FilterVariable__c as sbaa__FilterVariable__c
	,ac.sbaa__Index__c as sbaa__Index__c
	,ac.sbaa__Operator__c as sbaa__Operator__c
	,ac.sbaa__TestedField__c as sbaa__TestedField__c
	,av.Id as sbaa__TestedVariable__c 
	,CAST('' as nvarchar(2000)) as Error

INTO Stage_Production_SALESFORCE.dbo.sbaa__ApprovalCondition__c_Load

FROM SourceQA.dbo.sbaa__ApprovalCondition__c  ac	
	left join Source_Production_SALESFORCE.dbo.sbaa__ApprovalRule__c ar_qa
		on ar_qa.Approval_Rule_External_Id__c = ac.sbaa__ApprovalRule__c
	left join Source_Production_SALESFORCE.dbo.sbaa__ApprovalVariable__c av
		on av.Approval_Variable_External_Id__c = ac.sbaa__TestedVariable__c 
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from Stage_Production_SALESFORCE.dbo.sbaa__ApprovalCondition__c_Load


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE StageQA;

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'UPSERT:bulkapi,batchsize(100)','Production_SALESFORCE','sbaa__ApprovalCondition__c_Load', 'Id'

Select error, count(*) as num from sbaa__ApprovalCondition__c_Load_Result a
where error not like '%success%'
group by error
order by num desc

Select * from sbaa__ApprovalCondition__c_Load_Result a where error not like '%success%'