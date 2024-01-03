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
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'SBQQ__PriceRule__c'​
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'SBQQ__PriceAction__c'​
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'SBQQ__PriceCondition__c'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'SBQQ__SummaryVariable__c'

USE [Source_Production_SALESFORCE];
​
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'SBQQ__PriceRule__c'​
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'SBQQ__PriceAction__c'​
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'SBQQ__PriceCondition__c'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'SBQQ__SummaryVariable__c'


------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Price Rule
------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'SBQQ__PriceRule__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.[SBQQ__PriceRule__c_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	Coalesce(pr_qa.Id, CAST('' AS nvarchar(18))) AS [ID] 
	,pr.Id as Price_Rule_External_Id__c
	,pr.Name as Name
	,pr.SBQQ__Active__c as SBQQ__Active__c
	,pr.SBQQ__AdvancedCondition__c as SBQQ__AdvancedCondition__c
	,pr.SBQQ__ConditionsMet__c as SBQQ__ConditionsMet__c
	--,'All' as SBQQ__ConditionsMet__c ------ use it on first run
	,pr.SBQQ__ConfiguratorEvaluationEvent__c as SBQQ__ConfiguratorEvaluationEvent__c
	,pr.SBQQ__EvaluationEvent__c as SBQQ__EvaluationEvent__c
	,pr.SBQQ__EvaluationOrder__c as SBQQ__EvaluationOrder__c
	,pr.SBQQ__LookupObject__c as SBQQ__LookupObject__c
	,pr.SBQQ__Product__c as SBQQ__Product__c
	,pr.SBQQ__TargetObject__c as SBQQ__TargetObject__c
	,pr.Calculation_Event_Sequence__c as Calculation_Event_Sequence__c
	,pr.Description__c  as Description__c 
	,CAST('' as nvarchar(2000)) as Error

INTO Stage_Production_SALESFORCE.dbo.SBQQ__PriceRule__c_Load

FROM SourceQA.dbo.SBQQ__PriceRule__c pr
	left join Source_Production_SALESFORCE.dbo.SBQQ__PriceRule__c pr_qa
		on pr_qa.Name = pr.Name

	
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from Stage_Production_SALESFORCE.dbo.SBQQ__PriceRule__c_Load


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'UPSERT:bulkapi,batchsize(100)','Production_SALESFORCE','SBQQ__PriceRule__c_Load', 'Id'

Select error, * from SBQQ__PriceRule__c_Load_Result a where error not like '%success%'


------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Price Condition
------------------------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'SBQQ__PriceCondition__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.[SBQQ__PriceCondition__c_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	Coalesce(pc_qa.Id, CAST('' AS nvarchar(18))) AS [ID] 
	,pc.Id as Price_Condition_External_Id__c 
	,pc.Name as Name
	,pr.name as PriceRuleName
	,pr.Id as SBQQ__Rule__c
	,pc.SBQQ__Field__c as SBQQ__Field__c
	,pc.SBQQ__FilterFormula__c as SBQQ__FilterFormula__c
	,pc.SBQQ__FilterType__c as SBQQ__FilterType__c
	,pc.SBQQ__Index__c as SBQQ__Index__c
	,pc.SBQQ__Object__c as SBQQ__Object__c
	,pc.SBQQ__Operator__c as SBQQ__Operator__c
	,pc.SBQQ__ParentRuleIsActive__c as SBQQ__ParentRuleIsActive__c
	,pc.SBQQ__RuleTargetsCalculator__c as SBQQ__RuleTargetsCalculator__c
	,pc.SBQQ__TestedFormula__c as SBQQ__TestedFormula__c
	,pc.SBQQ__TestedVariable__c as SBQQ__TestedVariable__c
	,pc.SBQQ__Value__c as SBQQ__Value__c
	,CAST('' as nvarchar(2000)) as Error

INTO Stage_Production_SALESFORCE.dbo.SBQQ__PriceCondition__c_Load

