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

