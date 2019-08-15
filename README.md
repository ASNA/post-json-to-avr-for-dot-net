
This example shows how to POST Json data to a controller class in an AVR for .NET Web app. The typical use case for this would be posting data to the server from a browser with Ajax or from a server-side process in an app (which may or may not be AVR) hosted on another domain. 

In this example, a POST request needs to be made posting the data to populate a customer record. This request will be made to the `api/customers` route.

There are four parts to making this work but each part is short and simple. The parts include:

1. The `CustomerEntity` class defines the schema for the customer record data. 

2. ASP.NET routing maps the `api/customers` route to a method in an AVR for .NET class. This part also includes using the `ASNA.JsonRestRouting` DLL for RESTful controller support. 

3. JavaScript to submit the POST request to the `api/customers` route and receive the HTTP response server response. 

4. An AVR controller class named `CustomersController` to receive the incoming POST data and send back an HTTP response. 

Let's take a look at each in detail. 

### 1. The `CustomerEntity` class

Any data that needs to be posted to the server should have a corresponding class that provides a formal schema for the data. This classes are very important because they enable an easy transform from Json to consumable data on the AVR for .NET server side.

    BegClass CustomerEntity Access(*Public)
        DclProp CMCustNo    Type(*Integer4) Access(*Public)
        DclProp CMName      Type(*String) Access(*Public)
        DclProp CMAddr1     Type(*String) Access(*Public)
        DclProp CMCity      Type(*String) Access(*Public)
        DclProp CMState     Type(*String) Access(*Public)
        DclProp CMCntry     Type(*String) Access(*Public)
        DclProp CMPostCode  Type(*String) Access(*Public)
        DclProp CMActive    Type(*String) Access(*Public)
        DclProp CMFax       Type(*Packed) Len(12,0) Access(*Public)
        DclProp CMPhone     Type(*String) Access(*Public)
    EndClass