FROM SourceQA.dbo.SBQQ__PriceCondition__c pc
	left join Source_Production_SALESFORCE.dbo.SBQQ__PriceCondition__c pc_qa
		on pc_qa.Id  = pc.Price_Condition_External_Id__c 
	left join Source_Production_SALESFORCE.dbo.SBQQ__PriceRule__c pr
		on pr.Price_Rule_External_Id__c = pc.SBQQ__Rule__c

	
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from Stage_Production_SALESFORCE.dbo.SBQQ__PriceCondition__c_Load


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'UPSERT:bulkapi,batchsize(100)','Production_SALESFORCE','SBQQ__PriceCondition__c_Load', 'Id'

Select error, count(*) as num from SBQQ__PriceCondition__c_Load_Result a
where error not like '%success%'
group by error
order by num desc

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Summary variable
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

INTO Stage_Production_SALESFORCE.dbo.[SBQQ__SummaryVariable__c_Load]

FROM SourceQA.dbo.SBQQ__SummaryVariable__c sv
	left join Source_Production_SALESFORCE.dbo.SBQQ__SummaryVariable__c sv_qa
		on sv.Name = sv_qa.Name

	
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from Stage_Production_SALESFORCE.dbo.[SBQQ__SummaryVariable__c_Load]


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'UPSERT:bulkapi,batchsize(100)','Production_SALESFORCE','SBQQ__SummaryVariable__c_Load', 'Id'

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Price Action
------------------------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'SBQQ__PriceAction__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.[SBQQ__PriceAction__c_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	Coalesce(pa_qa.Id, CAST('' AS nvarchar(18))) AS [ID]  
	,pa.Id as Price_Action_External_Id__c
	,pr.name as PRNAme
	,pa.Name as Name
	,pr.Id as SBQQ__Rule__c
	,pa.SBQQ__Field__c as SBQQ__Field__c
	,pa.SBQQ__Formula__c as SBQQ__Formula__c
	,pa.SBQQ__Order__c as SBQQ__Order__c
	,pa.SBQQ__ParentRuleIsActive__c as SBQQ__ParentRuleIsActive__c
	,pa.SBQQ__RuleLookupObject__c as SBQQ__RuleLookupObject__c
	,pa.SBQQ__RuleTargetsCalculator__c as SBQQ__RuleTargetsCalculator__c
	,pa.SBQQ__SourceLookupField__c as SBQQ__SourceLookupField__c
	,sv.Id as SBQQ__SourceVariable__c
	,pa.SBQQ__TargetObject__c as SBQQ__TargetObject__c
	,pa.SBQQ__ValueField__c as SBQQ__ValueField__c
	,pa.SBQQ__Value__c   as SBQQ__Value__c  
	,CAST('' as nvarchar(2000)) as Error

INTO Stage_Production_SALESFORCE.dbo.[SBQQ__PriceAction__c_Load]

FROM SourceQA.dbo.SBQQ__PriceAction__c pa
	left join Source_Production_SALESFORCE.dbo.SBQQ__PriceRule__c pr
		on pr.Price_Rule_External_Id__c = pa.SBQQ__Rule__c
	left join Source_Production_SALESFORCE.dbo.SBQQ__PriceAction__c pa_qa
		on pa.SBQQ__Rule__c = pr.Price_Rule_External_Id__c
		and pa.SBQQ__Field__c = pa_qa.SBQQ__Field__c
		and pa.SBQQ__Value__c = pa_qa.SBQQ__Value__c
	left join Source_Production_SALESFORCE.dbo.SBQQ__SummaryVariable__c as sv
		on sv.Summary_Variable_External_Id__c = pa.SBQQ__SourceVariable__c

	
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from Stage_Production_SALESFORCE.dbo.[SBQQ__PriceAction__c_Load]


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'UPSERT:bulkapi,batchsize(100)','Production_SALESFORCE','SBQQ__PriceAction__c_Load', 'Id'

Select error, count(*) as num from SBQQ__PriceAction__c_Load_Result a
where error not like '%success%'
group by error
order by num desc