-- Escoge tu propia aventura - Script de base de datos
-- Ejecutar sobre una base de datos VACÍA: crea el esquema y carga los datos.
-- Los Id los genera la base de datos.


-- ESQUEMA (generado con dotnet ef migrations script)
IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
CREATE TABLE [Categorias] (
    [Id] int NOT NULL IDENTITY,
    [Nombre] nvarchar(max) NOT NULL,
    CONSTRAINT [PK_Categorias] PRIMARY KEY ([Id])
);

CREATE TABLE [Usuarios] (
    [Id] int NOT NULL IDENTITY,
    [NombreCompleto] nvarchar(max) NOT NULL,
    [Email] nvarchar(max) NOT NULL,
    [NombreUsuario] nvarchar(max) NOT NULL,
    [Contrasena] nvarchar(max) NOT NULL,
    [Rol] int NOT NULL,
    CONSTRAINT [PK_Usuarios] PRIMARY KEY ([Id])
);

CREATE TABLE [Auditorias] (
    [Id] int NOT NULL IDENTITY,
    [Accion] nvarchar(max) NOT NULL,
    [Fecha] datetime2 NOT NULL,
    [AdministradorId] int NOT NULL,
    [HistoriaId] int NOT NULL,
    CONSTRAINT [PK_Auditorias] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Auditorias_Usuarios_AdministradorId] FOREIGN KEY ([AdministradorId]) REFERENCES [Usuarios] ([Id])
);

CREATE TABLE [Capitulos] (
    [Id] int NOT NULL IDENTITY,
    [Titulo] nvarchar(max) NOT NULL,
    [Texto] nvarchar(max) NOT NULL,
    [HistoriaId] int NOT NULL,
    [Discriminator] nvarchar(21) NOT NULL,
    [CantidadVecesAlcanzado] int NULL,
    CONSTRAINT [PK_Capitulos] PRIMARY KEY ([Id])
);

CREATE TABLE [Historias] (
    [Id] int NOT NULL IDENTITY,
    [Titulo] nvarchar(max) NOT NULL,
    [Sinopsis] nvarchar(max) NOT NULL,
    [Estado] int NOT NULL,
    [CapituloInicialId] int NOT NULL,
    CONSTRAINT [PK_Historias] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Historias_Capitulos_CapituloInicialId] FOREIGN KEY ([CapituloInicialId]) REFERENCES [Capitulos] ([Id])
);

CREATE TABLE [Opciones] (
    [Id] int NOT NULL IDENTITY,
    [Texto] nvarchar(max) NOT NULL,
    [DestinoId] int NOT NULL,
    [CapituloIntermedioId] int NULL,
    CONSTRAINT [PK_Opciones] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Opciones_Capitulos_CapituloIntermedioId] FOREIGN KEY ([CapituloIntermedioId]) REFERENCES [Capitulos] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_Opciones_Capitulos_DestinoId] FOREIGN KEY ([DestinoId]) REFERENCES [Capitulos] ([Id])
);

CREATE TABLE [CategoriaHistoria] (
    [CategoriasId] int NOT NULL,
    [HistoriaId] int NOT NULL,
    CONSTRAINT [PK_CategoriaHistoria] PRIMARY KEY ([CategoriasId], [HistoriaId]),
    CONSTRAINT [FK_CategoriaHistoria_Categorias_CategoriasId] FOREIGN KEY ([CategoriasId]) REFERENCES [Categorias] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_CategoriaHistoria_Historias_HistoriaId] FOREIGN KEY ([HistoriaId]) REFERENCES [Historias] ([Id]) ON DELETE CASCADE
);

CREATE TABLE [Lecturas] (
    [Id] int NOT NULL IDENTITY,
    [FechaInicio] datetime2 NOT NULL,
    [FechaFinalizacion] datetime2 NULL,
    [UsuarioId] int NOT NULL,
    [HistoriaId] int NOT NULL,
    [CapituloActualId] int NOT NULL,
    [FinalAlcanzadoId] int NULL,
    CONSTRAINT [PK_Lecturas] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Lecturas_Capitulos_CapituloActualId] FOREIGN KEY ([CapituloActualId]) REFERENCES [Capitulos] ([Id]),
    CONSTRAINT [FK_Lecturas_Capitulos_FinalAlcanzadoId] FOREIGN KEY ([FinalAlcanzadoId]) REFERENCES [Capitulos] ([Id]),
    CONSTRAINT [FK_Lecturas_Historias_HistoriaId] FOREIGN KEY ([HistoriaId]) REFERENCES [Historias] ([Id]),
    CONSTRAINT [FK_Lecturas_Usuarios_UsuarioId] FOREIGN KEY ([UsuarioId]) REFERENCES [Usuarios] ([Id])
);

CREATE INDEX [IX_Auditorias_AdministradorId] ON [Auditorias] ([AdministradorId]);

CREATE INDEX [IX_Auditorias_HistoriaId] ON [Auditorias] ([HistoriaId]);

CREATE INDEX [IX_Capitulos_HistoriaId] ON [Capitulos] ([HistoriaId]);

CREATE INDEX [IX_CategoriaHistoria_HistoriaId] ON [CategoriaHistoria] ([HistoriaId]);

CREATE INDEX [IX_Historias_CapituloInicialId] ON [Historias] ([CapituloInicialId]);

CREATE INDEX [IX_Lecturas_CapituloActualId] ON [Lecturas] ([CapituloActualId]);

CREATE INDEX [IX_Lecturas_FinalAlcanzadoId] ON [Lecturas] ([FinalAlcanzadoId]);

CREATE INDEX [IX_Lecturas_HistoriaId] ON [Lecturas] ([HistoriaId]);

CREATE INDEX [IX_Lecturas_UsuarioId] ON [Lecturas] ([UsuarioId]);

CREATE INDEX [IX_Opciones_CapituloIntermedioId] ON [Opciones] ([CapituloIntermedioId]);

CREATE INDEX [IX_Opciones_DestinoId] ON [Opciones] ([DestinoId]);

ALTER TABLE [Auditorias] ADD CONSTRAINT [FK_Auditorias_Historias_HistoriaId] FOREIGN KEY ([HistoriaId]) REFERENCES [Historias] ([Id]);

ALTER TABLE [Capitulos] ADD CONSTRAINT [FK_Capitulos_Historias_HistoriaId] FOREIGN KEY ([HistoriaId]) REFERENCES [Historias] ([Id]) ON DELETE CASCADE;

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260910235038_Init', N'10.0.12');

COMMIT;
GO

BEGIN TRANSACTION;
DECLARE @var nvarchar(max);
SELECT @var = QUOTENAME([d].[name])
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Historias]') AND [c].[name] = N'CapituloInicialId');
IF @var IS NOT NULL EXEC(N'ALTER TABLE [Historias] DROP CONSTRAINT ' + @var + ';');
ALTER TABLE [Historias] ALTER COLUMN [CapituloInicialId] int NULL;

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260924123550_CorregirRelacionCapituloInicial', N'10.0.12');

COMMIT;
GO

BEGIN TRANSACTION;
ALTER TABLE [Auditorias] DROP CONSTRAINT [FK_Auditorias_Historias_HistoriaId];

DECLARE @var1 nvarchar(max);
SELECT @var1 = QUOTENAME([d].[name])
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Usuarios]') AND [c].[name] = N'NombreUsuario');
IF @var1 IS NOT NULL EXEC(N'ALTER TABLE [Usuarios] DROP CONSTRAINT ' + @var1 + ';');
ALTER TABLE [Usuarios] ALTER COLUMN [NombreUsuario] nvarchar(50) NOT NULL;

DECLARE @var2 nvarchar(max);
SELECT @var2 = QUOTENAME([d].[name])
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Usuarios]') AND [c].[name] = N'NombreCompleto');
IF @var2 IS NOT NULL EXEC(N'ALTER TABLE [Usuarios] DROP CONSTRAINT ' + @var2 + ';');
ALTER TABLE [Usuarios] ALTER COLUMN [NombreCompleto] nvarchar(150) NOT NULL;

DECLARE @var3 nvarchar(max);
SELECT @var3 = QUOTENAME([d].[name])
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Usuarios]') AND [c].[name] = N'Email');
IF @var3 IS NOT NULL EXEC(N'ALTER TABLE [Usuarios] DROP CONSTRAINT ' + @var3 + ';');
ALTER TABLE [Usuarios] ALTER COLUMN [Email] nvarchar(150) NOT NULL;

DECLARE @var4 nvarchar(max);
SELECT @var4 = QUOTENAME([d].[name])
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Usuarios]') AND [c].[name] = N'Contrasena');
IF @var4 IS NOT NULL EXEC(N'ALTER TABLE [Usuarios] DROP CONSTRAINT ' + @var4 + ';');
ALTER TABLE [Usuarios] ALTER COLUMN [Contrasena] nvarchar(100) NOT NULL;

DECLARE @var5 nvarchar(max);
SELECT @var5 = QUOTENAME([d].[name])
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Opciones]') AND [c].[name] = N'Texto');
IF @var5 IS NOT NULL EXEC(N'ALTER TABLE [Opciones] DROP CONSTRAINT ' + @var5 + ';');
ALTER TABLE [Opciones] ALTER COLUMN [Texto] nvarchar(300) NOT NULL;

DECLARE @var6 nvarchar(max);
SELECT @var6 = QUOTENAME([d].[name])
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Historias]') AND [c].[name] = N'Titulo');
IF @var6 IS NOT NULL EXEC(N'ALTER TABLE [Historias] DROP CONSTRAINT ' + @var6 + ';');
ALTER TABLE [Historias] ALTER COLUMN [Titulo] nvarchar(200) NOT NULL;

DECLARE @var7 nvarchar(max);
SELECT @var7 = QUOTENAME([d].[name])
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Historias]') AND [c].[name] = N'Sinopsis');
IF @var7 IS NOT NULL EXEC(N'ALTER TABLE [Historias] DROP CONSTRAINT ' + @var7 + ';');
ALTER TABLE [Historias] ALTER COLUMN [Sinopsis] nvarchar(2000) NOT NULL;

DECLARE @var8 nvarchar(max);
SELECT @var8 = QUOTENAME([d].[name])
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Categorias]') AND [c].[name] = N'Nombre');
IF @var8 IS NOT NULL EXEC(N'ALTER TABLE [Categorias] DROP CONSTRAINT ' + @var8 + ';');
ALTER TABLE [Categorias] ALTER COLUMN [Nombre] nvarchar(100) NOT NULL;

