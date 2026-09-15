/* cria função apenas numero para tratar campo de telefone */

CREATE FUNCTION dbo.ApenasNumeros (@temp VARCHAR(255))
RETURNS VARCHAR(255)
AS
BEGIN
    DECLARE @KeepValues AS VARCHAR(50) = '%[^0-9]%'
    WHILE PATINDEX(@KeepValues, @temp) > 0
        SET @temp = STUFF(@temp, PATINDEX(@KeepValues, @temp), 1, '')
    RETURN @temp
END