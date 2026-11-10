var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllersWithViews();

// Cliente HTTP para consumir la Web API.
// La dirección depende del ambiente, por eso va en la configuración.
string urlApi = builder.Configuration["Api:BaseUrl"]
    ?? throw new InvalidOperationException(
        "No se configuró la dirección de la API.");

builder.Services.AddHttpClient("ApiLectura", client =>
{
    client.BaseAddress = new Uri(urlApi);
});

// RF06 - La sesión guarda el token JWT que devuelve el login
builder.Services.AddDistributedMemoryCache();

builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(60);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseSession();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