DECLARE @var9 nvarchar(max);
SELECT @var9 = QUOTENAME([d].[name])
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Capitulos]') AND [c].[name] = N'Titulo');
IF @var9 IS NOT NULL EXEC(N'ALTER TABLE [Capitulos] DROP CONSTRAINT ' + @var9 + ';');
ALTER TABLE [Capitulos] ALTER COLUMN [Titulo] nvarchar(200) NOT NULL;

DECLARE @var10 nvarchar(max);
SELECT @var10 = QUOTENAME([d].[name])
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Auditorias]') AND [c].[name] = N'HistoriaId');
IF @var10 IS NOT NULL EXEC(N'ALTER TABLE [Auditorias] DROP CONSTRAINT ' + @var10 + ';');
ALTER TABLE [Auditorias] ALTER COLUMN [HistoriaId] int NULL;

DECLARE @var11 nvarchar(max);
SELECT @var11 = QUOTENAME([d].[name])
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Auditorias]') AND [c].[name] = N'Accion');
IF @var11 IS NOT NULL EXEC(N'ALTER TABLE [Auditorias] DROP CONSTRAINT ' + @var11 + ';');
ALTER TABLE [Auditorias] ALTER COLUMN [Accion] nvarchar(100) NOT NULL;

ALTER TABLE [Auditorias] ADD [TituloHistoria] nvarchar(200) NOT NULL DEFAULT N'';

EXEC('UPDATE a SET a.TituloHistoria = h.Titulo FROM Auditorias a INNER JOIN Historias h ON a.HistoriaId = h.Id')

CREATE UNIQUE INDEX [IX_Usuarios_Email] ON [Usuarios] ([Email]);

CREATE UNIQUE INDEX [IX_Usuarios_NombreUsuario] ON [Usuarios] ([NombreUsuario]);

ALTER TABLE [Auditorias] ADD CONSTRAINT [FK_Auditorias_Historias_HistoriaId] FOREIGN KEY ([HistoriaId]) REFERENCES [Historias] ([Id]) ON DELETE SET NULL;

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20261104235624_AuditoriaConservadaYLimites', N'10.0.12');

COMMIT;
GO

BEGIN TRANSACTION;
DECLARE @var12 nvarchar(max);
SELECT @var12 = QUOTENAME([d].[name])
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Capitulos]') AND [c].[name] = N'CantidadVecesAlcanzado');
IF @var12 IS NOT NULL EXEC(N'ALTER TABLE [Capitulos] DROP CONSTRAINT ' + @var12 + ';');
ALTER TABLE [Capitulos] DROP COLUMN [CantidadVecesAlcanzado];

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20261105014705_QuitarContadorDeFinales', N'10.0.12');

COMMIT;
GO

BEGIN TRANSACTION;
ALTER TABLE [Usuarios] ADD [EstiloLectura] nvarchar(20) NOT NULL DEFAULT N'CLARO';

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20261105021410_EstiloDeLectura', N'10.0.12');

COMMIT;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;

DECLARE @cat1 int, @cat2 int, @cat3 int, @cat4 int, @cat5 int, @cat6 int, @cat7 int, @cat8 int;
DECLARE @cat9 int, @cat10 int, @u_admin1 int, @u_admin2 int, @u_lector1 int, @u_nuevo int, @u_lector2 int, @u_lector3 int;
DECLARE @u_lector4 int, @u_lector5 int, @u_lector6 int, @u_lector7 int, @u_lector8 int, @u_lector9 int, @h_faro_que_no_se_apaga int, @h_estacion_orion_9 int;
DECLARE @h_casa_calle_sauce int, @h_pliego_de_la_cuchilla int, @h_carta_tren_de_las_siete int, @h_gato_contador_barrio_sur int, @h_ultima_llamada_de_la_noche int, @h_taxi_bajo_el_puente int, @h_cerro_del_eco int, @h_jardin_de_los_relojes int;
DECLARE @h_robot_se_jubila int, @h_biblioteca_bajo_el_agua int, @h_feria_de_los_espejos int, @c_faro_que_no_se_apaga_faro_inicio int, @c_faro_que_no_se_apaga_faro_lampara int, @c_faro_que_no_se_apaga_faro_sotano int, @c_faro_que_no_se_apaga_faro_final_guardian int, @c_faro_que_no_se_apaga_faro_final_oscuridad int;
DECLARE @c_faro_que_no_se_apaga_faro_final_farera int, @c_faro_que_no_se_apaga_faro_final_isla int, @c_estacion_orion_9_orion_inicio int, @c_estacion_orion_9_orion_control int, @c_estacion_orion_9_orion_final_voz int, @c_estacion_orion_9_orion_final_silencio int, @c_estacion_orion_9_orion_final_capsula int, @c_casa_calle_sauce_sauce_inicio int;
DECLARE @c_casa_calle_sauce_sauce_noche int, @c_casa_calle_sauce_sauce_final_altillo int, @c_casa_calle_sauce_sauce_final_casa int, @c_casa_calle_sauce_sauce_final_venta int, @c_pliego_de_la_cuchilla_pliego_inicio int, @c_pliego_de_la_cuchilla_pliego_cuchilla int, @c_pliego_de_la_cuchilla_pliego_pulperia int, @c_pliego_de_la_cuchilla_pliego_final_deber int;
DECLARE @c_pliego_de_la_cuchilla_pliego_final_trato int, @c_carta_tren_de_las_siete_carta_inicio int, @c_carta_tren_de_las_siete_carta_respuestas int, @c_carta_tren_de_las_siete_carta_final_puerto int, @c_carta_tren_de_las_siete_carta_final_papel int, @c_carta_tren_de_las_siete_carta_final_funcion int, @c_gato_contador_barrio_sur_gato_inicio int, @c_gato_contador_barrio_sur_gato_negociacion int;
DECLARE @c_gato_contador_barrio_sur_gato_matematica int, @c_gato_contador_barrio_sur_gato_final_contrato int, @c_gato_contador_barrio_sur_gato_final_gerente int, @c_ultima_llamada_de_la_noche_llamada_inicio int, @c_ultima_llamada_de_la_noche_llamada_diez_minutos int, @c_ultima_llamada_de_la_noche_llamada_final_llave int, @c_ultima_llamada_de_la_noche_llamada_final_camaras int, @c_ultima_llamada_de_la_noche_llamada_final_patrulleros int;
DECLARE @c_taxi_bajo_el_puente_taxi_inicio int, @c_taxi_bajo_el_puente_taxi_viaje int, @c_taxi_bajo_el_puente_taxi_final_perdido int, @c_taxi_bajo_el_puente_taxi_final_casa int, @c_taxi_bajo_el_puente_taxi_final_noSubio int, @c_cerro_del_eco_cerro_inicio int, @c_cerro_del_eco_cerro_canon int, @c_cerro_del_eco_cerro_final_cima int;
DECLARE @c_cerro_del_eco_cerro_final_rio int, @c_cerro_del_eco_cerro_final_voces int, @c_jardin_de_los_relojes_jardin_inicio int, @c_jardin_de_los_relojes_jardin_arrancado int, @c_jardin_de_los_relojes_jardin_agua int, @c_jardin_de_los_relojes_jardin_final_dia int, @c_jardin_de_los_relojes_jardin_final_jardinero int, @c_robot_se_jubila_robot_inicio int;
DECLARE @c_robot_se_jubila_robot_llave int, @c_robot_se_jubila_robot_final_herencia int, @c_robot_se_jubila_robot_final_silbidos int, @c_robot_se_jubila_robot_final_medalla int, @c_biblioteca_bajo_el_agua_biblio_inicio int, @c_biblioteca_bajo_el_agua_biblio_escritorio int, @c_biblioteca_bajo_el_agua_biblio_final_cajon int, @c_biblioteca_bajo_el_agua_biblio_final_tinta int;
DECLARE @c_biblioteca_bajo_el_agua_biblio_final_libros int, @c_feria_de_los_espejos_feria_inicio int;

-- ============================================================
-- PRECARGA GENERADA CON IA: categorías, usuarios, historias,
-- capítulos, opciones y finales.
-- ============================================================

-- Categorias
INSERT INTO Categorias (Nombre) VALUES (N'Fantasía'); SET @cat1 = SCOPE_IDENTITY();
INSERT INTO Categorias (Nombre) VALUES (N'Ciencia ficción'); SET @cat2 = SCOPE_IDENTITY();
INSERT INTO Categorias (Nombre) VALUES (N'Misterio'); SET @cat3 = SCOPE_IDENTITY();
INSERT INTO Categorias (Nombre) VALUES (N'Terror'); SET @cat4 = SCOPE_IDENTITY();
INSERT INTO Categorias (Nombre) VALUES (N'Aventura histórica'); SET @cat5 = SCOPE_IDENTITY();
INSERT INTO Categorias (Nombre) VALUES (N'Romance'); SET @cat6 = SCOPE_IDENTITY();
INSERT INTO Categorias (Nombre) VALUES (N'Humor'); SET @cat7 = SCOPE_IDENTITY();
INSERT INTO Categorias (Nombre) VALUES (N'Suspenso'); SET @cat8 = SCOPE_IDENTITY();
INSERT INTO Categorias (Nombre) VALUES (N'Leyendas urbanas'); SET @cat9 = SCOPE_IDENTITY();
INSERT INTO Categorias (Nombre) VALUES (N'Exploración'); SET @cat10 = SCOPE_IDENTITY();

