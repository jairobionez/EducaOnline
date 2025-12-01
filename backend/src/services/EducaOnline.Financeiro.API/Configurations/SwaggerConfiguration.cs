using Microsoft.OpenApi.Models;
using Microsoft.Extensions.Hosting;

namespace EducaOnline.Financeiro.API.Configurations
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
                    Title = "EducaOnline Financeiro API",
                    Description = "Esta API faz parte do curso MBA DevExpert Módulo 4",
                    //Colocar uma página de contatos ou remover definitivamente
                    //Contact = new OpenApiContact() { Name = "Ozias Costa", Email = "oziasmcn@gmail.com" },
                    License = new OpenApiLicense() { Name = "MIT", Url = new Uri("https://opensource.org/license/mit") }
                });

                c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
                {
                    Description = "Insira o token JWT desta maneira: Bearer {seu token}",
                    Name = "Authorization",
                    Scheme = "Bearer",
                    BearerFormat = "JWT",
                    In = ParameterLocation.Header,
                    Type = SecuritySchemeType.ApiKey
                });

                c.AddSecurityRequirement(new OpenApiSecurityRequirement
                {
                    {
                        new OpenApiSecurityScheme
                        {
                            Reference = new OpenApiReference
                            {
                                Type = ReferenceType.SecurityScheme,
                                Id = "Bearer"
                            }
                        },
                        new string[] {}
                    }
                });
            });



            return services;
        }


        public static WebApplication UseSwaggerConfiguration(this WebApplication app)
        {
            if (!app.Environment.IsDevelopment())
            {
                app.UseSwagger(c => { c.RouteTemplate = "api/financeiro/swagger/{documentName}/swagger.json"; });
                app.UseSwaggerUI(c =>
                {
                    c.SwaggerEndpoint("/api/financeiro/swagger/v1/swagger.json", "EducaOnline Financeiro API V1");
                    c.RoutePrefix = "api/financeiro/swagger";
                });
            }
            else
            {
                app.UseSwagger();
                app.UseSwaggerUI(c =>
                {
                    c.SwaggerEndpoint("/swagger/v1/swagger.json", "EducaOnline Financeiro API V1");
                });
            }

            return app;
        }
    }
}

