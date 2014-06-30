using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(Management_Console.Startup))]
namespace Management_Console
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureAuth(app);
        }
    }
}
