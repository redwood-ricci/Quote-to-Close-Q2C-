---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Product Rule Upsert Script	
--- Customer: Redwood
--- Primary Developer: Ajay Santhosh
--- Secondary Developers:  Ajay Santhosh
--- Created Date: 23/11/2023
--- Last Updated: 
--- Change Log: 
--- 	
--- Prerequisites:
--- 1. 
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
USE SourceQA;
​
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'SBQQ__ProductRule__c'​
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'SBQQ__ErrorCondition__c'​
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'SBQQ__SummaryVariable__c'

USE [Source_Production_SALESFORCE];
​
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'SBQQ__ProductRule__c'​
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'SBQQ__ErrorCondition__c'​
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'SBQQ__SummaryVariable__c'


------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Product Rule
------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'SBQQ__ProductRule__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.[SBQQ__ProductRule__c_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	Coalesce(pr_qa.Id, CAST('' AS nvarchar(18))) AS [ID] 
	,pr.Id as Product_Rule_External_Id__c
	,pr.Name as Name
	,pr.SBQQ__Active__c as SBQQ__Active__c
	,pr.SBQQ__AdvancedCondition__c as SBQQ__AdvancedCondition__c
	--,pr.SBQQ__ConditionsMet__c as SBQQ__ConditionsMet__c
	,'All' as SBQQ__ConditionsMet__c ------ use it on first run
	,pr.SBQQ__ErrorMessage__c as SBQQ__ErrorMessage__c
	,pr.SBQQ__EvaluationEvent__c as SBQQ__EvaluationEvent__c
	,pr.SBQQ__EvaluationOrder__c as SBQQ__EvaluationOrder__c
	,pr.SBQQ__LookupMessageField__c as SBQQ__LookupMessageField__c
	,pr.SBQQ__LookupObject__c as SBQQ__LookupObject__c
	,pr.SBQQ__LookupProductField__c as SBQQ__LookupProductField__c
	,pr.SBQQ__LookupRequiredField__c as SBQQ__LookupRequiredField__c
	,pr.SBQQ__LookupTypeField__c as SBQQ__LookupTypeField__c
	,pr.SBQQ__Scope__c as SBQQ__Scope__c
	,pr.SBQQ__Type__c as SBQQ__Type__c
	,CAST('' as nvarchar(2000)) as Error

INTO Stage_Production_SALESFORCE.dbo.SBQQ__ProductRule__c_Load

FROM SourceQA.dbo.SBQQ__ProductRule__c pr
	left join Source_Production_SALESFORCE.dbo.SBQQ__ProductRule__c pr_qa
		on pr_qa.Name = pr.Name

	
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from Stage_Production_SALESFORCE.dbo.SBQQ__ProductRule__c_Load


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'UPSERT:bulkapi,batchsize(100)','Production_SALESFORCE','SBQQ__ProductRule__c_Load', 'Id'

Select error, * from SBQQ__ProductRule__c_Load_Result a where error not like '%success%'
------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Summary Vairable
------------------------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'SBQQ__SummaryVariable__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.[SBQQ__SummaryVariable__c_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	Coalesce(sv_qa.Id, CAST('' AS nvarchar(18))) AS [ID] 
	,sv.Id as Summary_Variable_External_Id__c
	,sv.Name as Name
	,sv.SBQQ__AggregateField__c as SBQQ__AggregateField__c
	,sv.SBQQ__AggregateFunction__c as SBQQ__AggregateFunction__c
	,sv.SBQQ__CombineWith__c as SBQQ__CombineWith__c
	,sv.SBQQ__CompositeOperator__c as SBQQ__CompositeOperator__c
	,sv.SBQQ__ConstraintField__c as SBQQ__ConstraintField__c
	,sv.SBQQ__FilterField__c as SBQQ__FilterField__c
	,sv.SBQQ__FilterValue__c as SBQQ__FilterValue__c
	,sv.SBQQ__Operator__c as SBQQ__Operator__c
	,sv.SBQQ__Scope__c as SBQQ__Scope__c
	,sv.SBQQ__TargetObject__c as SBQQ__TargetObject__c
	,sv.SBQQ__ValueElement__c as SBQQ__ValueElement__c
	,CAST('' as nvarchar(2000)) as Error

INTO Stage_Production_SALESFORCE.dbo.SBQQ__SummaryVariable__c_Load

FROM SourceQA.dbo.SBQQ__SummaryVariable__c sv
	left join Source_Production_SALESFORCE.dbo.SBQQ__SummaryVariable__c sv_qa
		on sv_qa.Name = sv.Name

	
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from Stage_Production_SALESFORCE.dbo.SBQQ__SummaryVariable__c_Load


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'UPSERT:bulkapi,batchsize(100)','Production_SALESFORCE','SBQQ__SummaryVariable__c_Load', 'Id'


------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Error Condition
------------------------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'SBQQ__ErrorCondition__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.[SBQQ__ErrorCondition__c_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	Coalesce(ProdEC.Id, CAST('' AS nvarchar(18))) AS [ID] 
	,ec.Id as Error_Condition_External_Id__c
	,pr.name as PRNAme
	,ec.Name as Name
	,pr.Id as SBQQ__Rule__c
	,ec.SBQQ__FilterType__c as SBQQ__FilterType__c
	,ec.SBQQ__FilterValue__c as SBQQ__FilterValue__c
	,ec.SBQQ__FilterVariable__c as SBQQ__FilterVariable__c
	,ec.SBQQ__Index__c as SBQQ__Index__c
	,ec.SBQQ__Operator__c as SBQQ__Operator__c
	,ec.SBQQ__ParentRuleIsActive__c as SBQQ__ParentRuleIsActive__c
	,ec.SBQQ__RuleTargetsQuote__c as SBQQ__RuleTargetsQuote__c
	,ec.SBQQ__TestedAttribute__c as SBQQ__TestedAttribute__c
	,ec.SBQQ__TestedField__c as SBQQ__TestedField__c
	,ec.SBQQ__TestedObject__c as SBQQ__TestedObject__c
	,sv.Id  as SBQQ__TestedVariable__c 
	,CAST('' as nvarchar(2000)) as Error

INTO Stage_Production_SALESFORCE.dbo.SBQQ__ErrorCondition__c_Load

FROM SourceQA.dbo.SBQQ__ErrorCondition__c ec
	left join Source_Production_SALESFORCE.dbo.SBQQ__ProductRule__c pr
		on pr.Product_Rule_External_Id__c = ec.SBQQ__Rule__c
	left join Source_Production_SALESFORCE.dbo.SBQQ__ErrorCondition__c ProdEC
		on ProdEC.Error_Condition_External_Id__c = ec.Id
	left join Source_Production_SALESFORCE.dbo.SBQQ__SummaryVariable__c as sv
		on sv.Summary_Variable_External_Id__c = ec.SBQQ__TestedVariable__c

	
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from Stage_Production_SALESFORCE.dbo.SBQQ__ErrorCondition__c_Load

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'UPSERT:bulkapi,batchsize(100)','Production_SALESFORCE','SBQQ__ErrorCondition__c_Load', 'Id'

Select error, count(*) as num from SBQQ__ErrorCondition__c_Load_Result a
where error not like '%success%'
group by error
order by num desc