-- Usuarios (Rol: 0 = ADMINISTRADOR, 1 = LECTOR)
INSERT INTO Usuarios (NombreCompleto, Email, NombreUsuario, Contrasena, Rol, EstiloLectura) VALUES (N'Martina Echeverría', N'admin1@aventura.example', N'admin1', N'Admin123!', 0, N'OSCURO'); SET @u_admin1 = SCOPE_IDENTITY();
INSERT INTO Usuarios (NombreCompleto, Email, NombreUsuario, Contrasena, Rol, EstiloLectura) VALUES (N'Joaquín Pereyra', N'admin2@aventura.example', N'admin2', N'Admin123!', 0, N'CLARO'); SET @u_admin2 = SCOPE_IDENTITY();
INSERT INTO Usuarios (NombreCompleto, Email, NombreUsuario, Contrasena, Rol, EstiloLectura) VALUES (N'Camila Rodríguez', N'lector1@aventura.example', N'lector1', N'Lector123!', 1, N'CLARO'); SET @u_lector1 = SCOPE_IDENTITY();
INSERT INTO Usuarios (NombreCompleto, Email, NombreUsuario, Contrasena, Rol, EstiloLectura) VALUES (N'Bruno Techera', N'nuevo@aventura.example', N'nuevo', N'Lector123!', 1, N'OSCURO'); SET @u_nuevo = SCOPE_IDENTITY();
INSERT INTO Usuarios (NombreCompleto, Email, NombreUsuario, Contrasena, Rol, EstiloLectura) VALUES (N'Valentina Sosa', N'lector2@aventura.example', N'lector2', N'Lector123!', 1, N'OSCURO'); SET @u_lector2 = SCOPE_IDENTITY();
INSERT INTO Usuarios (NombreCompleto, Email, NombreUsuario, Contrasena, Rol, EstiloLectura) VALUES (N'Facundo Olivera', N'lector3@aventura.example', N'lector3', N'Lector123!', 1, N'CLARO'); SET @u_lector3 = SCOPE_IDENTITY();
INSERT INTO Usuarios (NombreCompleto, Email, NombreUsuario, Contrasena, Rol, EstiloLectura) VALUES (N'Lucía Barreto', N'lector4@aventura.example', N'lector4', N'Lector123!', 1, N'CLARO'); SET @u_lector4 = SCOPE_IDENTITY();
INSERT INTO Usuarios (NombreCompleto, Email, NombreUsuario, Contrasena, Rol, EstiloLectura) VALUES (N'Matías Cabrera', N'lector5@aventura.example', N'lector5', N'Lector123!', 1, N'OSCURO'); SET @u_lector5 = SCOPE_IDENTITY();
INSERT INTO Usuarios (NombreCompleto, Email, NombreUsuario, Contrasena, Rol, EstiloLectura) VALUES (N'Florencia Giménez', N'lector6@aventura.example', N'lector6', N'Lector123!', 1, N'OSCURO'); SET @u_lector6 = SCOPE_IDENTITY();
INSERT INTO Usuarios (NombreCompleto, Email, NombreUsuario, Contrasena, Rol, EstiloLectura) VALUES (N'Santiago Methol', N'lector7@aventura.example', N'lector7', N'Lector123!', 1, N'CLARO'); SET @u_lector7 = SCOPE_IDENTITY();
INSERT INTO Usuarios (NombreCompleto, Email, NombreUsuario, Contrasena, Rol, EstiloLectura) VALUES (N'Agustina Larrosa', N'lector8@aventura.example', N'lector8', N'Lector123!', 1, N'CLARO'); SET @u_lector8 = SCOPE_IDENTITY();
INSERT INTO Usuarios (NombreCompleto, Email, NombreUsuario, Contrasena, Rol, EstiloLectura) VALUES (N'Nicolás Duarte', N'lector9@aventura.example', N'lector9', N'Lector123!', 1, N'OSCURO'); SET @u_lector9 = SCOPE_IDENTITY();

-- Historia: El faro que no se apaga (PUBLICADA)
INSERT INTO Historias (Titulo, Sinopsis, Estado, CapituloInicialId) VALUES (N'El faro que no se apaga', N'Llegás a una isla remota para ocupar el puesto de farero y descubrís que el faro ya está encendido, y que su luz tiene voluntad propia. Entre una lámpara viva y un pozo lleno de reflejos, tus decisiones determinan quién va a cuidar la luz.', 1, NULL); SET @h_faro_que_no_se_apaga = SCOPE_IDENTITY();
INSERT INTO CategoriaHistoria (CategoriasId, HistoriaId) VALUES (@cat1, @h_faro_que_no_se_apaga);
INSERT INTO CategoriaHistoria (CategoriasId, HistoriaId) VALUES (@cat3, @h_faro_que_no_se_apaga);
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'La luz de medianoche', N'Llegás a la isla de Cuarzo para reemplazar al farero, pero el faro ya está encendido sin que nadie lo haya prendido. En la escalera encontrás un cuaderno con tu nombre, donde alguien anotó lo que vas a hacer antes de que lo hagas.', @h_faro_que_no_se_apaga, 'CapituloIntermedio'); SET @c_faro_que_no_se_apaga_faro_inicio = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'La lámpara viva', N'La luz resulta ser una criatura de vidrio y fuego que te estudia con paciencia. Te ofrece un trato: ocupar su lugar a cambio de que los barcos nunca más se pierdan.', @h_faro_que_no_se_apaga, 'CapituloIntermedio'); SET @c_faro_que_no_se_apaga_faro_lampara = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'El murmullo del sótano', N'Abajo hay un pozo de agua quieta donde se reflejan los faros de otros mundos. Una voz de mujer dice que fue la farera anterior y que lleva años atrapada.', @h_faro_que_no_se_apaga, 'CapituloIntermedio'); SET @c_faro_que_no_se_apaga_faro_sotano = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: El nuevo guardián', N'Tu cuerpo se vuelve luz y desde la costa los barcos ven una estrella constante que los guía a puerto. Nadie vuelve a saber de vos, pero ningún naufragio ocurre en esas aguas.', @h_faro_que_no_se_apaga, 'CapituloFinal'); SET @c_faro_que_no_se_apaga_faro_final_guardian = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: La noche sin luz', N'El cristal estalla y el faro se apaga por primera vez en siglos. Tenés que remar de noche en un mar sin guía, y a lo lejos otras luces sin dueño empiezan a encenderse.', @h_faro_que_no_se_apaga, 'CapituloFinal'); SET @c_faro_que_no_se_apaga_faro_final_oscuridad = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: La farera libre', N'Tirás del agua y una mujer vieja sale del pozo, riéndose y empapada. Te regala las llaves del faro, y se va en el primer bote con el cuaderno bajo el brazo.', @h_faro_que_no_se_apaga, 'CapituloFinal'); SET @c_faro_que_no_se_apaga_faro_final_farera = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Una isla que se olvida', N'Cerrás la tapa y subís sin mirar atrás. Al amanecer el faro está apagado, el cuaderno en blanco, y no recordás para qué habías venido a la isla.', @h_faro_que_no_se_apaga, 'CapituloFinal'); SET @c_faro_que_no_se_apaga_faro_final_isla = SCOPE_IDENTITY();
UPDATE Historias SET CapituloInicialId = @c_faro_que_no_se_apaga_faro_inicio WHERE Id = @h_faro_que_no_se_apaga;
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Subir hasta la lámpara y enfrentar la luz', @c_faro_que_no_se_apaga_faro_lampara, @c_faro_que_no_se_apaga_faro_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Bajar al sótano, de donde sale un murmullo', @c_faro_que_no_se_apaga_faro_sotano, @c_faro_que_no_se_apaga_faro_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Aceptar el trato de la criatura', @c_faro_que_no_se_apaga_faro_final_guardian, @c_faro_que_no_se_apaga_faro_lampara);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Romper el cristal que la sostiene', @c_faro_que_no_se_apaga_faro_final_oscuridad, @c_faro_que_no_se_apaga_faro_lampara);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Meter la mano en el pozo para sacarla', @c_faro_que_no_se_apaga_faro_final_farera, @c_faro_que_no_se_apaga_faro_sotano);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Cerrar la tapa del pozo y volver a subir', @c_faro_que_no_se_apaga_faro_final_isla, @c_faro_que_no_se_apaga_faro_sotano);

-- Historia: Estación Orión-9 (PUBLICADA)
INSERT INTO Historias (Titulo, Sinopsis, Estado, CapituloInicialId) VALUES (N'Estación Orión-9', N'Despertás en una estación orbital que parece abandonada y descubrís que pasaron once años. Una señal misteriosa llega desde el planeta de abajo, y de lo que hagas depende si la estación vuelve a la vida o queda para siempre en silencio.', 1, NULL); SET @h_estacion_orion_9 = SCOPE_IDENTITY();
INSERT INTO CategoriaHistoria (CategoriasId, HistoriaId) VALUES (@cat2, @h_estacion_orion_9);
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Despertar en hibernación', N'Abrís los ojos dentro de la cámara de hibernación y la voz de la estación te informa que pasaron once años desde tu último ciclo. Las luces de emergencia parpadean y no hay nadie en los pasillos.', @h_estacion_orion_9, 'CapituloIntermedio'); SET @c_estacion_orion_9_orion_inicio = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Registros de la tripulación', N'En el panel se repite un mensaje: la tripulación bajó al planeta tras recibir una señal que decía su nombre. La señal sigue llegando, más fuerte cada hora.', @h_estacion_orion_9, 'CapituloIntermedio'); SET @c_estacion_orion_9_orion_control = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Voz desde abajo', N'Del otro lado contesta tu propia tripulación, sana y salva, que construyó una ciudad en la superficie. Te invitan a bajar y empezás a empacar con una sonrisa.', @h_estacion_orion_9, 'CapituloFinal'); SET @c_estacion_orion_9_orion_final_voz = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Silencio en órbita', N'Apagás la antena y la estación queda en calma. Te quedás flotando entre las estrellas con la duda eterna de qué habría pasado si hubieras respondido.', @h_estacion_orion_9, 'CapituloFinal'); SET @c_estacion_orion_9_orion_final_silencio = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Regreso a casa con las manos vacías', N'La cápsula te devuelve a la Tierra, donde nadie recuerda la estación ni a tu tripulación. Vivís el resto de tus días mirando el cielo con la sensación de haber dejado algo atrás.', @h_estacion_orion_9, 'CapituloFinal'); SET @c_estacion_orion_9_orion_final_capsula = SCOPE_IDENTITY();
UPDATE Historias SET CapituloInicialId = @c_estacion_orion_9_orion_inicio WHERE Id = @h_estacion_orion_9;
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Ir a la sala de control para entender qué pasó', @c_estacion_orion_9_orion_control, @c_estacion_orion_9_orion_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Correr hasta la cápsula de escape', @c_estacion_orion_9_orion_final_capsula, @c_estacion_orion_9_orion_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Responder la señal con el transmisor', @c_estacion_orion_9_orion_final_voz, @c_estacion_orion_9_orion_control);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Apagar la antena y borrar el registro', @c_estacion_orion_9_orion_final_silencio, @c_estacion_orion_9_orion_control);

