using EFCoreExampleSeriLog.Data;
using EFCoreExampleSeriLog.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Serilog;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace EFCoreExampleSeriLog
{
    class Program
    {
        static async Task Main(string[] args)
        {
            // Configurar Serilog
            Log.Logger = new LoggerConfiguration()
                .WriteTo.Console()
                .CreateLogger();

            var loggerFactory = LoggerFactory.Create(builder =>
            {
                builder.AddSerilog();
            });

            var logger = loggerFactory.CreateLogger<Program>();

            try
            {
                using (var context = new ApplicationDbContext())
                {
                    context.Database.Migrate();

                    // Insertar un nuevo producto
                    var newProduct = new Product { Name = "Sample Product", Price = 9.99M };
                    context.Products.Add(newProduct);
                    context.SaveChanges();

                    logger.LogInformation("Inserted new product with ID: {Id}", newProduct.Id);

                    // Leer productos
                    var products = context.Products.ToList();

                    foreach (var product in products)
                    {
                        logger.LogInformation($"Id: {product.Id}, Name: {product.Name}, Price: {product.Price}");
                    }
                }
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "An error occurred while accessing the database.");
            }

            // Añadir un delay antes de finalizar
            await Task.Delay(TimeSpan.FromMinutes(1));

            // Cerrar el logger de Serilog
            Log.CloseAndFlush();
        }
    }
}