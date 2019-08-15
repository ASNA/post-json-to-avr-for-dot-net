<%@ Application Language="AVR" %>

<%@ Import Namespace="System.Web.Routing" %> 

<script runat="server">

	BegSr Application_Start
		DclSrParm sender Type(*Object)
		DclSrParm e Type(EventArgs)

        RegisterRoutes(RouteTable.Routes)
	EndSr

    BegSr RegisterRoutes
        DclSrParm routes Type(RouteCollection)

        DclFld restRouter Type(ASNA.JsonRestRouting.Router) 
        restRouter = *New ASNA.JsonRestRouting.Router(routes) 

        // RESTful routes.
        // This suport is provided by the ASNA.JsonRestRouting assembly.
        restRouter.Get("api/customers", "Add", *TypeOf(CustomersController))
        restRouter.Post("api/customers", "Add", *TypeOf(CustomersController))
    EndSr
      
</script>