-- Historia: La casa de la calle Sauce (PUBLICADA)
INSERT INTO Historias (Titulo, Sinopsis, Estado, CapituloInicialId) VALUES (N'La casa de la calle Sauce', N'Heredás una casa antigua donde todos los relojes están detenidos a las 3:07. Podés venderla sin entrar o pasar una noche entre sus paredes, y cada decisión te acerca más a lo que la casa lleva años esperando.', 1, NULL); SET @h_casa_calle_sauce = SCOPE_IDENTITY();
INSERT INTO CategoriaHistoria (CategoriasId, HistoriaId) VALUES (@cat4, @h_casa_calle_sauce);
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Herencia en la calle Sauce', N'Tu tía abuela te dejó una casa vieja donde todos los relojes están parados a las 3:07. El escribano te avisa que podés vender sin entrar, pero la llave pesa en tu bolsillo como si te llamara.', @h_casa_calle_sauce, 'CapituloIntermedio'); SET @c_casa_calle_sauce_sauce_inicio = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'A las 3:07', N'Los relojes arrancan todos a la vez y de la cocina sale olor a lluvia, como si alguien hubiera entrado empapado. En el pasillo se escuchan pasos mojados que suben hacia el altillo.', @h_casa_calle_sauce, 'CapituloIntermedio'); SET @c_casa_calle_sauce_sauce_noche = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Lo que guardaba el altillo', N'Arriba hay un baúl con cartas de tu tía abuela dirigidas a vos, escritas antes de que nacieras. La última está fechada mañana y describe exactamente lo que estás sintiendo ahora.', @h_casa_calle_sauce, 'CapituloFinal'); SET @c_casa_calle_sauce_sauce_final_altillo = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: La casa se queda con vos', N'Pasás la noche contra la puerta escuchando cómo alguien arrastra una silla del otro lado. Al amanecer salís sin dar vuelta la cabeza, pero desde entonces todos tus relojes se detienen a las 3:07.', @h_casa_calle_sauce, 'CapituloFinal'); SET @c_casa_calle_sauce_sauce_final_casa = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Vendida sin mirar atrás', N'Firmás los papeles en la vereda y te vas con el dinero. Meses después, el nuevo dueño te manda una sola foto: la ventana del altillo, con alguien parado que se te parece.', @h_casa_calle_sauce, 'CapituloFinal'); SET @c_casa_calle_sauce_sauce_final_venta = SCOPE_IDENTITY();
UPDATE Historias SET CapituloInicialId = @c_casa_calle_sauce_sauce_inicio WHERE Id = @h_casa_calle_sauce;
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Pasar la noche en la casa para conocerla', @c_casa_calle_sauce_sauce_noche, @c_casa_calle_sauce_sauce_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Firmar la venta sin cruzar la puerta', @c_casa_calle_sauce_sauce_final_venta, @c_casa_calle_sauce_sauce_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Seguir los pasos hasta el altillo', @c_casa_calle_sauce_sauce_final_altillo, @c_casa_calle_sauce_sauce_noche);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Encerrarte en el baño y esperar al amanecer', @c_casa_calle_sauce_sauce_final_casa, @c_casa_calle_sauce_sauce_noche);

-- Historia: El pliego de la cuchilla (PUBLICADA)
INSERT INTO Historias (Titulo, Sinopsis, Estado, CapituloInicialId) VALUES (N'El pliego de la cuchilla', N'A fines del siglo XVIII, un joven postillón lleva un pliego sellado por caminos de tierra, arroyos crecidos y pulperías sospechosas. Cada decisión puede cambiar el destino de un mensaje que alguien quiere que nunca llegue.', 1, NULL); SET @h_pliego_de_la_cuchilla = SCOPE_IDENTITY();
INSERT INTO CategoriaHistoria (CategoriasId, HistoriaId) VALUES (@cat5, @h_pliego_de_la_cuchilla);
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'El pliego lacrado', N'Te entregan un pliego lacrado en la posta y te dicen que tiene que llegar a Montevideo antes del domingo. Apenas salís, un jinete de poncho oscuro se cruza en tu camino y mira demasiado tu alforja.', @h_pliego_de_la_cuchilla, 'CapituloIntermedio'); SET @c_pliego_de_la_cuchilla_pliego_inicio = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'La cuchilla en tormenta', N'El cielo se vuelve negro y el viento te echa tierra en los ojos. Al pie de la loma el arroyo bajó con la lluvia y el vado desapareció.', @h_pliego_de_la_cuchilla, 'CapituloIntermedio'); SET @c_pliego_de_la_cuchilla_pliego_cuchilla = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'La pulpería del Cardal', N'Adentro, el jinete del poncho ya te espera con dos vasos servidos y una sonrisa de ofrecimiento. El pulpero te mira fijo y niega con la cabeza, como avisándote.', @h_pliego_de_la_cuchilla, 'CapituloIntermedio'); SET @c_pliego_de_la_cuchilla_pliego_pulperia = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: El pliego mojado, el deber cumplido', N'Llegás empapado y con el caballo agotado, pero el lacre resiste. El comandante lee el pliego y te nombra mensajero de confianza delante de toda la guardia.', @h_pliego_de_la_cuchilla, 'CapituloFinal'); SET @c_pliego_de_la_cuchilla_pliego_final_deber = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Un trato de pulpería', N'Bebés lo que te sirven y a la mañana despertás sin la alforja ni el caballo. Con el tiempo te enterás de que el pliego llegó con otra firma, y nunca vas a poder probar lo que pasó.', @h_pliego_de_la_cuchilla, 'CapituloFinal'); SET @c_pliego_de_la_cuchilla_pliego_final_trato = SCOPE_IDENTITY();
UPDATE Historias SET CapituloInicialId = @c_pliego_de_la_cuchilla_pliego_inicio WHERE Id = @h_pliego_de_la_cuchilla;
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Pasar al galope por la cuchilla del norte', @c_pliego_de_la_cuchilla_pliego_cuchilla, @c_pliego_de_la_cuchilla_pliego_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Tomar el camino de las pulperías, más largo pero más concurrido', @c_pliego_de_la_cuchilla_pliego_pulperia, @c_pliego_de_la_cuchilla_pliego_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Cruzar el arroyo a caballo, aunque la corriente se lleve todo', @c_pliego_de_la_cuchilla_pliego_final_deber, @c_pliego_de_la_cuchilla_pliego_cuchilla);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Aceptar la copa y escuchar la oferta', @c_pliego_de_la_cuchilla_pliego_final_trato, @c_pliego_de_la_cuchilla_pliego_pulperia);

-- Historia: Carta en el tren de las siete (PUBLICADA)
INSERT INTO Historias (Titulo, Sinopsis, Estado, CapituloInicialId) VALUES (N'Carta en el tren de las siete', N'Todos los días encontrás una carta olvidada en el mismo asiento del tren, escrita a mano y sin firma. Contestarla puede ser el comienzo de algo lindo o de una historia que prefiere quedarse en el papel.', 1, NULL); SET @h_carta_tren_de_las_siete = SCOPE_IDENTITY();
INSERT INTO CategoriaHistoria (CategoriasId, HistoriaId) VALUES (@cat6, @h_carta_tren_de_las_siete);
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'El asiento 14', N'Todos los días tomás el mismo tren y siempre hay una carta sin firma en el asiento 14. Hoy la nueva termina diciendo que, si querés contestar, dejes tu respuesta ahí mismo.', @h_carta_tren_de_las_siete, 'CapituloIntermedio'); SET @c_carta_tren_de_las_siete_carta_inicio = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Respuestas en papel', N'Durante semanas las cartas se vuelven más largas, más graciosas y más sinceras. Una mañana la última dice que el remitente se baja en la estación del puerto y que sería lindo conocerte ahí.', @h_carta_tren_de_las_siete, 'CapituloIntermedio'); SET @c_carta_tren_de_las_siete_carta_respuestas = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Estación del puerto', N'En el andén hay alguien de tu edad con tinta en los dedos y la misma flor en la solapa. Se ríen de los nervios y se van a tomar un café que dura hasta la noche.', @h_carta_tren_de_las_siete, 'CapituloFinal'); SET @c_carta_tren_de_las_siete_carta_final_puerto = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Cartas para siempre', N'Seguís intercambiando cartas durante años sin conocer su cara, y cada una te alcanza para seguir. Algunas historias de amor funcionan mejor en papel, y esta es una de ellas.', @h_carta_tren_de_las_siete, 'CapituloFinal'); SET @c_carta_tren_de_las_siete_carta_final_papel = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Una función con entradas de regalo', N'Quien llega a buscar la carta es una actriz de una compañía de teatro que deja mensajes para que nadie viaje solo. Te regala dos entradas, y en la función conocés a alguien que te hace reír toda la noche.', @h_carta_tren_de_las_siete, 'CapituloFinal'); SET @c_carta_tren_de_las_siete_carta_final_funcion = SCOPE_IDENTITY();
UPDATE Historias SET CapituloInicialId = @c_carta_tren_de_las_siete_carta_inicio WHERE Id = @h_carta_tren_de_las_siete;
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Escribir una respuesta y dejarla en el asiento', @c_carta_tren_de_las_siete_carta_respuestas, @c_carta_tren_de_las_siete_carta_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Quedarte en el vagón para ver quién viene a buscarla', @c_carta_tren_de_las_siete_carta_final_funcion, @c_carta_tren_de_las_siete_carta_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Bajarte en el puerto con una flor en la mano', @c_carta_tren_de_las_siete_carta_final_puerto, @c_carta_tren_de_las_siete_carta_respuestas);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Seguir escribiendo y no bajarte nunca', @c_carta_tren_de_las_siete_carta_final_papel, @c_carta_tren_de_las_siete_carta_respuestas);

