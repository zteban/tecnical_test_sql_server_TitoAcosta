USE [DB_Entrevistas]
GO

/* ---------------------------
Tito Acosta 15/12/2024
<Descripción>
Prueba Técnica: Sistema de Permisos

<Execute>
EXEC [dbo].[sp_GetUserPermissions] @id_user = 1, @id_entit = 2;
*/


ALTER PROCEDURE [dbo].[sp_GetUserPermissions]
    @id_user BIGINT,
    @id_entit BIGINT
AS
BEGIN
    
	DECLARE @id_role           BIGINT;
	DECLARE @id_PermissionZero BIGINT;

	SET @id_PermissionZero = (SELECT [id_permi] FROM [Permission] WHERE [can_create] = 0 AND [can_read]= 0 AND[can_update] = 0 AND[can_delete]= 0 AND[can_import]= 0 AND [can_export]= 0)
	SET @id_role = (SELECT role_id FROM [UserCompany] WHERE id_useco = @id_user)


   ---DECLARACIÓN DE TEMPORALES NECESARIAS PARA EL PROCESO 
    BEGIN
		---------------------------- PERMISOS A NIVEL ENTIDAD ------------------------------------------------
		IF OBJECT_ID('tempdb..#tmpPermiUser') IS NOT NULL DROP TABLE #tmpPermiUser;
		CREATE TABLE #tmpPermiUser
		(
			[id_user] [bigint] NOT NULL,
			[user_username] [nvarchar](255) NOT NULL,
			[id_rol] [bigint] NOT NULL,
			[role_name] [nvarchar](255) NOT NULL,
			[compa_name] [nvarchar](255) NOT NULL,
			[id_entit] [int] NOT NULL,
			[entit_name] [nvarchar](255) NOT NULL,
			[id_permi] [bigint] NOT NULL,
			[Permission] [nvarchar](255) NOT NULL,
			[can_create] [bit] NOT NULL,
			[can_delete] [bit] NOT NULL,
			[can_read] [bit] NOT NULL,
			[can_update] [bit] NOT NULL,
			[can_export] [bit] NOT NULL,
			[can_import] [bit] NOT NULL,
			[peusr_include] [bit] NOT NULL,
			[Inserted_by_default] [bit] NOT NULL,
		);
		IF OBJECT_ID('tempdb..#tmpPermiRole') IS NOT NULL DROP TABLE #tmpPermiRole;
		CREATE TABLE #tmpPermiRole
		(
			[id_role] [bigint] NOT NULL,
			[role_name] [nvarchar](255) NOT NULL,
			[compa_name] [nvarchar](255) NOT NULL,
			[id_entit] [int] NOT NULL,
			[entit_name] [nvarchar](255) NOT NULL,
			[id_permi] [bigint] NOT NULL,
			[Permission] [nvarchar](255) NOT NULL,
			[can_create] [bit] NOT NULL,
			[can_delete] [bit] NOT NULL,
			[can_read] [bit] NOT NULL,
			[can_update] [bit] NOT NULL,
			[can_export] [bit] NOT NULL,
			[can_import] [bit] NOT NULL,
			[perol_include] [bit] NOT NULL,
			[Inserted_by_default] [bit] NOT NULL
		);


		---------------------------- PERMISOS A NIVEL REGISTRO ------------------------------------------------

		-- Registros de PermiUserRecord teniendo en cuenta el nombre de la tabla y la llave primaria calculada
		IF OBJECT_ID('tempdb..#tmpPermiUserRecord') IS NOT NULL DROP TABLE #tmpPermiUserRecord;
		CREATE TABLE #tmpPermiUserRecord
		(
			[id_user] [bigint] NOT NULL,
			[user_username] [nvarchar](255) NOT NULL,
			[id_rol] [bigint] NOT NULL,
			[role_name] [nvarchar](255) NOT NULL,
			[compa_name] [nvarchar](255) NOT NULL,
			[id_entit] [int] NOT NULL,
			[entit_name] [nvarchar](255) NOT NULL,
			[id_permi] [bigint] NOT NULL,
			[Permission] [nvarchar](255) NOT NULL,
			[can_create] [bit] NOT NULL,
			[can_delete] [bit] NOT NULL,
			[can_read] [bit] NOT NULL,
			[can_update] [bit] NOT NULL,
			[can_export] [bit] NOT NULL, 
			[can_import] [bit] NOT NULL,
			[peusr_include] [bit] NOT NULL,
			[registro_de_la_entidad] int NOT NULL,
			[Inserted_by_default] [bit] NOT NULL
		);
		--llenado de la tabla con los registros faltantes, asignando por defecto el permiso 0 a estos registros 
		IF OBJECT_ID('tempdb..#tmpUserRecordMissing') IS NOT NULL DROP TABLE #tmpUserRecordMissing;
		CREATE TABLE #tmpUserRecordMissing
		(
			[table_name] varchar(100)  ,
			[id_permi] [int] ,
			[id_user] [int]  ,
			[id_record] [int]  ,
			[Inserted_by_default] [BIT]  ,
		);
		-- Registros de PermiRoleRecord teniendo en cuenta el nombre de la tabla y la llave primaria calculada
		IF OBJECT_ID('tempdb..#tmpPermiRoleRecord') IS NOT NULL DROP TABLE #tmpPermiRoleRecord;
		CREATE TABLE #tmpPermiRoleRecord
		(
			[id_role] [bigint] NOT NULL,
			[role_name] [nvarchar](255) NOT NULL,
			[compa_name] [nvarchar](255) NOT NULL,
			[id_entit] [int] NOT NULL,
			[entit_name] [nvarchar](255) NOT NULL,
			[id_permi] [bigint] NOT NULL,
			[Permission] [nvarchar](255) NOT NULL,
			[can_create] [bit] NOT NULL,
			[can_delete] [bit] NOT NULL,
			[can_read] [bit] NOT NULL,
			[can_update] [bit] NOT NULL,
			[can_export] [bit] NOT NULL, 
			[can_import] [bit] NOT NULL,
			[perrc_include] [bit] NOT NULL,
			[registro_de_la_entidad] int NOT NULL,
			[Inserted_by_default] [bit] NOT NULL
		)
		----llenado de la tabla con los registros faltantes asignando por defecto el permiso 0
		IF OBJECT_ID('tempdb..#tmpRoleRecordMissing') IS NOT NULL DROP TABLE #tmpRoleRecordMissing;
		CREATE TABLE #tmpRoleRecordMissing
		(
			[table_name] varchar(100)  ,
			[id_permi] [int] ,
			[id_rol] [int]  ,
			[id_record] [int]  ,
			[Inserted_by_default] [BIT]  ,
		)
	END;

	---------- #tmpPermiUser--------------- EXTRACCIÓN DE PERMISOS DE USUARIO A NIVEL ENTIDAD-----------------------------------------
	BEGIN
		INSERT INTO #tmpPermiUser
		SELECT A.[id_user]
			  ,A.[user_username]  
			  ,R.[id_role]
			  ,R.[role_name]
			  ,C.[compa_name] 
			  ,E.[id_entit] 
			  ,E.[entit_name]
			  ,F.[id_permi]
			  ,F.[name] AS Permission
			  ,F.[can_create]
			  ,F.[can_delete]
			  ,F.[can_read]
			  ,F.[can_update]
			  ,F.[can_export]
			  ,F.[can_import]
			  ,D.[peusr_include]
			  ,0 as [Inserted_by_default]
		FROM  [User]               A 
		INNER JOIN [UserCompany]   B ON A.[id_user]          = B.[user_id]  AND B.useco_active = 1    
		INNER JOIN [Company]       C ON B.[company_id]       = C.[id_compa] AND C.compa_active = 1   
		INNER JOIN [PermiUser]     D ON D.[usercompany_id]   = B.[user_id]                       
		INNER JOIN [EntityCatalog] E ON ((D.[peusr_include] = 1 AND E.[id_entit] = D.[entitycatalog_id]) OR (D.[peusr_include] = 0 AND E.[id_entit] != D.[entitycatalog_id]))
									 AND E.entit_active = 1 
		INNER JOIN [Permission]    F ON F.[id_permi]         = D.[permission_id]
		LEFT JOIN  [Role]          R ON R.id_role = B.role_id
		WHERE A.[id_user] = @id_user AND E.[id_entit]  = @id_entit;  


		--Borrado de duplicados en caso de tener en permiuser mas de un registro asociado al mismo usuario y a la misma entidad 
		-- o en caso de que una entidad tenga un permiso agregado por include y otro por exclude, tomando por defecto el registro en include 1 
		WITH CTE AS (SELECT ROW_NUMBER() OVER (PARTITION BY [id_user],[id_entit] order by [peusr_include] DESC) Rk  FROM #tmpPermiUser)
		DELETE FROM CTE WHERE Rk > 1;


		--llenado de la tabla con las entidades a las cuales el usuario no tiene permisos, asignando por defecto el permiso 0
		INSERT INTO #tmpPermiUser
		SELECT A.[id_user]
			  ,A.[user_username]
			  ,R.[id_role]
			  ,R.[role_name]
			  ,C.[compa_name] 
			  ,E.[id_entit] 
			  ,E.[entit_name]
			  ,F.[id_permi]
			  ,F.[name] AS Permission
			  ,F.[can_create]
			  ,F.[can_delete]
			  ,F.[can_read]
			  ,F.[can_update]
			  ,F.[can_export]
			  ,F.[can_import]
			  ,0
			  ,1 as [Inserted_by_default]
		FROM  [User]               A 
		INNER JOIN [UserCompany]   B ON A.[id_user]          = B.[user_id]  AND B.useco_active = 1 
		INNER JOIN [Company]       C ON B.[company_id]       = C.[id_compa] AND C.compa_active = 1  
		INNER JOIN (SELECT H.[id_entit]  ,B.id_permi ,@id_user as id_user FROM  [EntityCatalog]    H LEFT JOIN  #tmpPermiUser A  ON H.[id_entit] = A.[id_entit] INNER JOIN [Permission]  B  ON B.id_permi = @id_PermissionZero WHERE  A.[id_entit] IS NULL)     D ON D.id_user   = B.[user_id]    
		INNER JOIN [EntityCatalog] E ON  E.[id_entit] = D.[id_entit] AND E.entit_active = 1 
		INNER JOIN [Permission]    F ON F.[id_permi]         = @id_PermissionZero
		LEFT JOIN  [Role]          R ON R.id_role = B.role_id
		WHERE  E.[id_entit] = @id_entit AND A.[id_user] = @id_user;
	END;

	---------- #tmpPermiUserRecord--------- EXTRACCIÓN DE PERMISOS DE USUARIO A NIVEL REGISTRO----------------------------------------
	BEGIN
		
		DECLARE @table_name NVARCHAR(255)         -- Guarda el nombre de la tabla teniendo en cuenta el @id_entit
		DECLARE @primary_key NVARCHAR(255)        -- Guarda el nombre de la columna correspondiente a la llave primaria, para asi relacionar los tegistros
		DECLARE @sql NVARCHAR(MAX)                -- Query dinámica con el @table_name y @primary_key


		SET @table_name = (SELECT entit_name FROM EntityCatalog WHERE id_entit = @id_entit)
		SET @primary_key = (SELECT  KU.COLUMN_NAME FROM  INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS TC
														 INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KU ON TC.CONSTRAINT_NAME = KU.CONSTRAINT_NAME
							WHERE  TC.TABLE_NAME = @table_name AND TC.CONSTRAINT_TYPE = 'PRIMARY KEY');


		SET @sql = '
		INSERT INTO #tmpPermiUserRecord
		SELECT A.[id_user]
			  ,A.[user_username]  
			  ,R.[id_role]
			  ,R.[role_name]
			  ,C.[compa_name]
			  ,E.[id_entit] 
			  ,E.[entit_name]
			  ,F.[id_permi]
			  ,F.[name]
			  ,F.[can_create]
			  ,F.[can_delete]
			  ,F.[can_read]
			  ,F.[can_update]
			  ,F.[can_export]
			  ,F.[can_import]
			  ,D.[peusr_include]
			  ,G.'+@primary_key+' as registro_de_la_entidad
			  ,0 as [Inserted_by_default]
		FROM  [User]                 A 
		INNER JOIN [UserCompany]     B ON A.[id_user]         = B.[user_id]  AND B.useco_active = 1   -- NO MOSTRAR PERMISOS DE USUARIOS INACTIVOS
		INNER JOIN [Company]         C ON B.[company_id]      = C.[id_compa] AND C.compa_active = 1                   
		INNER JOIN [PermiUserRecord] D ON D.usercompany_id    = B.[user_id]                           
		INNER JOIN [EntityCatalog]   E ON E.[id_entit]        = D.[entitycatalog_id] AND E.entit_active = 1 
		INNER JOIN '+@table_name+'   G ON ((D.[peusr_include] = 1 AND D.peusr_record = G.'+@primary_key+') OR (D.[peusr_include] = 0  AND D.peusr_record != G.'+@primary_key+')) 
		INNER JOIN [Permission]      F ON F.[id_permi]       = D.[permission_id]
		LEFT JOIN  [Role]            R ON R.id_role = B.role_id
		WHERE E.[entit_name] = '''+@table_name+'''  AND A.[id_user] = ' + CAST(@id_user AS NVARCHAR)


		-- Ejecutar la query dinámica
		EXEC sp_executesql @sql;


		--Borrado de duplicados en caso de tener en permiuserRecord mas de un registro asociado al mismo usuario y a la misma entidad
		WITH CTE AS (SELECT ROW_NUMBER() OVER (PARTITION BY [id_user],[id_entit],registro_de_la_entidad order by [peusr_include] DESC) Rk  FROM #tmpPermiUserRecord)
		DELETE FROM CTE WHERE Rk > 1;


		--llenado de la tabla con los registros de la entidad, a los cuales el usuario no tiene permisos, asignando por defecto el permiso 0
		DECLARE @sql2 NVARCHAR(MAX)
		SET @sql2 = '
		INSERT INTO #tmpUserRecordMissing
		SELECT '''+@table_name+''' AS table_name  ,'+CAST(@id_PermissionZero AS NVARCHAR)+','+CAST(@id_user AS NVARCHAR)+' as id_user ,H.'+@primary_key+',1
		FROM  '+@table_name+'    H 
		LEFT JOIN  #tmpPermiUserRecord A  ON H.'+@primary_key+' = A.registro_de_la_entidad
		WHERE  A.[registro_de_la_entidad] IS NULL
		'
		 EXEC sp_executesql @sql2;


		--actualización de los registros faltantes, heredando de PermiUser en caso de que hayan registros sin asignación de permisos
		UPDATE  #tmpUserRecordMissing SET id_permi = b.id_permi , [Inserted_by_default] = B.[Inserted_by_default] from #tmpUserRecordMissing a inner join #tmpPermiUser b on a.id_user = b.id_user and a.table_name = b.entit_name

		--insertar registros faltantes en la tabla final de registros #tmpPermiUserRecord teniendo en cuenta los cálculos anteriores
		--para finalmente tener la tabla de permisos a nivel registro por entidad, con cada uno de los registros de dicha tabla 
		--(por defecto a los registros no relacionados se asigna el permiso 0)
		INSERT INTO #tmpPermiUserRecord
		SELECT A.[id_user]
			  ,A.[user_username]  
			  ,G.[id_role]
			  ,G.[role_name]
			  ,C.[compa_name] 
			  ,E.[id_entit] 
			  ,E.[entit_name]
			  ,F.[id_permi]
			  ,F.[name] AS Permission
			  ,F.[can_create]
			  ,F.[can_delete]
			  ,F.[can_read]
			  ,F.[can_update]
			  ,F.[can_export]
			  ,F.[can_import]
			  ,1
			  ,D.id_record
			  ,D.[Inserted_by_default]
		FROM  [User]               A 
		INNER JOIN [UserCompany]   B ON A.[id_user]          = B.[user_id]  AND B.useco_active = 1 
		INNER JOIN [Company]       C ON B.[company_id]       = C.[id_compa] AND C.compa_active = 1  
		INNER JOIN #tmpUserRecordMissing       D ON D.id_user   = B.[user_id]    
		INNER JOIN [EntityCatalog] E ON E.entit_name = D.table_name AND E.entit_active = 1 
		INNER JOIN [Permission]    F ON F.[id_permi]         = D.id_permi
		LEFT JOIN  [Role]          G ON G.id_role = B.role_id
		WHERE  E.[id_entit] = @id_entit AND A.[id_user] = @id_user;
	END;

	---------- #tmpPermiRole--------------- EXTRACCIÓN DE PERMISOS DE ROL A NIVEL ENTIDAD---------------------------------------------
	BEGIN
		INSERT INTO #tmpPermiRole
		SELECT A.id_role
			  ,A.role_name
			  ,C.[compa_name] 
			  ,E.[id_entit] 
			  ,E.[entit_name]
			  ,F.[id_permi]
			  ,F.[name] AS Permission
			  ,F.[can_create]
			  ,F.[can_delete]
			  ,F.[can_read]
			  ,F.[can_update]
			  ,F.[can_export]
			  ,F.[can_import]
			  ,D.[perol_include]
			  ,0
		FROM  [Role]               A   
		INNER JOIN [Company]       C ON A.[company_id]       = C.[id_compa] AND C.compa_active = 1   
		INNER JOIN [PermiRole]     D ON D.role_id  = A.id_role                       
		INNER JOIN [EntityCatalog] E ON ((D.[perol_include] = 1 AND E.[id_entit] = D.[entitycatalog_id]) OR (D.[perol_include] = 0 AND E.[id_entit] != D.[entitycatalog_id]))
									 AND E.entit_active = 1 
		INNER JOIN [Permission]    F ON F.[id_permi]         = D.[permission_id]
		WHERE E.[id_entit]  = @id_entit;  

		--Borrado de duplicados en caso de tener en permiRole mas de un registro asociado al mismo usuario y a la misma entidad
		WITH CTE AS (SELECT ROW_NUMBER() OVER (PARTITION BY [id_role],[id_entit] order by [perol_include] DESC) Rk  FROM #tmpPermiRole)
		DELETE FROM CTE WHERE Rk > 1;


		--llenado de la tabla, con las entidades restantes, asignando por defecto el permiso 0
		INSERT INTO #tmpPermiRole
		SELECT A.id_role
			  ,A.role_name
			  ,C.[compa_name] 
			  ,E.[id_entit] 
			  ,E.[entit_name]
			  ,F.[id_permi]
			  ,F.[name] AS Permission
			  ,F.[can_create]
			  ,F.[can_delete]
			  ,F.[can_read]
			  ,F.[can_update]
			  ,F.[can_export]
			  ,F.[can_import]
			  ,1
			  ,1 AS [Inserted_by_default]
		FROM  [Role]               A 
		INNER JOIN [Company]       C ON A.[company_id]       = C.[id_compa] AND C.compa_active = 1  
		INNER JOIN (SELECT H.[id_entit]  ,B.id_permi ,@id_role as id_role FROM  [EntityCatalog]    H LEFT JOIN  #tmpPermiRole A  ON H.[id_entit] = A.[id_entit] INNER JOIN [Permission]  B  ON B.id_permi = @id_PermissionZero WHERE  A.[id_entit] IS NULL)     D ON D.id_role  = A.id_role
		INNER JOIN [EntityCatalog] E ON  E.[id_entit] = D.[id_entit] AND E.entit_active = 1 
		INNER JOIN [Permission]    F ON F.[id_permi]         = @id_PermissionZero
		WHERE  E.[id_entit] = @id_entit;
	END;

	---------- #tmpPermiRoleRecord--------- EXTRACCIÓN DE PERMISOS DE ROL A NIVEL REGISTRO--------------------------------------------
	BEGIN
		DECLARE @sqlPermiRoleRecords NVARCHAR(MAX)
		-- Registros de PermiRoleRecord teniendo en cuenta el nombre de la tabla y la llave primaria calculada

		SET @sqlPermiRoleRecords = '
		INSERT INTO #tmpPermiRoleRecord
		SELECT A.[id_role]
			  ,A.[role_name] 
			  ,C.[compa_name]
			  ,E.[id_entit] 
			  ,E.[entit_name]
			  ,F.[id_permi]
			  ,F.[name]
			  ,F.[can_create]
			  ,F.[can_delete]
			  ,F.[can_read]
			  ,F.[can_update]
			  ,F.[can_export]
			  ,F.[can_import]
			  ,D.[perrc_include]
			  ,G.'+@primary_key+' as registro_de_la_entidad
			  ,0 AS [Inserted_by_default]
		FROM  [Role]                 A 
		INNER JOIN [Company]         C ON A.[company_id]      = C.[id_compa] AND C.compa_active = 1                   
		INNER JOIN [PermiRoleRecord] D ON D.role_id    = A.[id_role]                           
		INNER JOIN [EntityCatalog]   E ON E.[id_entit]        = D.[entitycatalog_id] AND E.entit_active = 1 
		INNER JOIN '+@table_name+'   G ON ((D.[perrc_include] = 1 AND D.perrc_record = G.'+@primary_key+') OR (D.[perrc_include] = 0  AND D.perrc_record != G.'+@primary_key+')) 
		INNER JOIN [Permission]      F ON F.[id_permi]       = D.[permission_id] 
		WHERE E.[entit_name] = '''+@table_name+'''  AND A.[id_role] = ' + CAST(@id_role AS NVARCHAR)


		-- Ejecutar la consulta dinámica
		EXEC sp_executesql @sqlPermiRoleRecords;


		--Borrado de duplicados en caso de tener en permiRoleRecord mas de un registro asociado al mismo usuario y a la misma entidad

		WITH CTE AS (SELECT ROW_NUMBER() OVER (PARTITION BY id_role,[id_entit],registro_de_la_entidad order by [perrc_include] DESC) Rk  FROM #tmpPermiRoleRecord)
		DELETE FROM CTE WHERE Rk > 1;




		DECLARE @sqlRoleRecordMissing NVARCHAR(MAX)
		SET @sqlRoleRecordMissing = '
		INSERT INTO #tmpRoleRecordMissing
		SELECT '''+@table_name+''' AS table_name  ,'+CAST(@id_PermissionZero AS NVARCHAR)+','+CAST(@id_role AS NVARCHAR)+' as id_role ,H.'+@primary_key+',1
		FROM  '+@table_name+'    H 
		LEFT JOIN  #tmpPermiRoleRecord A  ON H.'+@primary_key+' = A.registro_de_la_entidad
		WHERE  A.[registro_de_la_entidad] IS NULL
		'
		 EXEC sp_executesql @sqlRoleRecordMissing;


		----actualizar los registros faltantes, heredando de PermiRole en caso de que haya un registro alli, si no hay queda por defecto el permiso 0
		UPDATE  #tmpRoleRecordMissing SET id_permi = b.id_permi , [Inserted_by_default] = B.[Inserted_by_default] from #tmpRoleRecordMissing a inner join #tmpPermiRole b on a.id_rol = b.id_role and a.table_name = b.entit_name


		----insertar registros faltantes en la tabla final de registros #tmpPermiRoleRecord
		INSERT INTO #tmpPermiRoleRecord
		SELECT A.[id_Role]
			  ,A.role_name
			  ,C.[compa_name] 
			  ,E.[id_entit] 
			  ,E.[entit_name]
			  ,F.[id_permi]
			  ,F.[name] AS Permission
			  ,F.[can_create]
			  ,F.[can_delete]
			  ,F.[can_read]
			  ,F.[can_update]
			  ,F.[can_export]
			  ,F.[can_import]
			  ,1
			  ,D.id_record
			  ,d.[Inserted_by_default] AS [Inserted_by_default]
		FROM  [Role]               A 
		INNER JOIN [Company]       C ON A.[company_id]       = C.[id_compa] AND C.compa_active = 1  
		INNER JOIN #tmpRoleRecordMissing       D ON D.id_rol   = A.id_role
		INNER JOIN [EntityCatalog] E ON E.entit_name = D.table_name AND E.entit_active = 1 
		INNER JOIN [Permission]    F ON F.[id_permi]         = D.id_permi
		WHERE  E.[id_entit] = @id_entit;

	END;

	---------- QUERYS FINALES, A NIVEL ENTIDAD Y REGISTROS----------------------------------------------------------------------------
	BEGIN
	    -- COMPARA #tmpPermiUser Y #tmpPermiRole dando prioridad a #tmpPermiUser
		SELECT  A.[id_user]  ,
				A.[user_username]  ,
				A.[id_rol],
				A.[role_name] ,
				A.[compa_name] ,
				A.[id_entit] ,
				A.[entit_name] ,
				CASE WHEN A.[Inserted_by_default] = 0 THEN A.[id_permi]      ELSE B.[id_permi]      END AS [id_permi]     ,
				CASE WHEN A.[Inserted_by_default] = 0 THEN A.[Permission]    ELSE B.[Permission]    END AS [Permission]   ,
				CASE WHEN A.[Inserted_by_default] = 0 THEN A.[can_create]    ELSE B.[can_create]    END AS [can_create]   ,
				CASE WHEN A.[Inserted_by_default] = 0 THEN A.[can_delete]    ELSE B.[can_delete]    END AS [can_delete]   ,
				CASE WHEN A.[Inserted_by_default] = 0 THEN A.[can_read]      ELSE B.[can_read]      END AS [can_read]     ,
				CASE WHEN A.[Inserted_by_default] = 0 THEN A.[can_update]    ELSE B.[can_update]    END AS [can_update]   ,
				CASE WHEN A.[Inserted_by_default] = 0 THEN A.[can_export]    ELSE B.[can_export]    END AS [can_export]   ,
				CASE WHEN A.[Inserted_by_default] = 0 THEN A.[can_import]    ELSE B.[can_import]    END AS [can_import]   ,
				CASE WHEN A.[Inserted_by_default] = 0 THEN A.[peusr_include] ELSE B.[perol_include] END AS [peusr_include],
				A.[Inserted_by_default] 
		FROM #tmpPermiUser A
		LEFT JOIN #tmpPermiRole B ON A.id_rol = B.id_role AND A.id_entit = B.id_entit


		-- COMPARA #tmpPermiUserRecord Y #tmpPermiRoleRecord dando prioridad a #tmpPermiUserRecord
		SELECT  A.[id_user]  ,
				A.[user_username]  ,
				A.[id_rol],
				A.[role_name] ,
				A.[compa_name] ,
				A.[id_entit] ,
				A.[entit_name] ,
				CASE WHEN A.[Inserted_by_default]  = 0 THEN A.[id_permi]      ELSE B.[id_permi]             END  AS [id_permi]      ,
				CASE WHEN A.[Inserted_by_default]  = 0 THEN A.[Permission]    ELSE B.[Permission]           END  AS [Permission]    ,
				CASE WHEN A.[Inserted_by_default]  = 0 THEN A.[can_create]    ELSE B.[can_create]           END  AS [can_create]    ,
				CASE WHEN A.[Inserted_by_default]  = 0 THEN A.[can_delete]    ELSE B.[can_delete]           END  AS [can_delete]    ,
				CASE WHEN A.[Inserted_by_default]  = 0 THEN A.[can_read]      ELSE B.[can_read]             END  AS [can_read]      ,
				CASE WHEN A.[Inserted_by_default]  = 0 THEN A.[can_update]    ELSE B.[can_update]           END  AS [can_update]    ,
				CASE WHEN A.[Inserted_by_default]  = 0 THEN A.[can_export]    ELSE B.[can_export]           END  AS [can_export]    ,
				CASE WHEN A.[Inserted_by_default]  = 0 THEN A.[can_import]    ELSE B.[can_import]           END  AS [can_import]    ,
				CASE WHEN A.[Inserted_by_default]  = 0 THEN A.[peusr_include] ELSE B.perrc_include          END  AS [peusr_include] ,
				CASE WHEN A.[Inserted_by_default]  = 0 THEN A.registro_de_la_entidad ELSE B.registro_de_la_entidad END  AS registro_de_la_entidad ,
				A.[Inserted_by_default] 
		FROM #tmpPermiUserRecord A
		LEFT JOIN #tmpPermiRoleRecord B ON A.id_rol = B.id_role AND A.id_entit = B.id_entit AND A.registro_de_la_entidad = B.registro_de_la_entidad
	END;

	---------- ELIMINACIÓN DE TEMPORALES----------------------------------------------------------------------------------------------
	BEGIN
		---------------------------- PERMISOS A NIVEL ENTIDAD ------------------------------------------------
		IF OBJECT_ID('tempdb..#tmpPermiUser')           IS NOT NULL DROP TABLE #tmpPermiUser;
		IF OBJECT_ID('tempdb..#tmpPermiRole')           IS NOT NULL DROP TABLE #tmpPermiRole;
		IF OBJECT_ID('tempdb..#tmpPermiUserRecord')     IS NOT NULL DROP TABLE #tmpPermiUserRecord;
		IF OBJECT_ID('tempdb..#tmpUserRecordMissing')   IS NOT NULL DROP TABLE #tmpUserRecordMissing;
		IF OBJECT_ID('tempdb..#tmpPermiRoleRecord')     IS NOT NULL DROP TABLE #tmpPermiRoleRecord;
		IF OBJECT_ID('tempdb..#tmpRoleRecordMissing')   IS NOT NULL DROP TABLE #tmpRoleRecordMissing;
	END;

END