This AVR object corresponds to this JavaScript object (which we'll revisit in the JavaScript discussion): 

    const customer = {
            CMCustNo: 0,
            CMName: 'Neil Young',
            CMAddr1: '123 Broken Arrow Road',
            CMCity: 'Sugar Mountain',  
            CMState: 'CA',
            CMCntry: 'USA',
            CMPostCode: 98216,
            CMActive: '1',
            CMFax: 2104040212,    
            CMPhone: '800-289-2762',  
        };

Note how the field names match exactly (including case).

In this simple customer-based example, the class needed is very simple. However, in a more complex, real-world example, you might need several classes to fully define a Json object. For example this Json object needs three classes to describe it: 

    { 
      "clientToken": "token12385cdsc", 
      "charges": [ 
        { 
          "charge_id": "1", 
          "room_code": "101", 
          "date": "2016-12-20T14:23:36.000Z", 
          "sale_items": [ 
            { 
              "quantity": 2, 
              "product_code": "123", 
              "product_description": "pizza", 
              "unit_price": 5.5 
            }, 
            { 
              "quantity": 1, 
              "product_code": "569", 
              "product_description": "birra", 
              "unit_price": 3 
            } 
          ] 
        }, 
        { 
          "charge_id": "2", 
          "room_code": "107", 
          "date": "2016-12-20T14:23:36.000Z", 
          "sale_items": [ 
            { 
              "quantity": 3, 
              "product_code": "123", 
              "product_description": "primo terra", 
              "unit_price": 10 
            }, 
            { 
              "quantity": 1, 
              "product_code": "569", 
              "product_description": "vino carta", 
              "unit_price": 20 
            } 
          ] 
        } 
      ] 
    } 
     
These three classes describe the Json object above:      
     
    BegClass Client
        DclProp clientToken Type(*String)
        DclArray charges Type(Charges)
    EndClass
     
    BegClass Charges
        DclProp charge_id Type(*String)
        DclProp room_code Type(*String)
        DclProp date Type(*DateTime)
        DclArray sale_items Type(SaleItems)
    EndClass
        
    BegClass SaleItems
        DclProp quantity Type(*Integer4)
        DclProp product_code Type(*String) 
        DclProp product_description Type(*String)
        DclProp unit_price Type(*Packed) Len(12,2)
    EndClass
    
where the Client class's `charges` field is an array of `Charges` instances and the `Charges` class's `sale_items` field is an array `SalesItems` instances. When you're working with Json data, it is _very_ important to get these data models correct. Take your time and get these definitions correct before you write any other code! This includes data types. Pay careful attention to getting them correct.

> Speaking of the real world, the field names in the example above are a potential problem. IBM i database field names are limited to 10 characters. When working with AVR and Json, it's best to use Json structures that limit field names to 10 characters. However, that isn't always possible so you may need to write some code to manually populate AVR classes from the incoming Json data. More on this later.

#### 2. ASP.NET routing 

Microsoft's ASP.NET routing engine is used to route requests to the propery RESTful route ([read more about using that engine with AVR here](https://asna.com/us/tech/kb/doc/asp-net-routing)). RESTful routing is defined in the ASP.NET project's `global.asax` file.

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
            restRouter.Post("api/customers", "Add", *TypeOf(CustomersController))
        EndSr
          
    </script>

The `RegisterRoutes` method is called when the application starts (that isn't once for every user--routes are defined when the first user logs on). RESTful Json routes are registered with AVR using the ASNA.JsonRestRouting.Route class. (To use this class you'll need to include and set a reference to the ASNA.JsonRestRouting DLL). 

In this example, the route `api/customers` for an HTTP POST is mapped to the `Add` method of the `CustomersController` class. When data is POSTed to the `api/customers` route the posted data is available in the `Add` method. Using `Post()` method is what determines what HTTP verb is associated with this route. There are corresponding methods available for the GET, PUT, PATCH, and DELETE verbs. 

3. JavaScript to submit a POST request

The JavaScript to submit POST data is in the `postjson.aspx.js` file. It also includes a little JavaScript to wire up a `click` event handler for an anchor tag for testing purposes. 

> This JavaScript uses ES6 features such as arrow functions and promises. If you're aren't yet up to speed on current ES6 (and beyond) features, [Wes Bos's ES6 JavaScript course for $82 USD is a very worthwhile investment](https://es6.io/). Or you can [read fee summaries of ES6 features here](http://es6-features.org/#ExpressionBodies).

    // Enable better JavaScript error checking.
    'use strict';
    
    // A minimal documentReady function. This takes the place of 
    // jQuery's `Ready()` method.
    const documentReady = function(fn) {
        if (document.readyState !== 'loading') {
            fn();
        } else {
            document.addEventListener('DOMContentLoaded', fn);
        }
    }    
    
    // This functions does the POST request.
    const submitJsonPostRequest = function () {
        
        // Hardcoded Json data to send.
        const customer = {
            CMCustNo: 0,
            CMName: 'Neil Young',
            CMAddr1: '123 Broken Arrow Road',
            CMCity: 'Sugar Mountain',  
            CMState: 'CA',
            CMCntry: 'USA',
            CMPostCode: 98216,
            CMActive: '1',
            CMFax: 2104040212,    
            CMPhone: '800-289-2762',  
        };
    
        // The Axios `Post` method does the low-level 
        // request submission.
        axios.post('api/customers', customer, {
            // Add a few custom headers.
            headers: {
                'x-custom-header': 'custom x value',
                'y-custom-header': 'custom y value',
            }
        })
        .then(
            // If the request succeeded.
            (response) => {
                console.log(response.data.InfoMessage);
            }, 
            // If the request failed.
            (error) => {
                console.table(error);
            }
        );            
    }

    // Wait for page to load before doing any JavaScript.
    documentReady(() => {    
        // Set common Axios headers.
        axios.defaults.headers.common = {
            'X-Requested-With': 'XMLHttpRequest'
        };

        // Make POST request when #postjson anchor tag clicked.        
        const anchor = document.querySelector('#postjson');
        anchor.addEventListener('click', (e) => {   
            submitJsonPostRequest();              
        });
    });        

As you can see, the JavaScript to submit a POST request is very simple. Five or so years ago, to make Ajax requests most programmers would have reached for jQuery. However, thanks to JavaScript maturity (which in turn owes a great deal of thanks to jQuery) you don't need jQuery anymore. In many cases, the better approach today is to write plain vanilla JavaScript.

That said, while JavaScript has acquired powerful plain vanilla ways to perform Ajax, it's challenging to get all of Ajax's settings correct for a secure, reliable solution. For Ajax work, the open source [Axios library](https://github.com/axios/axios) makes a great JavaScript companion. It takes care of so many little details and makes it easier to get success quickly. You can see in the code above that Axios requires very little code to make an Ajax request. 

Here are a couple of details about the JavaScript above: 

* Without jQuery, you'll probably need your own documentReady function. A minimal, plain-vanilla `documentReady` is included. In production code you'd probably park this away in your own libray of reusable functions.

* An 'X-Requested-With' header is added as a default header for Axios. This header helps mitigate cross-site request forgery.

* Two additional customer headers (`x-custom header` and `y-custom-header`) are added to show using custom headers both in JavaScript and later in the AVR controller.

* JavaScripts `querySelector` is used to select the anchor tag by ID for testing purposes. 

* Ajax is usually an asynchronous operation, but the Axios `post` method looks synchronous. Notice how you don't see any call backs to be called on success or failure. That's because Axios is based on [JavaScript promises](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/prototype). The `then` method chained to the `post` method receives one of two arguments: a success function and an error function. While this Axios code looks synchronous--it is not--it is asynchronous.
 
One more thing about the JavaScript above...

Axios's `post` method returns a JavaScript promise. After performing the `post` the resulting promise's `then` is immediately chained (or fluently) called. The `then` method takes two arguments, the first is a function to call if the post succeeded and the second is a function to call if the post failed. The success function receives the response object as its only argument and the fail function receives an error object as its only argument. 

This example uses ES6 arrow functions. If you're not familiar with them, the code below can look pretty mysterious. Think of the `=>` pair as being the 'goes into' operator. In this case, on success the response object goes into the code that follows inside the braces; on error the error object goes into that code that follows. Although each of these two functions has only one line of code they could each have many more lines if necessary.

    axios.post('api/customers', customer, {
        // Add a few custom headers.
        headers: {
            'x-custom-header': 'custom x value',
            'y-custom-header': 'custom y value',
        }
    })
    .then(
        // If the request succeeded.
        (response) => {
            console.log(response.data.InfoMessage);
        }, 
        // If the request failed.
        (error) => {
            console.table(error);
        }
    );   
    
If the code above looks mysterious to you, here is another way (and some would argue a clearer way) to call the promise's `then` method:     

    let promise = axios.post('api/customers', customer, {
        headers: {
            'x-custom-header': 'custom x value',
            'y-custom-header': 'custom y value',
        },
        xsrfCookieName: 'XSRF-TOKEN',
        xsrfHeaderName: 'X-XSRF-TOKEN',        
    })

    promise.then(
        function(response) {
            console.log(response.data.InfoMessage);
        },
        function(error) {
            console.table(error);
        }
    );

This uses a `promise` variable to receive the promise from Axios's `post` method call and then it calls the promise's `then` method with two traditional anonymous functions as arguments. 

If some would agree the second way is clearer, why even bother with the first way? Because ES6 arrow functions and fluent method chaining are _everywhere_ in modern JavaScript. You'll see these features in many examples on the Web and it's important to be able to understand what that kind of code is doing. Once you get used to arrow functions and fluent chaining, you'll appreciate how much crisper and direct these (and other ES6) features make your JavaScript.

I've already mentioned it once, but it's worth repeating. Part of the value of JavaScript promises is friction they remove from asynchronous operations. The code above makes it look like the promise's `then` method is called immediately after the `post` method is called. It's not. The promise "wakes up" and calls its `then` method when the post operation completes.

4. The AVR 'CustomersController` controller

The final piece is the AVR controller. It's `Add` method is the target to which the from step #3 submits Json data. That controller code is shown below. 

    BegClass CustomersController Access(*Public) + 
                                 Extends(ASNA.JsonRestRouting.Controller)
    
        BegFunc Add Access(*Public) Type(ResponseInfo) 
            DclFld Customer Type(CustomerEntity) 
            DclFld headerValueX Type(*String) 
            DclFld headerValueY Type(*String) 
            DclFld Json Type(*String) 
            DclFld ri Type(ResponseInfo) New()
    
            Json = *Base.GetRequestContent()
            Customer = NewtonSoft.Json.JsonConvert.DeserializeObject(Json,+
                                   *TypeOf(CustomerEntity)) *As CustomerEntity
            
            // Show how to get header values.
            headerValueX = *This.Http.Request.Headers['x-custom-header'].ToString()
            headerValueY = *This.Http.Request.Headers['y-custom-header'].ToString()
    
            // Set return message.
            ri.InfoMessage = 'Data correctly received in the CustomersController'
    
            LeaveSr ri 
        EndFunc 
    
    EndClass 
    
A Json string is fetched from the `GetRequestContent` method and the [NewtonSoft Json.NET](https://www.newtonsoft.com/json) library deserializes that Json into an instance of the `CustomerEntity` object ([read more about Json.NET here](https://asna.com/us/tech/kb/doc/read-write-json)) It's very important that the property names in the Json object match those in the CustomerEntity class exactly--including case. We'll take a look in a minute at what to do if the names in the Json object don't (or can't) match those in the target AVR object. 

You can also see in the `Add` method how easy it is to fetch header values. 
    
The `CustomersController` must extend `ASNA.JsonRestRouting.Controller`. Public methods in this controller always return the result converted to Json. In this case, a small class named `ResponseInfo` is instanced and returned. It's code is shown below. 

    BegClass ResponseInfo Access(*Public)
        DclProp InfoMessage Type(*String) Access(*Public) 
    EndClass

This class has a single property that provides messaging the caller (in Json format). Depending on that the method is doing, you might need to add other properties to this class to return. 

![](https://asna.com/filebin/marketing/article-figures/json-data.png)

<small>A screen shot of the data as received in the controller's `Add` method</small>

#### Dealing with Json objects with field names that don't match your field names

The code below shows an alternative method of fetching the Json data. You might use this technique if the Json data element names don't exactly match those in the target AVR object. Beware, though, that you're responsible for converting all data types to the appropriately target data types with this method (ie. you can't rely on Json.NET's implicit type conversion). 

    BegFunc Add Access(*Public) Type(ResponseInfo) 
        DclFld ri Type(ResponseInfo) New()
        DclFld Customer Type(CustomerEntity) 
        DclFld headerValueX Type(*String) 
        DclFld headerValueY Type(*String) 
        DclFld Json Type(*String) 
        
        Customer = *New CustomerEntity()
        
        DclFld JsonRequest Type(NewtonSoft.Json.Linq.JObject)
        JsonRequest = *Base.GetJsonRequestContent()
        
        Customer.CMName = Customer.JsonRequest['customer-full-name'].ToString() 
        Customer.CMAddr1 = Customer.JsonRequest['customer-address1'].ToString()
        ...
        ...

        // Set return message.
        ri.InfoMessage = 'Data correctly received in the CustomersController'

        LeaveSr ri
    EndFunc 
    
Although the method above works, consider refactoring the JavaScript object on the client side before sending it to the AVR class. For example, 

Give this Json object: 

    const customer = {
        'customer-number': 0,
        'customer-name' : 'Neil Young',
        'customer-address-1': '123 Broken Arrow Road',
    }; 
    
The following JavaScript converts it to a new Json object using the `newCustomerKeys` structure to swap out the field names:
    
    const newCustomerFields = {
        'customer-number': 'CMCustNo',
        'customer-name': 'CMName',
        'customer-address-1': 'CMAddr1'
    }; 
    
    const convertKeys = function(fromObject, conversionObject) {
        const result = {};
    
        Reflect.ownKeys(fromObject).forEach(key => {
            result[conversionObject[key]] = fromObject[key];
        });
    
        return result;
    }

    const newCustomer = convertKeys(customer, newCustomerFields)

the newCustomer object looks like this:

{
    CMCustNo: 0,
    CMName: 'Neil Young',
    CMAddr1: '123 Broken Arrow Road'
}

Converting the object on the client side requires a valid name conversion object (ie, `newCustomerFields`, but this technique is easily reusable and lets you keep automatic type conversions (thanks to Json.NET) intact in the AVR code. 

### Seeing the results

Launch the app from inside Visual Studio setting `PostJson.aspx` as the start page. When the page appears, open the browser's dev tools and select the 'console' tab. 

When you click the `Post Json` link, you should see the message 

    Data correctly received in the CustomersController

as shown below. 

![](https://asna.com/filebin/marketing/article-figures/console-json-app.png)

Also, try setting a breakpoint in the CustomersController's `Add` method. Click the `Post Json` link again and the debugger should stop on your breakpoint. 