
CREATE FUNCTION dbo.fn_calcular_digito_verificador_modulo10
(
    @matricula VARCHAR(20) -- Número da matrícula
)
RETURNS CHAR(1)
AS
BEGIN
    DECLARE @soma INT = 0;
    DECLARE @i INT;
    DECLARE @multiplicador INT;
    DECLARE @digito INT;

    -- Laço para percorrer cada caractere da matrícula (da direita para a esquerda)
    SET @i = LEN(@matricula);
    
    -- Inicia o multiplicador como 2 (posição ímpar)
    SET @multiplicador = 2;

    WHILE @i > 0
    BEGIN
        -- Pega o valor do caractere (dígito) da matrícula e calcula o valor
        DECLARE @valor INT = CAST(SUBSTRING(@matricula, @i, 1) AS INT);
        
        -- Se a posição for ímpar (começando da direita, a partir de 1), multiplica por 2
        IF @multiplicador = 2
        BEGIN
            SET @valor = @valor * 2;
            -- Se o resultado for maior que 9, subtrai 9
            IF @valor > 9
            BEGIN
                SET @valor = @valor - 9;
            END
        END

        -- Soma o valor ao total
        SET @soma = @soma + @valor;

        -- Atualiza o multiplicador (2 -> 1, 1 -> 2, e assim por diante)
        SET @multiplicador = CASE 
            WHEN @multiplicador = 2 THEN 1 
            ELSE 2 
        END;

        SET @i = @i - 1;
    END

    -- Calcula o dígito verificador
    SET @digito = (@soma * 9) % 10;

    -- Retorna o dígito verificador
    RETURN CAST(@digito AS CHAR(1));
END


