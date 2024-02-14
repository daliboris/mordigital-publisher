
xquery version "3.1";

module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config";

import module namespace pm-mordigital-web="http://www.tei-c.org/pm/models/mordigital/web/module" at "../transform/mordigital-web-module.xql";
import module namespace pm-mordigital-print="http://www.tei-c.org/pm/models/mordigital/print/module" at "../transform/mordigital-print-module.xql";
import module namespace pm-mordigital-latex="http://www.tei-c.org/pm/models/mordigital/latex/module" at "../transform/mordigital-latex-module.xql";
import module namespace pm-mordigital-epub="http://www.tei-c.org/pm/models/mordigital/epub/module" at "../transform/mordigital-epub-module.xql";
import module namespace pm-mordigital-fo="http://www.tei-c.org/pm/models/mordigital/fo/module" at "../transform/mordigital-fo-module.xql";
import module namespace pm-teilex0-web="http://www.tei-c.org/pm/models/teilex0/web/module" at "../transform/teilex0-web-module.xql";
import module namespace pm-teilex0-print="http://www.tei-c.org/pm/models/teilex0/print/module" at "../transform/teilex0-print-module.xql";
import module namespace pm-teilex0-latex="http://www.tei-c.org/pm/models/teilex0/latex/module" at "../transform/teilex0-latex-module.xql";
import module namespace pm-teilex0-epub="http://www.tei-c.org/pm/models/teilex0/epub/module" at "../transform/teilex0-epub-module.xql";
import module namespace pm-teilex0-fo="http://www.tei-c.org/pm/models/teilex0/fo/module" at "../transform/teilex0-fo-module.xql";
import module namespace pm-docx-tei="http://www.tei-c.org/pm/models/docx/tei/module" at "../transform/docx-tei-module.xql";

declare variable $pm-config:web-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "mordigital.odd" return pm-mordigital-web:transform($xml, $parameters)
case "teilex0.odd" return pm-teilex0-web:transform($xml, $parameters)
    default return pm-mordigital-web:transform($xml, $parameters)
            
    
};
            


declare variable $pm-config:print-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "mordigital.odd" return pm-mordigital-print:transform($xml, $parameters)
case "teilex0.odd" return pm-teilex0-print:transform($xml, $parameters)
    default return pm-mordigital-print:transform($xml, $parameters)
            
    
};
            


declare variable $pm-config:latex-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "mordigital.odd" return pm-mordigital-latex:transform($xml, $parameters)
case "teilex0.odd" return pm-teilex0-latex:transform($xml, $parameters)
    default return pm-mordigital-latex:transform($xml, $parameters)
            
    
};
            


declare variable $pm-config:epub-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "mordigital.odd" return pm-mordigital-epub:transform($xml, $parameters)
case "teilex0.odd" return pm-teilex0-epub:transform($xml, $parameters)
    default return pm-mordigital-epub:transform($xml, $parameters)
            
    
};
            


declare variable $pm-config:fo-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "mordigital.odd" return pm-mordigital-fo:transform($xml, $parameters)
case "teilex0.odd" return pm-teilex0-fo:transform($xml, $parameters)
    default return pm-mordigital-fo:transform($xml, $parameters)
            
    
};
            


declare variable $pm-config:tei-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "docx.odd" return pm-docx-tei:transform($xml, $parameters)
    default return error(QName("http://www.tei-c.org/tei-simple/pm-config", "error"), "No default ODD found for output mode tei")
            
    
};
            
    