-- Historia: El gato contador de Barrio Sur (PUBLICADA)
INSERT INTO Historias (Titulo, Sinopsis, Estado, CapituloInicialId) VALUES (N'El gato contador de Barrio Sur', N'Heredás una rotisería de barrio y descubrís que las cuentas las llevaba un gato naranja que suma con las patas. Un día el gato entra en huelga, y vos tenés que decidir entre negociar con él o hacerte cargo de los números.', 1, NULL); SET @h_gato_contador_barrio_sur = SCOPE_IDENTITY();
INSERT INTO CategoriaHistoria (CategoriasId, HistoriaId) VALUES (@cat7, @h_gato_contador_barrio_sur);
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Un gato en la contabilidad', N'Heredás una rotisería de barrio y descubrís que las cuentas las llevaba un gato naranja llamado Contador. Esta mañana el gato se declara en huelga y se sienta sobre la caja registradora.', @h_gato_contador_barrio_sur, 'CapituloIntermedio'); SET @c_gato_contador_barrio_sur_gato_inicio = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Negociaciones felinas', N'El gato acepta el atún, pero exige además un sillón nuevo y un aumento de sueldo en croquetas. Cada vez que suena la maquinita de las tarjetas, bufa como si lo estuvieran insultando.', @h_gato_contador_barrio_sur, 'CapituloIntermedio'); SET @c_gato_contador_barrio_sur_gato_negociacion = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Matemática de emergencia', N'Después de dos horas obtenés tres resultados distintos para la misma suma, mientras el gato te mira con una lástima enorme. Un proveedor llega con una factura imposible y el gato la rompe de un zarpazo.', @h_gato_contador_barrio_sur, 'CapituloIntermedio'); SET @c_gato_contador_barrio_sur_gato_matematica = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Contrato de patas', N'La rotisería se hace famosa en el barrio por tener un gerente de cuatro patas. Las cuentas cierran perfecto, aunque cada tanto aparece un gasto misterioso que dice «ratones de peluche».', @h_gato_contador_barrio_sur, 'CapituloFinal'); SET @c_gato_contador_barrio_sur_gato_final_contrato = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Gerente general', N'El gato acepta, se sube a un banquito y empieza a dar órdenes con la cola. Vos terminás atendiendo el mostrador, feliz, y las cuentas nunca estuvieron tan claras ni los clientes tan confundidos.', @h_gato_contador_barrio_sur, 'CapituloFinal'); SET @c_gato_contador_barrio_sur_gato_final_gerente = SCOPE_IDENTITY();
UPDATE Historias SET CapituloInicialId = @c_gato_contador_barrio_sur_gato_inicio WHERE Id = @h_gato_contador_barrio_sur;
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Negociar con una lata de atún premium', @c_gato_contador_barrio_sur_gato_negociacion, @c_gato_contador_barrio_sur_gato_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Intentar hacer las cuentas vos solo', @c_gato_contador_barrio_sur_gato_matematica, @c_gato_contador_barrio_sur_gato_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Firmar el contrato con la huella de su pata', @c_gato_contador_barrio_sur_gato_final_contrato, @c_gato_contador_barrio_sur_gato_negociacion);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Pedirle perdón al gato y ofrecerle un ascenso', @c_gato_contador_barrio_sur_gato_final_gerente, @c_gato_contador_barrio_sur_gato_matematica);

-- Historia: La última llamada de la noche (PUBLICADA)
INSERT INTO Historias (Titulo, Sinopsis, Estado, CapituloInicialId) VALUES (N'La última llamada de la noche', N'Sos operadora nocturna de una línea de ayuda y a las dos de la mañana entra una llamada que susurra tu dirección. Tenés diez minutos para decidir en quién confiar antes de que alguien llegue a buscarte.', 1, NULL); SET @h_ultima_llamada_de_la_noche = SCOPE_IDENTITY();
INSERT INTO CategoriaHistoria (CategoriasId, HistoriaId) VALUES (@cat8, @h_ultima_llamada_de_la_noche);
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Número desconocido', N'A las dos de la mañana entra una llamada en la que alguien susurra tu dirección. Dice que tenés diez minutos antes de que «ellos» lleguen.', @h_ultima_llamada_de_la_noche, 'CapituloIntermedio'); SET @c_ultima_llamada_de_la_noche_llamada_inicio = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Diez minutos', N'La voz dice que vio a tu compañero de turno entrar al archivo con una llave que no le pertenece. En el monitor, la luz de esa oficina está encendida.', @h_ultima_llamada_de_la_noche, 'CapituloIntermedio'); SET @c_ultima_llamada_de_la_noche_llamada_diez_minutos = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: La llave equivocada', N'En el archivo encontrás a tu compañero quemando carpetas de llamadas viejas, y entre ellas la tuya de hace años. Lo enfrentás con el celular grabando, y cuando llegan los patrulleros ya tenés todo registrado.', @h_ultima_llamada_de_la_noche, 'CapituloFinal'); SET @c_ultima_llamada_de_la_noche_llamada_final_llave = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Lo que vieron las cámaras', N'Mirás a tu compañero sacar una caja, subirse a un auto y desaparecer. La voz vuelve a llamar solo para decir «gracias por no salir», y nunca descubrís quién era.', @h_ultima_llamada_de_la_noche, 'CapituloFinal'); SET @c_ultima_llamada_de_la_noche_llamada_final_camaras = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Patrulleros sin sirena', N'Los policías llegan rápido pero no encuentran nada: ni compañero, ni llave, ni registro de la llamada. A la mañana tu supervisor te pide la renuncia con una amabilidad que da escalofríos.', @h_ultima_llamada_de_la_noche, 'CapituloFinal'); SET @c_ultima_llamada_de_la_noche_llamada_final_patrulleros = SCOPE_IDENTITY();
UPDATE Historias SET CapituloInicialId = @c_ultima_llamada_de_la_noche_llamada_inicio WHERE Id = @h_ultima_llamada_de_la_noche;
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Mantener la calma y seguir hablando con la voz', @c_ultima_llamada_de_la_noche_llamada_diez_minutos, @c_ultima_llamada_de_la_noche_llamada_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Cortar y llamar a la policía', @c_ultima_llamada_de_la_noche_llamada_final_patrulleros, @c_ultima_llamada_de_la_noche_llamada_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Ir hasta el archivo con una linterna', @c_ultima_llamada_de_la_noche_llamada_final_llave, @c_ultima_llamada_de_la_noche_llamada_diez_minutos);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Encerrarte en tu cabina y vigilar las cámaras', @c_ultima_llamada_de_la_noche_llamada_final_camaras, @c_ultima_llamada_de_la_noche_llamada_diez_minutos);

-- Historia: El taxi bajo el puente de la rambla (PUBLICADA)
INSERT INTO Historias (Titulo, Sinopsis, Estado, CapituloInicialId) VALUES (N'El taxi bajo el puente de la rambla', N'En el barrio se cuenta que bajo el viejo puente de la rambla aparece un taxi sin patente que lleva a quien lo para a un lugar de su pasado. Una noche de lluvia, el taxi frena frente a vos.', 1, NULL); SET @h_taxi_bajo_el_puente = SCOPE_IDENTITY();
INSERT INTO CategoriaHistoria (CategoriasId, HistoriaId) VALUES (@cat9, @h_taxi_bajo_el_puente);
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'La luz azul bajo el puente', N'Dicen que bajo el puente de la rambla vive un taxi fantasma que lleva a quien lo para a «el lugar donde dejaste algo». Una noche de lluvia, un taxi sin patente frena delante tuyo y el conductor abre la puerta sin mirarte.', @h_taxi_bajo_el_puente, 'CapituloIntermedio'); SET @c_taxi_bajo_el_puente_taxi_inicio = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'El viaje sin semáforos', N'El taxi recorre calles que no existen mientras la radio nombra recuerdos que creías olvidados. El conductor dice que tenés que elegir entre volver a lo que perdiste o regresar a tu casa.', @h_taxi_bajo_el_puente, 'CapituloIntermedio'); SET @c_taxi_bajo_el_puente_taxi_viaje = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: El lugar donde dejaste algo', N'Te baja frente a la casa de tu infancia, con la luz de la cocina encendida y alguien esperándote con mate. Cuando mirás atrás ya no hay taxi, y en el bolsillo aparece el llavero que perdiste de chico.', @h_taxi_bajo_el_puente, 'CapituloFinal'); SET @c_taxi_bajo_el_puente_taxi_final_perdido = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: La puerta de siempre', N'El taxi te deja en tu cuadra, pero el reloj de tu casa marca la misma hora que cuando saliste. Nadie recuerda que te fuiste, y jurás no volver a pasar por la rambla de noche.', @h_taxi_bajo_el_puente, 'CapituloFinal'); SET @c_taxi_bajo_el_puente_taxi_final_casa = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: El que no subió', N'Caminás hasta la parada y esperás el ómnibus con el corazón en la boca. A la mañana el diario cuenta que apareció un taxi sin patente abandonado bajo el puente, con la puerta abierta y el asiento todavía tibio.', @h_taxi_bajo_el_puente, 'CapituloFinal'); SET @c_taxi_bajo_el_puente_taxi_final_noSubio = SCOPE_IDENTITY();
UPDATE Historias SET CapituloInicialId = @c_taxi_bajo_el_puente_taxi_inicio WHERE Id = @h_taxi_bajo_el_puente;
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Subirte al taxi', @c_taxi_bajo_el_puente_taxi_viaje, @c_taxi_bajo_el_puente_taxi_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Seguir caminando bajo la lluvia', @c_taxi_bajo_el_puente_taxi_final_noSubio, @c_taxi_bajo_el_puente_taxi_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Pedirle que te lleve a lo que perdiste', @c_taxi_bajo_el_puente_taxi_final_perdido, @c_taxi_bajo_el_puente_taxi_viaje);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Pedirle que te devuelva a tu casa', @c_taxi_bajo_el_puente_taxi_final_casa, @c_taxi_bajo_el_puente_taxi_viaje);

