<%@ Page Language="AVR" AutoEventWireup="false" CodeFile="PostJson.aspx.vr" Inherits="PostJson" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>Untitled Page</title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        <p>Open your browser's dev tools and open the console tab. </p>
        <p>After clicking the 'Post Json' you should see this message: <em>Data correctly received in the CustomersController</em></p>
        <a href="#" id="postjson">
           Post Json
        </a>
    </div>
    </form>

    <script src="assets/js/postjson.aspx.js"></script>
    <script src="https://unpkg.com/axios/dist/axios.min.js"></script>
</body>
</html>
