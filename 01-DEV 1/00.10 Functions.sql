-- Create a function that takes a country code as input and returns the mapped value
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
            ) THEN ''
            WHEN @CountryCode IN ('United States of America', 'USA') THEN 'United States'
            ELSE @CountryCode
        END

    RETURN @MappedCountry
END
