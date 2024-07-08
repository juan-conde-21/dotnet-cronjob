using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using EFCoreExampleSeriLog.Models;
using System;

namespace EFCoreExampleSeriLog.Data
{
    public class ApplicationDbContext : DbContext
    {
        public DbSet<Product> Products { get; set; }

        public static readonly ILoggerFactory MyLoggerFactory
            = LoggerFactory.Create(builder => { builder.AddConsole(); });

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            var serverName = Environment.GetEnvironmentVariable("SQLSERVER_NAME");
            var connectionString = $"Server={serverName},1433;Database=TestDB;User Id=sa;Password=P4ssw0rd$;TrustServerCertificate=True";

            optionsBuilder
                .UseSqlServer(connectionString)
                .UseLoggerFactory(MyLoggerFactory) // Enable logging
                .EnableSensitiveDataLogging(); // Enable sensitive data logging (development only)
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Product>()
                .Property(p => p.Price)
                .HasColumnType("decimal(18,2)");
        }
    }
}
