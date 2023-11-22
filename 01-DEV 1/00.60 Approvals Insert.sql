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
USE SourceNeocol

EXEC SourceNeocol.dbo.SF_Replicate 'SANDBOX_NEOCOL','sbaa__ApprovalChain__c','PKCHUNK'
EXEC SourceNeocol.dbo.SF_Replicate 'SANDBOX_NEOCOL','sbaa__ApprovalRule__c ','PKCHUNK'
EXEC SourceNeocol.dbo.SF_Replicate 'SANDBOX_NEOCOL','sbaa__ApprovalCondition__c','PKCHUNK'
EXEC SourceNeocol.dbo.SF_Replicate 'SANDBOX_NEOCOL','sbaa__ApprovalVariable__c','PKCHUNK'

USE SourceQA

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','sbaa__ApprovalChain__c','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','sbaa__ApprovalRule__c ','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','sbaa__ApprovalCondition__c','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','sbaa__ApprovalVariable__c','PKCHUNK'

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'sbaa__ApprovalChain__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[sbaa__ApprovalChain__c_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	Coalesce(ac_qa.Id, CAST('' AS nvarchar(18))) AS [ID] 
	,ac.Id as Approval_Chain_External_Id__c
	,ac.Name as Name
	,CAST('' as nvarchar(2000)) as Error

INTO StageQA.dbo.sbaa__ApprovalChain__c_Load

FROM SourceNeocol.dbo.sbaa__ApprovalChain__c ac
	left join SourceQA.dbo.sbaa__ApprovalChain__c ac_qa
		on ac_qa.Name = ac.Name

	
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from StageQA.dbo.sbaa__ApprovalChain__c_Load


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE StageQA;

EXEC StageQA.dbo.SF_Tableloader 'UPSERT:bulkapi,batchsize(100)','SANDBOX_QA','sbaa__ApprovalRule__c_Load', 'Id'


-------------------------------------------------------------------------------------
-- Approval Rules
-------------------------------------------------------------------------------------
---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'sbaa__ApprovalRule__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[sbaa__ApprovalRule__c_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	Coalesce(ar_qa.Id, CAST('' AS nvarchar(18))) AS [ID] 
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

INTO StageQA.dbo.sbaa__ApprovalRule__c_Load

FROM SourceNeocol.dbo.sbaa__ApprovalRule__c ar
	left join SourceQA.dbo.sbaa__ApprovalRule__c ar_qa
		on ar_qa.Name = ar.Name
	left join SourceQA.dbo.sbaa__ApprovalChain__c ac
		on ac.Approval_Chain_External_Id__c = ar.sbaa__ApprovalChain__c

	
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from StageQA.dbo.sbaa__ApprovalRule__c_Load


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE StageQA;

EXEC StageQA.dbo.SF_Tableloader 'UPSERT:bulkapi,batchsize(100)','SANDBOX_QA','sbaa__ApprovalRule__c_Load', 'Id'

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
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'sbaa__ApprovalVariable__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[sbaa__ApprovalRule__c_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	Coalesce(ar_qa.Id, CAST('' AS nvarchar(18))) AS [ID] 
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

INTO StageQA.dbo.sbaa__ApprovalRule__c_Load

FROM SourceNeocol.dbo.sbaa__ApprovalRule__c ar
	left join SourceQA.dbo.sbaa__ApprovalRule__c ar_qa
		on ar_qa.Name = ar.Name
	left join SourceQA.dbo.sbaa__ApprovalChain__c ac
		on ac.Approval_Chain_External_Id__c = ar.sbaa__ApprovalChain__c

	
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from StageQA.dbo.sbaa__ApprovalRule__c_Load


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE StageQA;

EXEC StageQA.dbo.SF_Tableloader 'UPSERT:bulkapi,batchsize(100)','SANDBOX_QA','sbaa__ApprovalRule__c_Load', 'Id'

Select error, count(*) as num from sbaa__ApprovalRule__c_Load a
where error not like '%success%'
group by error
order by num desc