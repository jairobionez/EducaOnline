using Microsoft.OpenApi.Models;
using Microsoft.Extensions.Hosting;

namespace EducaOnline.Identidade.API.Configurations
{
    public static class SwaggerConfiguration
    {
        public static IServiceCollection AddSwaggerConfiguration(this IServiceCollection services)
        {
            services.AddSwaggerGen(
            c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo()
                {
                    Title = "EducaOnline Identity API",
                    Description = "Esta API faz parte do curso MBA DevExpert Módulo 4",
                    //Colocar uma página de contatos ou remover definitivamente
                    //Contact = new OpenApiContact() { Name = "Ozias Costa", Email = "oziasmcn@gmail.com" },
                    License = new OpenApiLicense() { Name = "MIT", Url = new Uri("https://opensource.org/license/mit") }
                });
            });
            return services;
        }


        public static WebApplication UseSwaggerConfiguration(this WebApplication app)
        {
            if (!app.Environment.IsDevelopment())
            {
                app.UseSwagger(c => { c.RouteTemplate = "api/identidade/swagger/{documentName}/swagger.json"; });
                app.UseSwaggerUI(c =>
                {
                    c.SwaggerEndpoint("/api/identidade/swagger/v1/swagger.json", "EducaOnline Identity API V1");
                    c.RoutePrefix = "api/identidade/swagger";
                });
            }
            else
            {
                app.UseSwagger();
                app.UseSwaggerUI(c =>
                {
                    c.SwaggerEndpoint("/swagger/v1/swagger.json", "EducaOnline Identity API V1");
                });
            }

            return app;
        }
    }
}