-- Historia: Expedición al Cerro del Eco (PUBLICADA)
INSERT INTO Historias (Titulo, Sinopsis, Estado, CapituloInicialId) VALUES (N'Expedición al Cerro del Eco', N'Sos geóloga de un pequeño grupo que quiere mapear un cerro donde las voces rebotan con minutos de retraso. Cañones, puentes viejos y cuevas llenas de ecos te esperan, y cada ruta guarda un descubrimiento distinto.', 1, NULL); SET @h_cerro_del_eco = SCOPE_IDENTITY();
INSERT INTO CategoriaHistoria (CategoriasId, HistoriaId) VALUES (@cat10, @h_cerro_del_eco);
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Base del Cerro del Eco', N'Sos geóloga y tu grupo quiere mapear un cerro donde las voces rebotan con minutos de retraso. A mitad de la subida encontrás dos senderos: uno bordea un cañón y el otro entra en una cueva.', @h_cerro_del_eco, 'CapituloIntermedio'); SET @c_cerro_del_eco_cerro_inicio = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'El borde del cañón', N'El viento sopla fuerte y desde el fondo sube tu propia voz, diciendo cosas que todavía no dijiste. Un puente de cuerda cruza el cañón, viejo pero entero.', @h_cerro_del_eco, 'CapituloIntermedio'); SET @c_cerro_del_eco_cerro_canon = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: La cima sin eco', N'En la cima el silencio es total y el mapa se completa por primera vez. Plantás una bandera de tela y volvés con datos que cambian el atlas de la región.', @h_cerro_del_eco, 'CapituloFinal'); SET @c_cerro_del_eco_cerro_final_cima = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: El río del fondo', N'Abajo corre un río claro que ninguna foto aérea había registrado. Pasás la noche anotando todo lo que ves y decidís no revelar el punto exacto, para que siga siendo tuyo.', @h_cerro_del_eco, 'CapituloFinal'); SET @c_cerro_del_eco_cerro_final_rio = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Galería de las voces', N'En la cueva las paredes devuelven las voces de otros exploradores que pasaron hace siglos. Grabás horas de ecos y volvés convencida de que el cerro guarda memoria.', @h_cerro_del_eco, 'CapituloFinal'); SET @c_cerro_del_eco_cerro_final_voces = SCOPE_IDENTITY();
UPDATE Historias SET CapituloInicialId = @c_cerro_del_eco_cerro_inicio WHERE Id = @h_cerro_del_eco;
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Seguir por el borde del cañón', @c_cerro_del_eco_cerro_canon, @c_cerro_del_eco_cerro_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Entrar a la cueva con las linternas', @c_cerro_del_eco_cerro_final_voces, @c_cerro_del_eco_cerro_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Cruzar el puente de cuerda', @c_cerro_del_eco_cerro_final_cima, @c_cerro_del_eco_cerro_canon);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Bajar por la pared hasta el fondo', @c_cerro_del_eco_cerro_final_rio, @c_cerro_del_eco_cerro_canon);

-- Historia: El jardín de los relojes (PUBLICADA)
INSERT INTO Historias (Titulo, Sinopsis, Estado, CapituloInicialId) VALUES (N'El jardín de los relojes', N'Detrás de la casa de tu abuela hay una puerta que da a un jardín donde los relojes crecen como flores. Cada uno marca un momento de tu vida, y uno late más fuerte que los demás.', 1, NULL); SET @h_jardin_de_los_relojes = SCOPE_IDENTITY();
INSERT INTO CategoriaHistoria (CategoriasId, HistoriaId) VALUES (@cat1, @h_jardin_de_los_relojes);
INSERT INTO CategoriaHistoria (CategoriasId, HistoriaId) VALUES (@cat3, @h_jardin_de_los_relojes);
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Una puerta entre las hortensias', N'En el fondo de la casa de tu abuela encontrás una puerta que da a un jardín donde los relojes crecen como flores. Cada uno marca un momento distinto de tu vida, y uno late más fuerte que el resto.', @h_jardin_de_los_relojes, 'CapituloIntermedio'); SET @c_jardin_de_los_relojes_jardin_inicio = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'El reloj arrancado', N'Al arrancarlo el jardín se queda sin viento y los demás relojes se detienen de a uno. El tuyo marca la hora exacta de un día que nunca te animaste a recordar.', @h_jardin_de_los_relojes, 'CapituloIntermedio'); SET @c_jardin_de_los_relojes_jardin_arrancado = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Agua para el tiempo', N'Los relojes florecen y largan notas de música de cuerda. Un caracol de oro te avisa que uno de ellos está enfermo y que solo vos podés curarlo.', @h_jardin_de_los_relojes, 'CapituloIntermedio'); SET @c_jardin_de_los_relojes_jardin_agua = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: El día que faltaba', N'Ves una tarde de verano que habías olvidado, con tu abuela riéndose y vos de chico corriendo descalzo. Cuando salís del jardín la puerta ya no está, pero la risa te acompaña.', @h_jardin_de_los_relojes, 'CapituloFinal'); SET @c_jardin_de_los_relojes_jardin_final_dia = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Jardinero del tiempo', N'Curás el reloj con unas gotas de agua y una canción que tu abuela te enseñó. El jardín te nombra jardinero, y desde entonces cada primavera aparece una puerta nueva entre las hortensias.', @h_jardin_de_los_relojes, 'CapituloFinal'); SET @c_jardin_de_los_relojes_jardin_final_jardinero = SCOPE_IDENTITY();
UPDATE Historias SET CapituloInicialId = @c_jardin_de_los_relojes_jardin_inicio WHERE Id = @h_jardin_de_los_relojes;
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Arrancar el reloj que late más fuerte', @c_jardin_de_los_relojes_jardin_arrancado, @c_jardin_de_los_relojes_jardin_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Regar los relojes con la regadera de la abuela', @c_jardin_de_los_relojes_jardin_agua, @c_jardin_de_los_relojes_jardin_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Dar cuerda y mirar ese día', @c_jardin_de_los_relojes_jardin_final_dia, @c_jardin_de_los_relojes_jardin_arrancado);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Seguir al caracol hasta el reloj enfermo', @c_jardin_de_los_relojes_jardin_final_jardinero, @c_jardin_de_los_relojes_jardin_agua);

-- Historia: Don Robot se jubila (PUBLICADA)
INSERT INTO Historias (Titulo, Sinopsis, Estado, CapituloInicialId) VALUES (N'Don Robot se jubila', N'Sos el robot de mantenimiento de una estación de trenes y hoy es tu último turno antes de la jubilación. Entre una fuga de vapor, un aprendiz nervioso y un discurso larguísimo, vas a tener que decidir cómo despedirte del oficio.', 1, NULL); SET @h_robot_se_jubila = SCOPE_IDENTITY();
INSERT INTO CategoriaHistoria (CategoriasId, HistoriaId) VALUES (@cat2, @h_robot_se_jubila);
INSERT INTO CategoriaHistoria (CategoriasId, HistoriaId) VALUES (@cat7, @h_robot_se_jubila);
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'El último turno', N'Hoy es tu último turno antes de la jubilación, pero en la sala de máquinas hay una fuga de vapor. Por los altavoces anuncian que el intendente de la estación viene a darte una medalla.', @h_robot_se_jubila, 'CapituloIntermedio'); SET @c_robot_se_jubila_robot_inicio = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Llave inglesa de despedida', N'Mientras ajustás la tubería, tus engranajes crujen y sentís que alguien te mira desde la escalera: es el aprendiz, un robot nuevo y nervioso. Te pregunta si podés enseñarle el último secreto del oficio.', @h_robot_se_jubila, 'CapituloIntermedio'); SET @c_robot_se_jubila_robot_llave = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: La herencia de la llave', N'El aprendiz golpea la válvula y todo el sistema vuelve a funcionar al instante. El intendente lee un discurso larguísimo, recibís la medalla y te vas a descansar a una plaza con una lata de aceite.', @h_robot_se_jubila, 'CapituloFinal'); SET @c_robot_se_jubila_robot_final_herencia = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Silbidos y secretos', N'Salís de la estación con tu secreto y una sonrisa de metal. A los dos días te llaman de vuelta por una emergencia, y aceptás volver con tarifa de consultor y un moño de regalo.', @h_robot_se_jubila, 'CapituloFinal'); SET @c_robot_se_jubila_robot_final_silbidos = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Medalla bajo el vapor', N'La ceremonia se hace dentro de una nube de vapor y el intendente termina empapado. Te dan la medalla igual, pero tu jubilación empieza con una orden de limpiar oficinas.', @h_robot_se_jubila, 'CapituloFinal'); SET @c_robot_se_jubila_robot_final_medalla = SCOPE_IDENTITY();
UPDATE Historias SET CapituloInicialId = @c_robot_se_jubila_robot_inicio WHERE Id = @h_robot_se_jubila;
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Arreglar la fuga antes que nada', @c_robot_se_jubila_robot_llave, @c_robot_se_jubila_robot_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Recibir la medalla y dejar la fuga para después', @c_robot_se_jubila_robot_final_medalla, @c_robot_se_jubila_robot_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Enseñarle el truco del golpecito en la válvula', @c_robot_se_jubila_robot_final_herencia, @c_robot_se_jubila_robot_llave);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Guardarte el secreto y salir silbando', @c_robot_se_jubila_robot_final_silbidos, @c_robot_se_jubila_robot_llave);

-- Historia: La biblioteca bajo el agua (BORRADOR)
INSERT INTO Historias (Titulo, Sinopsis, Estado, CapituloInicialId) VALUES (N'La biblioteca bajo el agua', N'Una crecida deja al descubierto una escalera en el sótano de un viejo club, y al final hay una biblioteca entera bajo el agua. Entre libros flotantes y un registro que predice el futuro, vas a decidir qué descubrir y qué dejar donde está.', 0, NULL); SET @h_biblioteca_bajo_el_agua = SCOPE_IDENTITY();
INSERT INTO CategoriaHistoria (CategoriasId, HistoriaId) VALUES (@cat3, @h_biblioteca_bajo_el_agua);
INSERT INTO CategoriaHistoria (CategoriasId, HistoriaId) VALUES (@cat10, @h_biblioteca_bajo_el_agua);
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'El sótano inundado', N'Una crecida dejó al descubierto una escalera en el sótano del viejo club y bajás con casco y linterna. Abajo hay una biblioteca entera bajo el agua, con libros que flotan abiertos como pájaros.', @h_biblioteca_bajo_el_agua, 'CapituloIntermedio'); SET @c_biblioteca_bajo_el_agua_biblio_inicio = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'El escritorio del bibliotecario', N'Sobre el escritorio hay un registro con una última anotación fechada mañana. A su lado, una llave de bronce con una etiqueta que dice «no abrir hasta la próxima crecida».', @h_biblioteca_bajo_el_agua, 'CapituloIntermedio'); SET @c_biblioteca_bajo_el_agua_biblio_escritorio = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: El cajón sellado', N'Adentro hay un mapa de túneles que conectan todos los sótanos del barrio. Lo guardás con cuidado, sabiendo que hay mucho más para explorar.', @h_biblioteca_bajo_el_agua, 'CapituloFinal'); SET @c_biblioteca_bajo_el_agua_biblio_final_cajon = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Tinta que no se borra', N'Copiás el registro línea por línea y descubrís que las anotaciones predicen la crecida de cada año. Volvés a la superficie con una advertencia que va a salvar más de un sótano.', @h_biblioteca_bajo_el_agua, 'CapituloFinal'); SET @c_biblioteca_bajo_el_agua_biblio_final_tinta = SCOPE_IDENTITY();
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'Final: Libros mojados', N'Salvás una docena de libros y los secás al sol con piedras sobre las hojas. Entre ellos hay uno con tu apellido en la tapa, pero nunca más conseguís bajar de nuevo.', @h_biblioteca_bajo_el_agua, 'CapituloFinal'); SET @c_biblioteca_bajo_el_agua_biblio_final_libros = SCOPE_IDENTITY();
UPDATE Historias SET CapituloInicialId = @c_biblioteca_bajo_el_agua_biblio_inicio WHERE Id = @h_biblioteca_bajo_el_agua;
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Nadar hasta el escritorio del fondo', @c_biblioteca_bajo_el_agua_biblio_escritorio, @c_biblioteca_bajo_el_agua_biblio_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Sacar los libros más cercanos y volver rápido', @c_biblioteca_bajo_el_agua_biblio_final_libros, @c_biblioteca_bajo_el_agua_biblio_inicio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Usar la llave en el cajón sellado', @c_biblioteca_bajo_el_agua_biblio_final_cajon, @c_biblioteca_bajo_el_agua_biblio_escritorio);
INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) VALUES (N'Dejar la llave y copiar el registro', @c_biblioteca_bajo_el_agua_biblio_final_tinta, @c_biblioteca_bajo_el_agua_biblio_escritorio);

