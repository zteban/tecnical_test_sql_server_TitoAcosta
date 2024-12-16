Prueba Técnica: Sistema de Permisos

Nota: Agregué la columna [role_id] a la tabla [DB_Entrevistas].[dbo].[UserCompany] para identificar el rol de cada usuario y asi poder asignar los permisos del rol al usuario





-- Query para el llenado de la tabla [dbo].[Permission] con todas las combinaciones
DECLARE @can_create BIT, @can_read BIT, @can_update BIT, @can_delete BIT, @can_import BIT, @can_export BIT
-- Bucle para todas las combinaciones posibles de 0 y 1
DECLARE @i INT = 0;
WHILE @i < 64
BEGIN

    SET @can_create = @i & 1;
    SET @can_read = (@i & 2) / 2;
    SET @can_update = (@i & 4) / 4;
    SET @can_delete = (@i & 8) / 8;
    SET @can_import = (@i & 16) / 16;
    SET @can_export = (@i & 32) / 32;
    -- Insertar la combinación en la tabla Permission
    INSERT INTO [dbo].[Permission] ([name], [description], [can_create], [can_read], [can_update], [can_delete], [can_import], [can_export])
    VALUES (CONCAT('Permission ', @i), 'Description for permission ' + CAST(@i AS NVARCHAR), @can_create, @can_read, @can_update, @can_delete, @can_import, @can_export);
    SET @i = @i + 1;  
END;
