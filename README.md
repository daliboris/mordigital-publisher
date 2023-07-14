# MORDigital TEI Publisher

TEI Publisher application module for MORDigital project

## Static content in Jetty

For to serve/deliver static web content, for example images, create an `xml` configuration file in the Jetty repository.

If the eXist-db is installed in the `D:\exist-db` directory, the directory for the config file will be `D:\eXist-db\etc\jetty\webapps\`. The confuguration file can have any name, for example `mordigital-images.xml`.

Note the `PUBLIC` identifier for Jetty 9.4.50.v20221201, which is delivered with [eXist-db 6.2.0](https://exist-db.org/exist/apps/wiki/blogs/eXist/eXistdb620).

```xml
<!DOCTYPE Configure
  PUBLIC "-//Jetty//Configure//EN" "http://www.eclipse.org/jetty/configure_9_3.dtd">
<Configure class="org.eclipse.jetty.server.handler.ContextHandler">
 <Set name="contextPath">/mordigital</Set>
 <Set name="handler">
  <New class="org.eclipse.jetty.server.handler.ResourceHandler">
   <Set name="resourceBase">D:/MorDigital/local/data/images</Set>
   <Set name="directoriesListed">true</Set>
  </New>
 </Set>
</Configure>
```

More details can be found in the [Using Jetty to Serve Static Web Content](https://www.codeproject.com/Articles/1223459/Using-Jetty-to-Serve-Static-Web-Content) article by Han Bo Sun.