-- Historia: La feria de los espejos (BORRADOR)
INSERT INTO Historias (Titulo, Sinopsis, Estado, CapituloInicialId) VALUES (N'La feria de los espejos', N'Cada tanto, una feria de espejos aparece de noche en un baldío del barrio y solo se ve cuando la luna está baja. Esta vez las luces están encendidas, y un reflejo te hace señas para que te acerques.', 0, NULL); SET @h_feria_de_los_espejos = SCOPE_IDENTITY();
INSERT INTO CategoriaHistoria (CategoriasId, HistoriaId) VALUES (@cat9, @h_feria_de_los_espejos);
INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) VALUES (N'La feria que llega de noche', N'Cada tanto, una feria de espejos aparece en el baldío del barrio, y los vecinos dicen que solo se ve cuando la luna está baja. Esta noche las luces están encendidas y, en uno de los espejos, tu reflejo te hace señas para que te acerques.', @h_feria_de_los_espejos, 'CapituloIntermedio'); SET @c_feria_de_los_espejos_feria_inicio = SCOPE_IDENTITY();
UPDATE Historias SET CapituloInicialId = @c_feria_de_los_espejos_feria_inicio WHERE Id = @h_feria_de_los_espejos;

-- ============================================================
-- DATOS DE USO: auditoría y lecturas, los que el sistema
-- registra mientras se usa.
-- ============================================================

-- Auditorias
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de historia', '2026-07-06T10:00:00', @u_admin1, @h_faro_que_no_se_apaga, N'El faro que no se apaga');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo intermedio', '2026-07-06T10:12:00', @u_admin1, @h_faro_que_no_se_apaga, N'El faro que no se apaga');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo intermedio', '2026-07-06T10:24:00', @u_admin1, @h_faro_que_no_se_apaga, N'El faro que no se apaga');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-07-06T10:36:00', @u_admin1, @h_faro_que_no_se_apaga, N'El faro que no se apaga');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-07-06T10:48:00', @u_admin1, @h_faro_que_no_se_apaga, N'El faro que no se apaga');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-07-06T11:00:00', @u_admin1, @h_faro_que_no_se_apaga, N'El faro que no se apaga');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-07-06T11:12:00', @u_admin1, @h_faro_que_no_se_apaga, N'El faro que no se apaga');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Publicación de historia', '2026-07-06T11:32:00', @u_admin1, @h_faro_que_no_se_apaga, N'El faro que no se apaga');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de historia', '2026-07-12T16:30:00', @u_admin2, @h_estacion_orion_9, N'Estación Orión-9');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo intermedio', '2026-07-12T16:42:00', @u_admin2, @h_estacion_orion_9, N'Estación Orión-9');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-07-12T16:54:00', @u_admin2, @h_estacion_orion_9, N'Estación Orión-9');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-07-12T17:06:00', @u_admin2, @h_estacion_orion_9, N'Estación Orión-9');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-07-12T17:18:00', @u_admin2, @h_estacion_orion_9, N'Estación Orión-9');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Publicación de historia', '2026-07-12T17:38:00', @u_admin2, @h_estacion_orion_9, N'Estación Orión-9');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de historia', '2026-08-10T22:05:00', @u_admin1, @h_casa_calle_sauce, N'La casa de la calle Sauce');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo intermedio', '2026-08-10T22:17:00', @u_admin1, @h_casa_calle_sauce, N'La casa de la calle Sauce');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-08-10T22:29:00', @u_admin1, @h_casa_calle_sauce, N'La casa de la calle Sauce');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-08-10T22:41:00', @u_admin1, @h_casa_calle_sauce, N'La casa de la calle Sauce');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-08-10T22:53:00', @u_admin1, @h_casa_calle_sauce, N'La casa de la calle Sauce');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Publicación de historia', '2026-08-10T23:13:00', @u_admin1, @h_casa_calle_sauce, N'La casa de la calle Sauce');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de historia', '2026-07-18T11:20:00', @u_admin2, @h_pliego_de_la_cuchilla, N'El pliego de la cuchilla');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo intermedio', '2026-07-18T11:32:00', @u_admin2, @h_pliego_de_la_cuchilla, N'El pliego de la cuchilla');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo intermedio', '2026-07-18T11:44:00', @u_admin2, @h_pliego_de_la_cuchilla, N'El pliego de la cuchilla');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-07-18T11:56:00', @u_admin2, @h_pliego_de_la_cuchilla, N'El pliego de la cuchilla');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-07-18T12:08:00', @u_admin2, @h_pliego_de_la_cuchilla, N'El pliego de la cuchilla');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Publicación de historia', '2026-07-18T12:28:00', @u_admin2, @h_pliego_de_la_cuchilla, N'El pliego de la cuchilla');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de historia', '2026-07-30T15:10:00', @u_admin1, @h_carta_tren_de_las_siete, N'Carta en el tren de las siete');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo intermedio', '2026-07-30T15:22:00', @u_admin1, @h_carta_tren_de_las_siete, N'Carta en el tren de las siete');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-07-30T15:34:00', @u_admin1, @h_carta_tren_de_las_siete, N'Carta en el tren de las siete');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-07-30T15:46:00', @u_admin1, @h_carta_tren_de_las_siete, N'Carta en el tren de las siete');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-07-30T15:58:00', @u_admin1, @h_carta_tren_de_las_siete, N'Carta en el tren de las siete');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Publicación de historia', '2026-07-30T16:18:00', @u_admin1, @h_carta_tren_de_las_siete, N'Carta en el tren de las siete');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de historia', '2026-08-06T10:30:00', @u_admin2, @h_gato_contador_barrio_sur, N'El gato contador de Barrio Sur');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo intermedio', '2026-08-06T10:42:00', @u_admin2, @h_gato_contador_barrio_sur, N'El gato contador de Barrio Sur');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo intermedio', '2026-08-06T10:54:00', @u_admin2, @h_gato_contador_barrio_sur, N'El gato contador de Barrio Sur');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-08-06T11:06:00', @u_admin2, @h_gato_contador_barrio_sur, N'El gato contador de Barrio Sur');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-08-06T11:18:00', @u_admin2, @h_gato_contador_barrio_sur, N'El gato contador de Barrio Sur');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Publicación de historia', '2026-08-06T11:38:00', @u_admin2, @h_gato_contador_barrio_sur, N'El gato contador de Barrio Sur');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de historia', '2026-08-22T20:00:00', @u_admin1, @h_ultima_llamada_de_la_noche, N'La última llamada de la noche');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo intermedio', '2026-08-22T20:12:00', @u_admin1, @h_ultima_llamada_de_la_noche, N'La última llamada de la noche');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-08-22T20:24:00', @u_admin1, @h_ultima_llamada_de_la_noche, N'La última llamada de la noche');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-08-22T20:36:00', @u_admin1, @h_ultima_llamada_de_la_noche, N'La última llamada de la noche');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-08-22T20:48:00', @u_admin1, @h_ultima_llamada_de_la_noche, N'La última llamada de la noche');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Publicación de historia', '2026-08-22T21:08:00', @u_admin1, @h_ultima_llamada_de_la_noche, N'La última llamada de la noche');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de historia', '2026-09-03T17:40:00', @u_admin2, @h_taxi_bajo_el_puente, N'El taxi bajo el puente de la rambla');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo intermedio', '2026-09-03T17:52:00', @u_admin2, @h_taxi_bajo_el_puente, N'El taxi bajo el puente de la rambla');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-09-03T18:04:00', @u_admin2, @h_taxi_bajo_el_puente, N'El taxi bajo el puente de la rambla');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-09-03T18:16:00', @u_admin2, @h_taxi_bajo_el_puente, N'El taxi bajo el puente de la rambla');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-09-03T18:28:00', @u_admin2, @h_taxi_bajo_el_puente, N'El taxi bajo el puente de la rambla');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Publicación de historia', '2026-09-03T18:48:00', @u_admin2, @h_taxi_bajo_el_puente, N'El taxi bajo el puente de la rambla');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de historia', '2026-09-14T09:15:00', @u_admin1, @h_cerro_del_eco, N'Expedición al Cerro del Eco');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo intermedio', '2026-09-14T09:27:00', @u_admin1, @h_cerro_del_eco, N'Expedición al Cerro del Eco');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-09-14T09:39:00', @u_admin1, @h_cerro_del_eco, N'Expedición al Cerro del Eco');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-09-14T09:51:00', @u_admin1, @h_cerro_del_eco, N'Expedición al Cerro del Eco');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-09-14T10:03:00', @u_admin1, @h_cerro_del_eco, N'Expedición al Cerro del Eco');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Publicación de historia', '2026-09-14T10:23:00', @u_admin1, @h_cerro_del_eco, N'Expedición al Cerro del Eco');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de historia', '2026-09-25T12:00:00', @u_admin2, @h_jardin_de_los_relojes, N'El jardín de los relojes');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo intermedio', '2026-09-25T12:12:00', @u_admin2, @h_jardin_de_los_relojes, N'El jardín de los relojes');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo intermedio', '2026-09-25T12:24:00', @u_admin2, @h_jardin_de_los_relojes, N'El jardín de los relojes');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-09-25T12:36:00', @u_admin2, @h_jardin_de_los_relojes, N'El jardín de los relojes');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-09-25T12:48:00', @u_admin2, @h_jardin_de_los_relojes, N'El jardín de los relojes');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Publicación de historia', '2026-09-25T13:08:00', @u_admin2, @h_jardin_de_los_relojes, N'El jardín de los relojes');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de historia', '2026-10-05T14:30:00', @u_admin1, @h_robot_se_jubila, N'Don Robot se jubila');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo intermedio', '2026-10-05T14:42:00', @u_admin1, @h_robot_se_jubila, N'Don Robot se jubila');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-10-05T14:54:00', @u_admin1, @h_robot_se_jubila, N'Don Robot se jubila');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-10-05T15:06:00', @u_admin1, @h_robot_se_jubila, N'Don Robot se jubila');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-10-05T15:18:00', @u_admin1, @h_robot_se_jubila, N'Don Robot se jubila');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Publicación de historia', '2026-10-05T15:38:00', @u_admin1, @h_robot_se_jubila, N'Don Robot se jubila');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de historia', '2026-10-18T10:00:00', @u_admin2, @h_biblioteca_bajo_el_agua, N'La biblioteca bajo el agua');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo intermedio', '2026-10-18T10:12:00', @u_admin2, @h_biblioteca_bajo_el_agua, N'La biblioteca bajo el agua');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-10-18T10:24:00', @u_admin2, @h_biblioteca_bajo_el_agua, N'La biblioteca bajo el agua');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-10-18T10:36:00', @u_admin2, @h_biblioteca_bajo_el_agua, N'La biblioteca bajo el agua');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de capítulo final', '2026-10-18T10:48:00', @u_admin2, @h_biblioteca_bajo_el_agua, N'La biblioteca bajo el agua');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de historia', '2026-11-02T18:20:00', @u_admin1, @h_feria_de_los_espejos, N'La feria de los espejos');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Edición de historia', '2026-07-20T09:45:00', @u_admin1, @h_faro_que_no_se_apaga, N'El faro que no se apaga');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Edición de historia', '2026-09-01T11:00:00', @u_admin2, @h_casa_calle_sauce, N'La casa de la calle Sauce');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Edición de historia', '2026-10-12T16:20:00', @u_admin1, @h_cerro_del_eco, N'Expedición al Cerro del Eco');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Creación de historia', '2026-08-14T09:30:00', @u_admin2, NULL, N'El señor de las nubes de cartón');
INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) VALUES (N'Baja de historia', '2026-10-02T16:45:00', @u_admin2, NULL, N'El señor de las nubes de cartón');

