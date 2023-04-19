CREATE DATABASE ex_triggers_07
GO
USE ex_triggers_07
GO
CREATE TABLE cliente (
codigo		INT			NOT NULL,
nome		VARCHAR(70)	NOT NULL
PRIMARY KEY(codigo)
)
GO
CREATE TABLE venda (
codigo_venda	INT				NOT NULL,
codigo_cliente	INT				NOT NULL,
valor_total		DECIMAL(7,2)	NOT NULL
PRIMARY KEY (codigo_venda)
FOREIGN KEY (codigo_cliente) REFERENCES cliente(codigo)
)
GO
CREATE TABLE pontos (
codigo_cliente	INT					NOT NULL,
total_pontos	DECIMAL(4,1)		NOT NULL
PRIMARY KEY (codigo_cliente)
FOREIGN KEY (codigo_cliente) REFERENCES cliente(codigo)
)

/*
- Uma empresa vende produtos alimentícios
- A empresa dá pontos, para seus clientes, que podem ser revertidos em prêmios
- Para não prejudicar a tabela venda, nenhum produto pode ser deletado, mesmo que não venha mais a ser vendido
- Para não prejudicar os relatórios e a contabilidade, a tabela venda não pode ser alterada. 
- Ao invés de alterar a tabela venda deve-se exibir uma tabela com o nome do último cliente que comprou e o valor da 
última compra
- Após a inserção de cada linha na tabela venda, 10% do total deverá ser transformado em pontos.
- Se o cliente ainda não estiver na tabela de pontos, deve ser inserido automaticamente após sua primeira compra
- Se o cliente atingir 1 ponto, deve receber uma mensagem (PRINT SQL Server) dizendo que ganhou
*/

-- Para não prejudicar a tabela venda, nenhum produto pode ser deletado, mesmo que não venha mais a ser vendido
CREATE TRIGGER t_naodeletarproduto ON venda
FOR DELETE
AS 
BEGIN
     ROLLBACK TRANSACTION
	 RAISERROR('Não se pode deletar produtos', 16, 1)
END



-- Para não prejudicar os relatórios e a contabilidade, a tabela venda não pode ser alterada.
CREATE TRIGGER t_naopodeatualizarproduto ON venda
FOR UPDATE
AS 
BEGIN
    ROLLBACK TRANSACTION
	RAISERROR('Não se pode alterar os produtos', 16, 1)
END

-- Ao invés de alterar a tabela venda deve-se exibir uma tabela com o nome do último cliente que comprou e o valor da 
-- última compra
CREATE TRIGGER t_aoinvesdeatualizarproduto ON venda
INSTEAD OF UPDATE 
AS
BEGIN
DECLARE @codigo INT 
SET @codigo = (SELECT MAX(codigo) FROM cliente)
SELECT c.nome, v.valor_total
FROM cliente c, venda v
WHERE c.codigo = v.codigo_cliente
  AND c.codigo = @codigo
END

-- Após a inserção de cada linha na tabela venda, 10% do total deverá ser transformado em pontos.
CREATE TRIGGER t_converterparapontos ON venda
FOR INSERT
AS
BEGIN
DECLARE @codigo INT,
        @pontos DECIMAL(4, 2)
SELECT @codigo = codigo_cliente FROM INSERTED
SELECT @pontos = CAST(v.valor_total * 0.10 AS DECIMAL(7, 2)) FROM cliente c, venda v WHERE c.codigo = v.codigo_cliente AND c.codigo = @codigo

INSERT pontos (codigo_cliente, total_pontos) VALUES       
              (@codigo, @pontos)
END




-- Se o cliente ainda não estiver na tabela de pontos, deve ser inserido automaticamente após sua primeira compra
CREATE TRIGGER t_naoestivernospontos ON venda
FOR INSERT
AS
BEGIN 
     DECLARE @codigo_cliente  INT,
			 @total_pontos DECIMAL(4, 2)
     SELECT @codigo_cliente = codigo_cliente FROM INSERTED
	 SELECT @total_pontos = CAST(v.valor_total * 0.10 AS DECIMAL(7, 2)) FROM cliente c, venda v WHERE c.codigo = v.codigo_cliente AND c.codigo = @codigo_cliente 
	 PRINT(@codigo_cliente)
	 PRINT(@total_pontos)

     IF (@codigo_cliente NOT IN (SELECT codigo_cliente FROM pontos) )
     BEGIN
		  INSERT INTO pontos (codigo_cliente, total_pontos) VALUES
		                     (@codigo_cliente, @total_pontos)
     END
END

		  
-- Se o cliente atingir 1 ponto, deve receber uma mensagem (PRINT SQL Server) dizendo que ganhou     
CREATE TRIGGER t_mensagemqueganhou ON venda
FOR INSERT
AS
BEGIN
     DECLARE @codigo_cliente  INT,
			 @total_pontos DECIMAL(4, 2),
			 @nome_ganhador VARCHAR(100) 
     SELECT @codigo_cliente = codigo_cliente FROM INSERTED
	 SELECT @total_pontos = CAST(v.valor_total * 0.10 AS DECIMAL(7, 2)) FROM cliente c, venda v WHERE c.codigo = v.codigo_cliente AND c.codigo = @codigo_cliente
	 SELECT @nome_ganhador = c.nome FROM cliente c, venda v WHERE c.codigo = v.codigo_cliente AND c.codigo = @codigo_cliente

	 IF(@total_pontos >= 1)
	 BEGIN
	      PRINT(@nome_ganhador + ' ganhou!!!') 
	 END
END

SELECT * FROM cliente 
SELECT * FROM venda
SELECT * FROM pontos

delete cliente 
delete venda
delete pontos

update venda 
set valor_total = 150.00
where codigo_cliente = 1

insert into cliente VALUES
          (1, 'oato')
insert into cliente VALUES
          (2, 'papa')
insert into cliente VALUES
		  (3, 'ttt')

INSERT INTO venda VALUES
          (1, 1, 100.00)
INSERT INTO venda VALUES
          (2, 2, 200.00)
INSERT INTO venda VALUES
		  (3, 3, 300.00)                  