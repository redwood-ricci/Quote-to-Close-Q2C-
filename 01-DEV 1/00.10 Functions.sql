-- Create a function that takes a country code as input and returns the mapped value
IF OBJECT_ID('dbo.MapBillingCountry', 'FN') IS NOT NULL
BEGIN
    DROP FUNCTION dbo.MapBillingCountry;
    PRINT 'Function dbo.MapBillingCountry dropped successfully.';
END

GO

CREATE FUNCTION dbo.MapBillingCountry(@CountryCode NVARCHAR(255))
RETURNS NVARCHAR(255)
AS
BEGIN
    DECLARE @MappedCountry NVARCHAR(255)

    -- Use a CASE statement to map the values
    SET @MappedCountry = 
        CASE
            WHEN @CountryCode IN (
                '.', 'a', 'ada', 'blah', 'dfgdf', 'dgf', 'drdyf', 'fgfg', 'fhgh', 'fsdf', 'ghjg', 'gjkg', 'hjh', 'jkjnh', 'k', 'khjhjk',
                'Na', 'o', 'rht', 'sdvs'
            ) THEN NULL
            WHEN @CountryCode IN ('United States of America', 'USA') THEN 'United States'
            ELSE @CountryCode
        END

    RETURN @MappedCountry
END

GO
-- Function to turn state abreviations into their full names

IF OBJECT_ID('dbo.fn_GetStateFullName', 'FN') IS NOT NULL
BEGIN
    DROP FUNCTION dbo.fn_GetStateFullName;
END

GO

CREATE FUNCTION dbo.fn_GetStateFullName (@StateAbbreviation VARCHAR(255))
RETURNS NVARCHAR(255)
AS
BEGIN
    RETURN 
        CASE @StateAbbreviation
            WHEN 'AL' THEN 'Alabama'
            WHEN 'AK' THEN 'Alaska'
            WHEN 'AZ' THEN 'Arizona'
            WHEN 'AR' THEN 'Arkansas'
            WHEN 'CA' THEN 'California'
            WHEN 'CO' THEN 'Colorado'
            WHEN 'CT' THEN 'Connecticut'
            WHEN 'DE' THEN 'Delaware'
            WHEN 'FL' THEN 'Florida'
            WHEN 'GA' THEN 'Georgia'
            WHEN 'HI' THEN 'Hawaii'
            WHEN 'ID' THEN 'Idaho'
            WHEN 'IL' THEN 'Illinois'
            WHEN 'IN' THEN 'Indiana'
            WHEN 'IA' THEN 'Iowa'
            WHEN 'KS' THEN 'Kansas'
            WHEN 'KY' THEN 'Kentucky'
            WHEN 'LA' THEN 'Louisiana'
            WHEN 'ME' THEN 'Maine'
            WHEN 'MD' THEN 'Maryland'
            WHEN 'MA' THEN 'Massachusetts'
            WHEN 'MI' THEN 'Michigan'
            WHEN 'MN' THEN 'Minnesota'
            WHEN 'MS' THEN 'Mississippi'
            WHEN 'MO' THEN 'Missouri'
            WHEN 'MT' THEN 'Montana'
            WHEN 'NE' THEN 'Nebraska'
            WHEN 'NV' THEN 'Nevada'
            WHEN 'NH' THEN 'New Hampshire'
            WHEN 'NJ' THEN 'New Jersey'
            WHEN 'NM' THEN 'New Mexico'
            WHEN 'NY' THEN 'New York'
            WHEN 'NC' THEN 'North Carolina'
            WHEN 'ND' THEN 'North Dakota'
            WHEN 'OH' THEN 'Ohio'
            WHEN 'OK' THEN 'Oklahoma'
            WHEN 'OR' THEN 'Oregon'
            WHEN 'PA' THEN 'Pennsylvania'
            WHEN 'RI' THEN 'Rhode Island'
            WHEN 'SC' THEN 'South Carolina'
            WHEN 'SD' THEN 'South Dakota'
            WHEN 'TN' THEN 'Tennessee'
            WHEN 'TX' THEN 'Texas'
            WHEN 'UT' THEN 'Utah'
            WHEN 'VT' THEN 'Vermont'
            WHEN 'VA' THEN 'Virginia'
            WHEN 'WA' THEN 'Washington'
            WHEN 'WV' THEN 'West Virginia'
            WHEN 'WI' THEN 'Wisconsin'
            WHEN 'WY' THEN 'Wyoming'
            ELSE @StateAbbreviation
        END
END

GO


-- function to combine the top two functions to scrub messy values and convert state full anmes
IF OBJECT_ID('dbo.scrub_address', 'FN') IS NOT NULL
BEGIN
    DROP FUNCTION dbo.scrub_address;
END

GO

CREATE FUNCTION scrub_address (@input NVARCHAR(255))
RETURNS NVARCHAR(255)
AS
BEGIN
    -- Call the first two functions in sequence
    DECLARE @temp NVARCHAR(255) = dbo.MapBillingCountry(@input)
    SET @temp = dbo.fn_GetStateFullName(@temp)
    RETURN @temp
END

GO