-- Lecturas (FechaFinalizacion y FinalAlcanzadoId en NULL = todavía en curso)
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-08-05T17:00:00', '2026-08-05T17:15:00', @u_lector2, @h_pliego_de_la_cuchilla, @c_pliego_de_la_cuchilla_pliego_final_deber, @c_pliego_de_la_cuchilla_pliego_final_deber);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-08-08T20:15:00', '2026-08-08T20:29:00', @u_lector1, @h_faro_que_no_se_apaga, @c_faro_que_no_se_apaga_faro_final_guardian, @c_faro_que_no_se_apaga_faro_final_guardian);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-08-12T07:55:00', '2026-08-12T08:04:00', @u_lector3, @h_carta_tren_de_las_siete, @c_carta_tren_de_las_siete_carta_final_papel, @c_carta_tren_de_las_siete_carta_final_papel);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-08-14T18:40:00', '2026-08-14T18:51:00', @u_lector2, @h_faro_que_no_se_apaga, @c_faro_que_no_se_apaga_faro_final_guardian, @c_faro_que_no_se_apaga_faro_final_guardian);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-08-17T21:30:00', '2026-08-17T21:50:00', @u_lector2, @h_estacion_orion_9, @c_estacion_orion_9_orion_final_silencio, @c_estacion_orion_9_orion_final_silencio);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-08-19T22:10:00', '2026-08-19T22:27:00', @u_lector3, @h_faro_que_no_se_apaga, @c_faro_que_no_se_apaga_faro_final_farera, @c_faro_que_no_se_apaga_faro_final_farera);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-08-23T19:15:00', '2026-08-23T19:21:00', @u_lector5, @h_estacion_orion_9, @c_estacion_orion_9_orion_final_capsula, @c_estacion_orion_9_orion_final_capsula);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-08-25T23:15:00', '2026-08-25T23:37:00', @u_lector1, @h_casa_calle_sauce, @c_casa_calle_sauce_sauce_final_altillo, @c_casa_calle_sauce_sauce_final_altillo);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-08-28T13:10:00', '2026-08-28T13:14:00', @u_lector5, @h_casa_calle_sauce, @c_casa_calle_sauce_sauce_final_venta, @c_casa_calle_sauce_sauce_final_venta);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-08-30T16:25:00', '2026-08-30T16:37:00', @u_lector4, @h_faro_que_no_se_apaga, @c_faro_que_no_se_apaga_faro_final_guardian, @c_faro_que_no_se_apaga_faro_final_guardian);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-09-02T22:50:00', '2026-09-02T23:15:00', @u_lector3, @h_casa_calle_sauce, @c_casa_calle_sauce_sauce_final_casa, @c_casa_calle_sauce_sauce_final_casa);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-09-06T23:00:00', '2026-09-06T23:08:00', @u_lector5, @h_faro_que_no_se_apaga, @c_faro_que_no_se_apaga_faro_final_oscuridad, @c_faro_que_no_se_apaga_faro_final_oscuridad);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-09-09T23:40:00', NULL, @u_lector9, @h_casa_calle_sauce, @c_casa_calle_sauce_sauce_noche, NULL);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-09-10T12:20:00', '2026-09-10T12:38:00', @u_lector1, @h_estacion_orion_9, @c_estacion_orion_9_orion_final_voz, @c_estacion_orion_9_orion_final_voz);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-09-12T14:00:00', '2026-09-12T14:16:00', @u_lector4, @h_estacion_orion_9, @c_estacion_orion_9_orion_final_voz, @c_estacion_orion_9_orion_final_voz);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-09-15T19:30:00', '2026-09-15T19:45:00', @u_lector6, @h_faro_que_no_se_apaga, @c_faro_que_no_se_apaga_faro_final_farera, @c_faro_que_no_se_apaga_faro_final_farera);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-09-20T21:05:00', '2026-09-20T21:14:00', @u_lector2, @h_faro_que_no_se_apaga, @c_faro_que_no_se_apaga_faro_final_guardian, @c_faro_que_no_se_apaga_faro_final_guardian);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-09-26T08:30:00', '2026-09-26T08:36:00', @u_lector7, @h_carta_tren_de_las_siete, @c_carta_tren_de_las_siete_carta_final_funcion, @c_carta_tren_de_las_siete_carta_final_funcion);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-09-28T20:35:00', '2026-09-28T20:47:00', @u_lector1, @h_taxi_bajo_el_puente, @c_taxi_bajo_el_puente_taxi_final_perdido, @c_taxi_bajo_el_puente_taxi_final_perdido);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-10-02T19:00:00', NULL, @u_lector8, @h_jardin_de_los_relojes, @c_jardin_de_los_relojes_jardin_inicio, NULL);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-10-03T17:45:00', '2026-10-03T17:55:00', @u_lector7, @h_faro_que_no_se_apaga, @c_faro_que_no_se_apaga_faro_final_guardian, @c_faro_que_no_se_apaga_faro_final_guardian);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-10-04T21:10:00', NULL, @u_lector9, @h_estacion_orion_9, @c_estacion_orion_9_orion_control, NULL);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-10-08T22:40:00', '2026-10-08T22:59:00', @u_lector6, @h_estacion_orion_9, @c_estacion_orion_9_orion_final_voz, @c_estacion_orion_9_orion_final_voz);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-10-09T08:10:00', '2026-10-09T08:17:00', @u_lector1, @h_carta_tren_de_las_siete, @c_carta_tren_de_las_siete_carta_final_puerto, @c_carta_tren_de_las_siete_carta_final_puerto);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-10-11T18:20:00', '2026-10-11T18:34:00', @u_lector2, @h_taxi_bajo_el_puente, @c_taxi_bajo_el_puente_taxi_final_casa, @c_taxi_bajo_el_puente_taxi_final_casa);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-10-14T20:20:00', NULL, @u_lector3, @h_jardin_de_los_relojes, @c_jardin_de_los_relojes_jardin_agua, NULL);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-10-15T15:30:00', NULL, @u_lector6, @h_cerro_del_eco, @c_cerro_del_eco_cerro_canon, NULL);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-10-18T20:50:00', '2026-10-18T21:03:00', @u_lector8, @h_faro_que_no_se_apaga, @c_faro_que_no_se_apaga_faro_final_farera, @c_faro_que_no_se_apaga_faro_final_farera);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-10-21T10:00:00', '2026-10-21T10:24:00', @u_lector1, @h_cerro_del_eco, @c_cerro_del_eco_cerro_final_cima, @c_cerro_del_eco_cerro_final_cima);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-10-22T19:45:00', '2026-10-22T19:56:00', @u_lector4, @h_taxi_bajo_el_puente, @c_taxi_bajo_el_puente_taxi_final_perdido, @c_taxi_bajo_el_puente_taxi_final_perdido);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-10-27T21:00:00', '2026-10-27T21:21:00', @u_lector7, @h_casa_calle_sauce, @c_casa_calle_sauce_sauce_final_altillo, @c_casa_calle_sauce_sauce_final_altillo);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-10-29T12:45:00', '2026-10-29T12:53:00', @u_lector4, @h_gato_contador_barrio_sur, @c_gato_contador_barrio_sur_gato_final_contrato, @c_gato_contador_barrio_sur_gato_final_contrato);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-10-30T16:40:00', '2026-10-30T16:58:00', @u_lector3, @h_cerro_del_eco, @c_cerro_del_eco_cerro_final_voces, @c_cerro_del_eco_cerro_final_voces);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-11-01T21:15:00', '2026-11-01T21:25:00', @u_lector6, @h_taxi_bajo_el_puente, @c_taxi_bajo_el_puente_taxi_final_casa, @c_taxi_bajo_el_puente_taxi_final_casa);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-11-01T22:30:00', NULL, @u_lector9, @h_jardin_de_los_relojes, @c_jardin_de_los_relojes_jardin_arrancado, NULL);
INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) VALUES ('2026-11-03T22:10:00', '2026-11-03T22:23:00', @u_lector1, @h_ultima_llamada_de_la_noche, @c_ultima_llamada_de_la_noche_llamada_final_llave, @c_ultima_llamada_de_la_noche_llamada_final_llave);

COMMIT TRANSACTION;
GO
